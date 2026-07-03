import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_paths.dart';
import '../models/debt.dart';
import '../models/group.dart';
import '../models/member.dart';
import '../models/prediction.dart';

class FirestoreRepository {
  FirestoreRepository(this.db);

  final FirebaseFirestore db;

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

    final batch = db.batch();
    batch.set(doc, group.toMap());

    final creatorProfile = MemberProfile(
      uid: creatorUid,
      displayName: creatorDisplayName,
      photoUrl: creatorPhotoUrl,
      role: GroupRole.admin,
      perfectScoresCount: 0,
    );
    batch.set(members(doc.id).doc(creatorUid), creatorProfile.toMap());

    await batch.commit();

    return doc.id;
  }

  Stream<Group?> watchGroup(String groupId) {
    return groupRef(groupId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Group.fromMap(id: snap.id, map: data);
    });
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
    await groupRef(groupId).update({'matchFilter': matchFilter.toMap()});
  }

  Future<void> upsertMemberProfile({
    required String groupId,
    required String uid,
    required String displayName,
    required String? photoUrl,
  }) async {
    final doc = members(groupId).doc(uid);
    await doc.set({
      'displayName': displayName,
      'photoUrl': photoUrl,
      'role': GroupRole.member.name,
      'perfectScoresCount': 0,
    }, SetOptions(merge: true));
  }

  Future<void> upsertPrediction({
    required String groupId,
    required String uid,
    required String matchId,
    required int? predictedHomeScore,
    required int? predictedAwayScore,
  }) async {
    final id = Prediction.makeId(uid: uid, matchId: matchId);
    final prediction = Prediction(
      id: id,
      groupId: groupId,
      uid: uid,
      matchId: matchId,
      predictedHomeScore: predictedHomeScore,
      predictedAwayScore: predictedAwayScore,
    );

    await predictions(groupId).doc(id).set(prediction.toMap());
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

  Future<int> countIncludedCatalogMatches({
    required String tournamentId,
    required List<String> teamIds,
    required List<String> stages,
  }) async {
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
