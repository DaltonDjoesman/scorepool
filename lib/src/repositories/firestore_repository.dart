import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore/firestore_paths.dart';
import '../models/debt.dart';
import '../models/group.dart';
import '../models/match.dart';
import '../models/member.dart';
import '../models/prediction.dart';
import '../models/round_participation.dart';
import '../models/tournament_team.dart';
import '../models/user_group_membership.dart';
import '../models/user_profile.dart';
import '../services/group_match_reconciliation.dart';

class FirestoreRepository {
  FirestoreRepository(this.db);

  final FirebaseFirestore db;

  Future<void> _ensureFirestoreAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Faça login antes de usar o Firestore.');
    }
    await user.getIdToken();
  }

  CollectionReference<Map<String, Object?>> groups() =>
      db.collection(FirestorePaths.groups);

  DocumentReference<Map<String, Object?>> groupRef(String groupId) =>
      db.doc(FirestorePaths.group(groupId));

  CollectionReference<Map<String, Object?>> members(String groupId) =>
      db.collection(FirestorePaths.groupMembers(groupId));

  CollectionReference<Map<String, Object?>> predictions(String groupId) =>
      db.collection(FirestorePaths.groupPredictions(groupId));

  CollectionReference<Map<String, Object?>> debtItems({
    required String groupId,
    required String matchId,
  }) => db.collection(FirestorePaths.groupDebtItems(groupId, matchId));

  CollectionReference<Map<String, Object?>> groupMatches(String groupId) =>
      db.collection(FirestorePaths.groupMatches(groupId));

  DocumentReference<Map<String, Object?>> userRef(String uid) =>
      db.doc(FirestorePaths.user(uid));

  Future<void> _addUserGroup(String uid, String groupId) async {
    await userRef(uid).set({
      'groupIds': FieldValue.arrayUnion([groupId]),
    }, SetOptions(merge: true));
  }

  Future<void> _removeUserGroup(String uid, String groupId) async {
    await userRef(uid).set({
      'groupIds': FieldValue.arrayRemove([groupId]),
    }, SetOptions(merge: true));
  }

  List<String> _groupIdsFromUserData(Map<String, Object?>? data) {
    return ((data?['groupIds'] as List?) ?? const [])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<String>> _discoverGroupIdsFromMembership(String uid) async {
    final byUidField = await db
        .collectionGroup('members')
        .where('uid', isEqualTo: uid)
        .get();
    final groupIds = <String>{
      for (final doc in byUidField.docs)
        if (doc.reference.parent.parent?.id case final groupId?) groupId,
    };

    if (groupIds.isNotEmpty) return groupIds.toList(growable: false);

    final allMine = await db.collectionGroup('members').get();
    for (final doc in allMine.docs.where((doc) => doc.id == uid)) {
      final groupId = doc.reference.parent.parent?.id;
      if (groupId != null) groupIds.add(groupId);
    }
    return groupIds.toList(growable: false);
  }

  Future<List<String>> _userGroupIds(String uid) async {
    final userSnap = await userRef(uid).get();
    var groupIds = _groupIdsFromUserData(userSnap.data());
    if (groupIds.isNotEmpty) return groupIds;

    groupIds = await _discoverGroupIdsFromMembership(uid);
    if (groupIds.isNotEmpty) {
      await userRef(uid).set({'groupIds': groupIds}, SetOptions(merge: true));
    }
    return groupIds;
  }

  Future<({String displayName, String? photoUrl})> resolveMemberDisplay({
    required String uid,
    String fallbackName = '',
    String? fallbackPhoto,
  }) async {
    final snap = await userRef(uid).get();
    final data = snap.data();
    final savedName = (data?['displayName'] as String?)?.trim() ?? '';
    final savedPhoto = data?['photoUrl'] as String?;
    final name = savedName.isNotEmpty ? savedName : fallbackName.trim();
    return (displayName: name, photoUrl: savedPhoto ?? fallbackPhoto);
  }

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final snap = await userRef(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return UserProfile.fromMap(uid: uid, map: data);
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return userRef(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromMap(uid: uid, map: data);
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
  }) async {
    await _ensureFirestoreAuth();
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw StateError('Informe um nome para o perfil.');
    }

    await userRef(uid).set({
      'uid': uid,
      'displayName': trimmed,
    }, SetOptions(merge: true));

    final groupIds = await _userGroupIds(uid);
    if (groupIds.isEmpty) return;

    var batch = db.batch();
    var ops = 0;
    for (final groupId in groupIds) {
      batch.update(members(groupId).doc(uid), {
        'displayName': trimmed,
      });
      ops += 1;
      if (ops >= 450) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) {
      await batch.commit();
    }
  }

  Future<String> createGroup({
    required String name,
    required String currency,
    required int entryFeeCents,
    required int predictionLockMinutes,
    required String creatorUid,
    required String creatorDisplayName,
    required String? creatorPhotoUrl,
    GroupMatchFilter? matchFilter,
  }) async {
    await _ensureFirestoreAuth();

    final resolved = await resolveMemberDisplay(
      uid: creatorUid,
      fallbackName: creatorDisplayName,
      fallbackPhoto: creatorPhotoUrl,
    );

    final doc = groups().doc();

    final group = Group(
      id: doc.id,
      name: name,
      currency: currency,
      entryFeeCents: entryFeeCents,
      predictionLockMinutes: predictionLockMinutes,
      adminUids: [creatorUid],
      matchFilter:
          matchFilter ?? GroupMatchFilter(teamIds: const [], stages: const []),
      carryOverPotCents: 0,
    );

    final creatorMemberRef = members(doc.id).doc(creatorUid);
    final creatorProfile = MemberProfile(
      uid: creatorUid,
      displayName: resolved.displayName,
      photoUrl: resolved.photoUrl,
      role: GroupRole.member,
      perfectScoresCount: 0,
    );

    await doc.set(group.toMap());
    await creatorMemberRef.set(creatorProfile.toMap());
    await creatorMemberRef.update({'role': GroupRole.admin.name});

    await GroupMatchReconciliation(db).reconcileGroup(
      groupId: doc.id,
      matchFilter: group.matchFilter,
      predictionLockMinutes: predictionLockMinutes,
    );

    await _addUserGroup(creatorUid, doc.id);
    await userRef(creatorUid).set({
      'uid': creatorUid,
      'displayName': resolved.displayName,
      'photoUrl': resolved.photoUrl,
    }, SetOptions(merge: true));

    return doc.id;
  }

  Future<void> reconcileGroupMatches(String groupId) async {
    await _ensureFirestoreAuth();
    final snap = await groupRef(groupId).get();
    final data = snap.data();
    if (data == null) return;

    final group = Group.fromMap(id: snap.id, map: data);
    await GroupMatchReconciliation(db).reconcileGroup(
      groupId: groupId,
      matchFilter: group.matchFilter,
      predictionLockMinutes: group.predictionLockMinutes,
    );
  }

  Stream<Group?> watchGroup(String groupId) {
    return groupRef(groupId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Group.fromMap(id: snap.id, map: data);
    });
  }

  Future<bool> isMember({required String groupId, required String uid}) async {
    final memberSnap = await members(groupId).doc(uid).get();
    if (!memberSnap.exists) return false;
    final memberData = memberSnap.data();
    if (memberData != null && memberData['uid'] != uid) {
      await members(groupId).doc(uid).update({'uid': uid});
    }
    await _addUserGroup(uid, groupId);
    final groupSnap = await groupRef(groupId).get();
    return groupSnap.exists;
  }

  Future<List<UserGroupMembership>> fetchUserGroups(String uid) async {
    final groupIds = await _userGroupIds(uid);
    return _membershipsFromGroupIds(uid, groupIds);
  }

  Stream<List<UserGroupMembership>> watchUserGroups(String uid) {
    return userRef(uid).snapshots().asyncMap((userSnap) async {
      var groupIds = _groupIdsFromUserData(userSnap.data());
      if (groupIds.isEmpty) {
        groupIds = await _discoverGroupIdsFromMembership(uid);
        if (groupIds.isNotEmpty) {
          await userRef(uid).set({'groupIds': groupIds}, SetOptions(merge: true));
        }
      }
      return _membershipsFromGroupIds(uid, groupIds);
    });
  }

  Future<List<UserGroupMembership>> _membershipsFromGroupIds(
    String uid,
    List<String> groupIds,
  ) async {
    final memberships = <UserGroupMembership>[];
    for (final groupId in groupIds) {
      final memberSnap = await members(groupId).doc(uid).get();
      if (!memberSnap.exists) {
        await _removeUserGroup(uid, groupId);
        continue;
      }

      final groupSnap = await groupRef(groupId).get();
      final data = groupSnap.data();
      if (data == null) {
        await _removeUserGroup(uid, groupId);
        continue;
      }

      memberships.add(
        UserGroupMembership(
          groupId: groupId,
          group: Group.fromMap(id: groupId, map: data),
          role: MemberProfile.fromMap(uid: uid, map: memberSnap.data()!).role,
        ),
      );
    }

    memberships.sort((a, b) => a.group.name.compareTo(b.group.name));
    return memberships;
  }

  Future<void> deleteGroup(String groupId) async {
    await _ensureFirestoreAuth();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await groupRef(groupId).delete();
    if (uid != null) {
      await _removeUserGroup(uid, groupId);
    }
  }

  Future<void> leaveGroup({
    required String groupId,
    required String uid,
  }) async {
    await _ensureFirestoreAuth();
    await members(groupId).doc(uid).delete();
    await _removeUserGroup(uid, groupId);
  }

  Stream<List<MemberProfile>> watchMembers(String groupId) {
    return members(groupId).snapshots().map(
      (snap) => snap.docs
          .map((d) => MemberProfile.fromMap(uid: d.id, map: d.data()))
          .toList(growable: false),
    );
  }

  Future<void> updateGroupMatchFilter({
    required String groupId,
    required GroupMatchFilter matchFilter,
  }) async {
    await _ensureFirestoreAuth();
    final groupSnap = await groupRef(groupId).get();
    final group = groupSnap.data();
    if (group == null) return;

    await groupRef(groupId).update({'matchFilter': matchFilter.toMap()});

    final lockMinutes =
        (group['predictionLockMinutes'] as num?)?.toInt() ?? 15;
    await GroupMatchReconciliation(db).reconcileGroup(
      groupId: groupId,
      matchFilter: matchFilter,
      predictionLockMinutes: lockMinutes,
    );
  }

  Stream<List<GroupMatchOverlay>> watchGroupMatches({
    required String groupId,
    required bool excludedByFilter,
    bool descending = false,
  }) {
    var query = groupMatches(
      groupId,
    ).where('excludedByFilter', isEqualTo: excludedByFilter);

    query = descending
        ? query.orderBy('matchTimeUtc', descending: true)
        : query.orderBy('matchTimeUtc');

    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => GroupMatchOverlay.fromMap(
              matchId: d.id,
              groupId: groupId,
              map: d.data(),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<GroupMatchOverlay?> watchGroupMatch({
    required String groupId,
    required String matchId,
  }) {
    return groupMatches(groupId).doc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return GroupMatchOverlay.fromMap(
        matchId: snap.id,
        groupId: groupId,
        map: data,
      );
    });
  }

  Stream<RoundParticipation?> watchRoundParticipation({
    required String groupId,
    required String matchId,
    required String uid,
  }) {
    return db
        .doc(FirestorePaths.groupRoundUser(groupId, matchId, uid))
        .snapshots()
        .map((snap) {
          final data = snap.data();
          if (data == null) {
            return RoundParticipation(
              uid: uid,
              groupId: groupId,
              matchId: matchId,
              isInPot: true,
            );
          }
          return RoundParticipation.fromMap(
            uid: uid,
            groupId: groupId,
            matchId: matchId,
            map: data,
          );
        });
  }

  /// All explicit round-participation docs for a match (uid → isInPot).
  Stream<Map<String, bool>> watchMatchParticipations({
    required String groupId,
    required String matchId,
  }) {
    return db
        .collection(FirestorePaths.groupRoundUsers(groupId, matchId))
        .snapshots()
        .map((snap) {
          final map = <String, bool>{};
          for (final doc in snap.docs) {
            final data = doc.data();
            map[doc.id] = (data['isInPot'] as bool?) ?? true;
          }
          return map;
        });
  }

  Future<void> updateRoundParticipation({
    required String groupId,
    required String matchId,
    required String uid,
    required bool isInPot,
  }) async {
    final data = <String, Object?>{
      'uid': uid,
      'groupId': groupId,
      'matchId': matchId,
      'isInPot': isInPot,
      'optedOutAt': isInPot ? null : FieldValue.serverTimestamp(),
    };

    await db
        .doc(FirestorePaths.groupRoundUser(groupId, matchId, uid))
        .set(data, SetOptions(merge: true));
  }

  Future<void> joinGroup({
    required String groupId,
    required String uid,
    required String displayName,
    required String? photoUrl,
  }) async {
    await _ensureFirestoreAuth();

    final groupSnap = await groupRef(groupId).get();
    if (!groupSnap.exists) {
      throw StateError('Grupo não encontrado. Verifique o código.');
    }

    final resolved = await resolveMemberDisplay(
      uid: uid,
      fallbackName: displayName,
      fallbackPhoto: photoUrl,
    );

    final memberDoc = members(groupId).doc(uid);
    final existing = await memberDoc.get();
    if (existing.exists) {
      await memberDoc.update({
        'uid': uid,
        'displayName': resolved.displayName,
        'photoUrl': resolved.photoUrl,
      });
    } else {
      await memberDoc.set({
        'uid': uid,
        'displayName': resolved.displayName,
        'photoUrl': resolved.photoUrl,
        'role': GroupRole.member.name,
        'perfectScoresCount': 0,
      });
    }
    await _addUserGroup(uid, groupId);
    await userRef(uid).set({
      'uid': uid,
      'displayName': resolved.displayName,
      'photoUrl': resolved.photoUrl,
    }, SetOptions(merge: true));
  }

  Future<void> upsertMemberProfile({
    required String groupId,
    required String uid,
    required String displayName,
    required String? photoUrl,
  }) async {
    await _ensureFirestoreAuth();
    final doc = members(groupId).doc(uid);
    await doc.update({
      'uid': uid,
      'displayName': displayName,
      'photoUrl': photoUrl,
    });
  }

  Future<void> saveFcmToken({
    required String groupId,
    required String uid,
    required String token,
  }) async {
    await members(groupId).doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> upsertPrediction({
    required String groupId,
    required String uid,
    required String matchId,
    required int? predictedHomeScore,
    required int? predictedAwayScore,
  }) async {
    await _ensureFirestoreAuth();
    final id = Prediction.makeId(uid: uid, matchId: matchId);
    final prediction = Prediction(
      id: id,
      groupId: groupId,
      uid: uid,
      matchId: matchId,
      predictedHomeScore: predictedHomeScore,
      predictedAwayScore: predictedAwayScore,
    );

    await predictions(groupId).doc(id).set(prediction.toMap(), SetOptions(merge: true));
  }

  Stream<Prediction?> watchPrediction({
    required String groupId,
    required String uid,
    required String matchId,
  }) {
    final id = Prediction.makeId(uid: uid, matchId: matchId);
    return predictions(groupId).doc(id).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Prediction.fromMap(id: snap.id, map: data);
    });
  }

  Stream<List<Prediction>> watchMatchPredictions({
    required String groupId,
    required String matchId,
  }) {
    return predictions(groupId)
        .where('matchId', isEqualTo: matchId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Prediction.fromMap(id: d.id, map: d.data()))
              .toList(growable: false),
        );
  }

  Stream<List<DebtItem>> watchDebtItems({
    required String groupId,
    required String matchId,
  }) {
    return debtItems(groupId: groupId, matchId: matchId).snapshots().map(
      (snap) => snap.docs
          .map((d) => DebtItem.fromMap(id: d.id, map: d.data()))
          .toList(growable: false),
    );
  }

  Future<void> declareDebtPaid({
    required String groupId,
    required String matchId,
    required String debtItemId,
  }) async {
    await debtItems(groupId: groupId, matchId: matchId).doc(debtItemId).update({
      'status': DebtStatus.paid.name,
      'declaredPaidAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateDebtRecipient({
    required String groupId,
    required String matchId,
    required String debtItemId,
    required String toUid,
  }) async {
    await debtItems(groupId: groupId, matchId: matchId).doc(debtItemId).update({
      'toUid': toUid,
    });
  }

  static List<DebtItem> sortDebtsForLedger(List<DebtItem> debts) {
    final copy = [...debts];
    copy.sort((a, b) {
      final statusOrder = a.status.index.compareTo(b.status.index);
      if (statusOrder != 0) return statusOrder;
      final fromCompare = a.fromUid.compareTo(b.fromUid);
      if (fromCompare != 0) return fromCompare;
      return a.toUid.compareTo(b.toUid);
    });
    return copy;
  }

  Future<List<TournamentTeam>> listTournamentTeams(String tournamentId) async {
    await _ensureFirestoreAuth();

    final teamsSnap =
        await db.collection(FirestorePaths.tournamentTeams(tournamentId)).get();
    if (teamsSnap.docs.isNotEmpty) {
      final teams = teamsSnap.docs
          .map(
            (doc) => TournamentTeam.fromMap(id: doc.id, data: doc.data()),
          )
          .where((team) => !team.id.startsWith('TBD_'))
          .toList();
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    }

    final matchesSnap =
        await db.collection(FirestorePaths.tournamentMatches(tournamentId)).get();
    final byId = <String, TournamentTeam>{};
    for (final doc in matchesSnap.docs) {
      final data = doc.data();
      for (final field in ['homeTeamId', 'awayTeamId']) {
        final id = data[field] as String?;
        if (id == null || id.startsWith('TBD_')) continue;
        byId.putIfAbsent(id, () => TournamentTeam(id: id, name: id));
      }
    }

    final teams = byId.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return teams;
  }

  Future<int> countIncludedCatalogMatches({
    required String tournamentId,
    required List<String> teamIds,
    required List<String> stages,
  }) async {
    await _ensureFirestoreAuth();

    final matches = db.collection(FirestorePaths.tournamentMatches(tournamentId));

    final ids = <String>{};

    if (stages.isNotEmpty) {
      final chunks = _chunks(stages, 10);
      for (final chunk in chunks) {
        final snap = await matches.where('stage', whereIn: chunk).get();
        for (final d in snap.docs) {
          ids.add(d.id);
        }
      }
    }

    if (teamIds.isNotEmpty) {
      final chunks = _chunks(teamIds, 10);
      for (final chunk in chunks) {
        final snap = await matches.where('teamIds', arrayContainsAny: chunk).get();
        for (final d in snap.docs) {
          ids.add(d.id);
        }
      }
    }

    return ids.length;
  }

  static Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    if (items.isEmpty) return;
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size) < items.length ? (i + size) : items.length;
      yield items.sublist(i, end);
    }
  }
}
