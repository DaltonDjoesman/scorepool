class RoundParticipation {
  RoundParticipation({
    required this.uid,
    required this.groupId,
    required this.matchId,
    required this.isInPot,
  });

  final String uid;
  final String groupId;
  final String matchId;
  final bool isInPot;

  Map<String, Object?> toMap() => {
    'uid': uid,
    'groupId': groupId,
    'matchId': matchId,
    'isInPot': isInPot,
  };

  static RoundParticipation fromMap({
    required String uid,
    required String groupId,
    required String matchId,
    required Map<String, Object?> map,
  }) {
    return RoundParticipation(
      uid: uid,
      groupId: groupId,
      matchId: matchId,
      isInPot: (map['isInPot'] as bool?) ?? true,
    );
  }
}
