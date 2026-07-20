import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_paths.dart';
import '../models/prediction.dart';
import '../models/round_participation.dart';
import 'firestore_client.dart';

class PredictionsRepository {
  PredictionsRepository(this._client);

  final FirestoreClient _client;

  Future<void> upsertPrediction({
    required String groupId,
    required String uid,
    required String matchId,
    required int? predictedHomeScore,
    required int? predictedAwayScore,
  }) async {
    await _client.ensureFirebaseAuth();
    final id = Prediction.makeId(uid: uid, matchId: matchId);
    final prediction = Prediction(
      id: id,
      groupId: groupId,
      uid: uid,
      matchId: matchId,
      predictedHomeScore: predictedHomeScore,
      predictedAwayScore: predictedAwayScore,
    );

    await _client
        .predictions(groupId)
        .doc(id)
        .set(prediction.toMap(), SetOptions(merge: true));
  }

  Stream<Prediction?> watchPrediction({
    required String groupId,
    required String uid,
    required String matchId,
  }) {
    final id = Prediction.makeId(uid: uid, matchId: matchId);
    return _client.predictions(groupId).doc(id).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return Prediction.fromMap(id: snap.id, map: data);
    });
  }

  Stream<List<Prediction>> watchMatchPredictions({
    required String groupId,
    required String matchId,
  }) {
    return _client
        .predictions(groupId)
        .where('matchId', isEqualTo: matchId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => Prediction.fromMap(id: d.id, map: d.data()))
              .toList(growable: false),
        );
  }

  Stream<RoundParticipation?> watchRoundParticipation({
    required String groupId,
    required String matchId,
    required String uid,
  }) {
    return _client.db
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
    return _client.db
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

    await _client.db
        .doc(FirestorePaths.groupRoundUser(groupId, matchId, uid))
        .set(data, SetOptions(merge: true));
  }
}
