import 'match_status.dart';

class TournamentMatch {
  TournamentMatch({
    required this.id,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.teamIds,
    required this.stage,
    required this.matchTimeUtc,
    required this.status,
    required this.homeScore,
    required this.awayScore,
    required this.homeFlag,
    required this.awayFlag,
  });

  final String id;
  final String homeTeamId;
  final String awayTeamId;
  final List<String> teamIds;
  final String stage;
  final DateTime matchTimeUtc;
  final MatchStatus status;
  final int? homeScore;
  final int? awayScore;
  final String? homeFlag;
  final String? awayFlag;

  Map<String, Object?> toMap() => {
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'teamIds': teamIds,
    'stage': stage,
    'matchTimeUtc': matchTimeUtc.toIso8601String(),
    'status': status.name,
    'homeScore': homeScore,
    'awayScore': awayScore,
    'homeFlag': homeFlag,
    'awayFlag': awayFlag,
  };

  static TournamentMatch fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    final homeTeamId = (map['homeTeamId'] as String?) ?? '';
    final awayTeamId = (map['awayTeamId'] as String?) ?? '';
    return TournamentMatch(
      id: id,
      homeTeamId: homeTeamId,
      awayTeamId: awayTeamId,
      teamIds: ((map['teamIds'] as List?) ?? [homeTeamId, awayTeamId])
          .whereType<String>()
          .toList(growable: false),
      stage: (map['stage'] as String?) ?? '',
      matchTimeUtc:
          DateTime.tryParse((map['matchTimeUtc'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      status: MatchStatus.fromString((map['status'] as String?) ?? 'scheduled'),
      homeScore: (map['homeScore'] as num?)?.toInt(),
      awayScore: (map['awayScore'] as num?)?.toInt(),
      homeFlag: map['homeFlag'] as String?,
      awayFlag: map['awayFlag'] as String?,
    );
  }
}

class GroupMatchOverlay {
  GroupMatchOverlay({
    required this.matchId,
    required this.groupId,
    required this.excludedByFilter,
    required this.lockedInGroup,
    required this.winnerUids,
    required this.accumulatedFromPreviousCents,
    required this.status,
    required this.matchTimeUtc,
    required this.homeTeamId,
    required this.awayTeamId,
    required this.stage,
    this.homeFlag,
    this.awayFlag,
    this.basePotCents,
    this.totalPotCents,
  });

  final String matchId;
  final String groupId;
  final bool excludedByFilter;
  final bool lockedInGroup;
  final List<String> winnerUids;
  final int accumulatedFromPreviousCents;
  final MatchStatus status;
  final DateTime matchTimeUtc;
  final String homeTeamId;
  final String awayTeamId;
  final String stage;
  final String? homeFlag;
  final String? awayFlag;
  final int? basePotCents;
  final int? totalPotCents;

  Map<String, Object?> toMap() => {
    'matchId': matchId,
    'groupId': groupId,
    'excludedByFilter': excludedByFilter,
    'lockedInGroup': lockedInGroup,
    'winnerUids': winnerUids,
    'accumulatedFromPreviousCents': accumulatedFromPreviousCents,
    'status': status.name,
    'matchTimeUtc': matchTimeUtc.toIso8601String(),
    'homeTeamId': homeTeamId,
    'awayTeamId': awayTeamId,
    'stage': stage,
    'homeFlag': homeFlag,
    'awayFlag': awayFlag,
    'basePotCents': basePotCents,
    'totalPotCents': totalPotCents,
  };

  static GroupMatchOverlay fromMap({
    required String matchId,
    required String groupId,
    required Map<String, Object?> map,
  }) {
    return GroupMatchOverlay(
      matchId: matchId,
      groupId: groupId,
      excludedByFilter: (map['excludedByFilter'] as bool?) ?? false,
      lockedInGroup: (map['lockedInGroup'] as bool?) ?? false,
      winnerUids: ((map['winnerUids'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      accumulatedFromPreviousCents:
          (map['accumulatedFromPreviousCents'] as num?)?.toInt() ?? 0,
      status: MatchStatus.fromString((map['status'] as String?) ?? 'scheduled'),
      matchTimeUtc:
          DateTime.tryParse((map['matchTimeUtc'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      homeTeamId: (map['homeTeamId'] as String?) ?? '',
      awayTeamId: (map['awayTeamId'] as String?) ?? '',
      stage: (map['stage'] as String?) ?? '',
      homeFlag: map['homeFlag'] as String?,
      awayFlag: map['awayFlag'] as String?,
      basePotCents: (map['basePotCents'] as num?)?.toInt(),
      totalPotCents: (map['totalPotCents'] as num?)?.toInt(),
    );
  }
}
