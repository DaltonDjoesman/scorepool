enum DebtStatus { pending, paid }

class DebtItem {
  DebtItem({
    required this.id,
    required this.groupId,
    required this.matchId,
    required this.fromUid,
    required this.toUid,
    required this.amountCents,
    required this.status,
  });

  final String id;
  final String groupId;
  final String matchId;
  final String fromUid;
  final String toUid;
  final int amountCents;
  final DebtStatus status;

  Map<String, Object?> toMap() => {
    'groupId': groupId,
    'matchId': matchId,
    'fromUid': fromUid,
    'toUid': toUid,
    'amountCents': amountCents,
    'status': status.name,
  };

  static String makeId({required String fromUid, required String toUid}) =>
      '${fromUid}_$toUid';

  static DebtItem fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final statusString = (map['status'] as String?) ?? DebtStatus.pending.name;
    final status = DebtStatus.values.firstWhere(
      (s) => s.name == statusString,
      orElse: () => DebtStatus.pending,
    );

    return DebtItem(
      id: id,
      groupId: (map['groupId'] as String?) ?? '',
      matchId: (map['matchId'] as String?) ?? '',
      fromUid: (map['fromUid'] as String?) ?? '',
      toUid: (map['toUid'] as String?) ?? '',
      amountCents: (map['amountCents'] as num?)?.toInt() ?? 0,
      status: status,
    );
  }
}
