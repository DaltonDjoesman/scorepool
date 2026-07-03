import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/match.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/screens/feed/match_feed_card.dart';

GroupMatchOverlay _finishedMatch() => GroupMatchOverlay(
      matchId: 'm1',
      groupId: 'g1',
      excludedByFilter: false,
      lockedInGroup: false,
      winnerUids: const ['u1'],
      accumulatedFromPreviousCents: 0,
      status: MatchStatus.finished,
      matchTimeUtc: DateTime.utc(2026, 6, 15, 18),
      homeTeamId: 'BRA',
      awayTeamId: 'ARG',
      stage: 'Grupo A',
      totalPotCents: 5000,
    );

void main() {
  test('feedCardCanEditPrediction is false for finished matches', () {
    expect(
      feedCardCanEditPrediction(
        match: _finishedMatch(),
        predictionLockMinutes: 15,
      ),
      isFalse,
    );
  });

  test('feedCardLockedForPredictions is true after lock time', () {
    final pastMatch = GroupMatchOverlay(
      matchId: 'm2',
      groupId: 'g1',
      excludedByFilter: false,
      lockedInGroup: false,
      winnerUids: const [],
      accumulatedFromPreviousCents: 0,
      status: MatchStatus.scheduled,
      matchTimeUtc: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      homeTeamId: 'BRA',
      awayTeamId: 'ARG',
      stage: 'Grupo A',
    );

    expect(
      feedCardLockedForPredictions(
        match: pastMatch,
        predictionLockMinutes: 15,
      ),
      isTrue,
    );
  });
}
