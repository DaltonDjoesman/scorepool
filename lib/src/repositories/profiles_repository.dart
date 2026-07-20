import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/member.dart';
import '../models/user_profile.dart';
import 'firestore_client.dart';

class ProfilesRepository {
  ProfilesRepository(this._client);

  final FirestoreClient _client;

  Future<UserProfile?> fetchUserProfile(String uid) async {
    final snap = await _client.userRef(uid).get();
    final data = snap.data();
    if (data == null) return null;
    return UserProfile.fromMap(uid: uid, map: data);
  }

  Stream<UserProfile?> watchUserProfile(String uid) {
    return _client.userRef(uid).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return UserProfile.fromMap(uid: uid, map: data);
    });
  }

  Future<void> updateUserProfile({
    required String uid,
    required String displayName,
  }) async {
    await _client.ensureFirebaseAuth();
    final trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw StateError('Informe um nome para o perfil.');
    }

    await _client.userRef(uid).set({
      'uid': uid,
      'displayName': trimmed,
    }, SetOptions(merge: true));

    final groupIds = await _client.userGroupIds(uid);
    if (groupIds.isEmpty) return;

    var batch = _client.db.batch();
    var ops = 0;
    for (final groupId in groupIds) {
      batch.update(_client.members(groupId).doc(uid), {
        'displayName': trimmed,
      });
      ops += 1;
      if (ops >= 450) {
        await batch.commit();
        batch = _client.db.batch();
        ops = 0;
      }
    }
    if (ops > 0) {
      await batch.commit();
    }
  }

  Stream<List<MemberProfile>> watchMembers(String groupId) {
    return _client.members(groupId).snapshots().map(
      (snap) => snap.docs
          .map((d) => MemberProfile.fromMap(uid: d.id, map: d.data()))
          .toList(growable: false),
    );
  }

  Future<void> updateMemberPerfectScoresCount({
    required String groupId,
    required String memberUid,
    required int perfectScoresCount,
  }) async {
    await _client.ensureFirebaseAuth();
    if (perfectScoresCount < 0) {
      throw StateError('A pontuação não pode ser negativa.');
    }
    await _client.members(groupId).doc(memberUid).update({
      'perfectScoresCount': perfectScoresCount,
    });
  }

  Future<void> saveFcmToken({
    required String groupId,
    required String uid,
    required String token,
  }) async {
    await _client.members(groupId).doc(uid).set({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
