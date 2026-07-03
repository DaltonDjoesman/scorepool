import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/match.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/utils/pot_calculator.dart';

GroupMatchOverlay _match({MatchStatus status = MatchStatus.scheduled}) =>
    GroupMatchOverlay(
      matchId: 'm1',
      groupId: 'g1',
      excludedByFilter: false,
      lockedInGroup: false,
      winnerUids: const [],
      accumulatedFromPreviousCents: 800,
      status: status,
      matchTimeUtc: DateTime.utc(2026, 6, 15, 18),
      homeTeamId: 'BRA',
      awayTeamId: 'ARG',
      stage: 'Grupo A',
    );

void main() {
  group('PotCalculator', () {
    test('estimatePotCents multiplies entry fee by in-pot count plus carryover',
        () {
      expect(
        PotCalculator.estimatePotCents(
          entryFeeCents: 1000,
          inPotParticipantCount: 5,
          accumulatedFromPreviousCents: 800,
        ),
        5800,
      );
    });

    test('countInPotParticipants defaults missing docs to in-pot', () {
      expect(
        PotCalculator.countInPotParticipants(
          memberCount: 5,
          participationByUid: const {'u1': false, 'u2': true},
        ),
        4,
      );
    });

    test('displayPotCents uses estimate before finish', () {
      expect(
        PotCalculator.displayPotCents(
          match: _match(),
          entryFeeCents: 1000,
          inPotParticipantCount: 3,
        ),
        3800,
      );
    });

    test('displayPotCents uses settled pot when finished', () {
      final match = GroupMatchOverlay(
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
        totalPotCents: 7500,
      );
      expect(
        PotCalculator.displayPotCents(
          match: match,
          entryFeeCents: 1000,
          inPotParticipantCount: 2,
        ),
        7500,
      );
    });
  });
}
