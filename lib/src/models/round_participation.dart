import 'package:cloud_firestore/cloud_firestore.dart';

class RoundParticipation {
  RoundParticipation({
    required this.uid,
    required this.groupId,
    required this.matchId,
    required this.isInPot,
    this.optedOutAt,
  });

  final String uid;
  final String groupId;
  final String matchId;
  final bool isInPot;
  final DateTime? optedOutAt;

  Map<String, Object?> toMap() => {
    'uid': uid,
    'groupId': groupId,
    'matchId': matchId,
    'isInPot': isInPot,
    'optedOutAt': optedOutAt?.toIso8601String(),
  };

  static RoundParticipation fromMap({
    required String uid,
    required String groupId,
    required String matchId,
    required Map<String, Object?> map,
  }) {
    final optedOutRaw = map['optedOutAt'];
    DateTime? optedOutAt;
    if (optedOutRaw is Timestamp) {
      optedOutAt = optedOutRaw.toDate().toUtc();
    } else if (optedOutRaw is String) {
      optedOutAt = DateTime.tryParse(optedOutRaw)?.toUtc();
    }

    return RoundParticipation(
      uid: uid,
      groupId: groupId,
      matchId: matchId,
      isInPot: (map['isInPot'] as bool?) ?? true,
      optedOutAt: optedOutAt,
    );
  }
}
