import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/group.dart';
import '../models/member.dart';
import '../models/user_group_membership.dart';
import '../services/group_match_reconciliation.dart';
import 'firestore_client.dart';

class GroupsRepository {
  GroupsRepository(this._client);

  final FirestoreClient _client;

  FirebaseFirestore get db => _client.db;

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
    await _client.ensureFirebaseAuth();

    final resolved = await _client.resolveMemberDisplay(
      uid: creatorUid,
      fallbackName: creatorDisplayName,
      fallbackPhoto: creatorPhotoUrl,
    );

    final doc = _client.groups().doc();

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

    final creatorMemberRef = _client.members(doc.id).doc(creatorUid);
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

    await _client.addUserGroup(creatorUid, doc.id);
    await _client.userRef(creatorUid).set({
      'uid': creatorUid,
      'displayName': resolved.displayName,
      'photoUrl': resolved.photoUrl,
    }, SetOptions(merge: true));

    return doc.id;
  }

  Stream<Group?> watchGroup(String groupId) {
    return _client.groupRef(groupId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Group.fromMap(id: snap.id, map: data);
    });
  }

  Future<bool> isMember({required String groupId, required String uid}) async {
    final memberSnap = await _client.members(groupId).doc(uid).get();
    if (!memberSnap.exists) return false;
    final memberData = memberSnap.data();
    if (memberData != null && memberData['uid'] != uid) {
      await _client.members(groupId).doc(uid).update({'uid': uid});
    }
    await _client.addUserGroup(uid, groupId);
    final groupSnap = await _client.groupRef(groupId).get();
    return groupSnap.exists;
  }

  Future<List<UserGroupMembership>> fetchUserGroups(String uid) async {
    final groupIds = await _client.userGroupIds(uid);
    return _membershipsFromGroupIds(uid, groupIds);
  }

  Stream<List<UserGroupMembership>> watchUserGroups(String uid) {
    return _client.userRef(uid).snapshots().asyncMap((userSnap) async {
      var groupIds = _client.groupIdsFromUserData(userSnap.data());
      if (groupIds.isEmpty) {
        groupIds = await _client.discoverGroupIdsFromMembership(uid);
        if (groupIds.isNotEmpty) {
          await _client.userRef(uid).set({
            'groupIds': groupIds,
          }, SetOptions(merge: true));
        }
      }
      if (groupIds.isEmpty) return const <UserGroupMembership>[];
      return _membershipsFromGroupIds(uid, groupIds);
    });
  }

  Future<List<UserGroupMembership>> _membershipsFromGroupIds(
    String uid,
    List<String> groupIds,
  ) async {
    final memberships = <UserGroupMembership>[];
    for (final groupId in groupIds) {
      final memberSnap = await _client.members(groupId).doc(uid).get();
      if (!memberSnap.exists) {
        await _client.removeUserGroup(uid, groupId);
        continue;
      }

      final groupSnap = await _client.groupRef(groupId).get();
      final data = groupSnap.data();
      if (data == null) {
        await _client.removeUserGroup(uid, groupId);
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
    await _client.ensureFirebaseAuth();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    await _client.groupRef(groupId).delete();
    if (uid != null) {
      await _client.removeUserGroup(uid, groupId);
    }
  }

  Future<void> leaveGroup({
    required String groupId,
    required String uid,
  }) async {
    await _client.ensureFirebaseAuth();
    await _client.members(groupId).doc(uid).delete();
    await _client.removeUserGroup(uid, groupId);
  }

  Future<void> updateGroupMatchFilter({
    required String groupId,
    required GroupMatchFilter matchFilter,
  }) async {
    await _client.ensureFirebaseAuth();
    final groupSnap = await _client.groupRef(groupId).get();
    final group = groupSnap.data();
    if (group == null) return;

    await _client.groupRef(groupId).update({'matchFilter': matchFilter.toMap()});

    final lockMinutes =
        (group['predictionLockMinutes'] as num?)?.toInt() ?? 15;
    await GroupMatchReconciliation(db).reconcileGroup(
      groupId: groupId,
      matchFilter: matchFilter,
      predictionLockMinutes: lockMinutes,
    );
  }

  Future<void> joinGroup({
    required String groupId,
    required String uid,
    required String displayName,
    required String? photoUrl,
  }) async {
    await _client.ensureFirebaseAuth();

    final groupSnap = await _client.groupRef(groupId).get();
    if (!groupSnap.exists) {
      throw StateError('Grupo não encontrado. Verifique o código.');
    }

    final resolved = await _client.resolveMemberDisplay(
      uid: uid,
      fallbackName: displayName,
      fallbackPhoto: photoUrl,
    );

    final memberDoc = _client.members(groupId).doc(uid);
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
    await _client.addUserGroup(uid, groupId);
    await _client.userRef(uid).set({
      'uid': uid,
      'displayName': resolved.displayName,
      'photoUrl': resolved.photoUrl,
    }, SetOptions(merge: true));
  }
}
