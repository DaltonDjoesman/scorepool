class Prediction {
  Prediction({
    required this.id,
    required this.groupId,
    required this.uid,
    required this.matchId,
    required this.predictedHomeScore,
    required this.predictedAwayScore,
  });

  final String id;
  final String groupId;
  final String uid;
  final String matchId;
  final int? predictedHomeScore;
  final int? predictedAwayScore;

  Map<String, Object?> toMap() => {
    'groupId': groupId,
    'uid': uid,
    'matchId': matchId,
    'predictedHomeScore': predictedHomeScore,
    'predictedAwayScore': predictedAwayScore,
  };

  static String makeId({required String uid, required String matchId}) =>
      '${uid}_$matchId';

  static Prediction fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    return Prediction(
      id: id,
      groupId: (map['groupId'] as String?) ?? '',
      uid: (map['uid'] as String?) ?? '',
      matchId: (map['matchId'] as String?) ?? '',
      predictedHomeScore: (map['predictedHomeScore'] as num?)?.toInt(),
      predictedAwayScore: (map['predictedAwayScore'] as num?)?.toInt(),
    );
  }
}
