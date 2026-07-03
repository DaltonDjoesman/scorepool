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
}
