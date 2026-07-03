import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/match.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/utils/match_lock.dart';

GroupMatchOverlay _match({
  required DateTime matchTimeUtc,
  MatchStatus status = MatchStatus.scheduled,
}) {
  return GroupMatchOverlay(
    matchId: 'm1',
    groupId: 'g1',
    excludedByFilter: false,
    lockedInGroup: false,
    winnerUids: const [],
    accumulatedFromPreviousCents: 0,
    status: status,
    matchTimeUtc: matchTimeUtc,
    homeTeamId: 'BRA',
    awayTeamId: 'ARG',
    stage: 'group',
  );
}

void main() {
  test('isBeforeLock is true before lock window ends', () {
    final now = DateTime.utc(2026, 6, 15, 12, 0);
    final match = _match(matchTimeUtc: DateTime.utc(2026, 6, 15, 13, 0));

    expect(
      isBeforeLock(match: match, predictionLockMinutes: 15, now: now),
      isTrue,
    );
  });

  test('isBeforeLock is false after lock window', () {
    final now = DateTime.utc(2026, 6, 15, 12, 46);
    final match = _match(matchTimeUtc: DateTime.utc(2026, 6, 15, 13, 0));

    expect(
      isBeforeLock(match: match, predictionLockMinutes: 15, now: now),
      isFalse,
    );
  });

  test('formatTimeUntilLock renders minutes', () {
    expect(
      formatTimeUntilLock(const Duration(minutes: 12, seconds: 4)),
      'Tranca em 12m',
    );
  });
}
