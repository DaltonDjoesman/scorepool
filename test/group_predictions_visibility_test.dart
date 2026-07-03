import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/match.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/screens/match/group_predictions_list.dart';
import 'package:worldcupbettracker_app/src/utils/match_lock.dart';

GroupMatchOverlay _scheduledMatch({required DateTime kickoff}) =>
    GroupMatchOverlay(
      matchId: 'm1',
      groupId: 'g1',
      excludedByFilter: false,
      lockedInGroup: false,
      winnerUids: const [],
      accumulatedFromPreviousCents: 0,
      status: MatchStatus.scheduled,
      matchTimeUtc: kickoff,
      homeTeamId: 'BRA',
      awayTeamId: 'ARG',
      stage: 'Grupo A',
    );

void main() {
  test('shouldShowGroupPredictions after lock on scheduled match', () {
    final kickoff = DateTime.now().toUtc().add(const Duration(minutes: 10));
    final match = _scheduledMatch(kickoff: kickoff);
    expect(
      shouldShowGroupPredictions(match: match, predictionLockMinutes: 15),
      isTrue,
    );
    expect(isBeforeLock(match: match, predictionLockMinutes: 15), isFalse);
  });

  test('shouldShowGroupPredictions false before lock on scheduled match', () {
    final kickoff = DateTime.now().toUtc().add(const Duration(hours: 2));
    final match = _scheduledMatch(kickoff: kickoff);
    expect(
      shouldShowGroupPredictions(match: match, predictionLockMinutes: 15),
      isFalse,
    );
  });
}
