import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/match.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/utils/world_cup_standings.dart';

TournamentMatch _match({
  required String id,
  required String stage,
  required String home,
  required String away,
  required int homeScore,
  required int awayScore,
}) {
  return TournamentMatch(
    id: id,
    homeTeamId: home,
    awayTeamId: away,
    teamIds: [home, away],
    stage: stage,
    matchTimeUtc: DateTime.utc(2026, 7, 19),
    status: MatchStatus.finished,
    homeScore: homeScore,
    awayScore: awayScore,
    homeFlag: null,
    awayFlag: null,
  );
}

void main() {
  test('worldCupFinaleStanding derives champion and top 4', () {
    final standing = worldCupFinaleStanding(
      finalMatch: _match(
        id: 'f',
        stage: 'final',
        home: 'ESP',
        away: 'ARG',
        homeScore: 1,
        awayScore: 0,
      ),
      thirdPlaceMatch: _match(
        id: 't',
        stage: 'third_place',
        home: 'FRA',
        away: 'ENG',
        homeScore: 4,
        awayScore: 6,
      ),
    );

    expect(standing, isNotNull);
    expect(standing!.champion.teamId, 'ESP');
    expect(standing.runnerUp.teamId, 'ARG');
    expect(standing.third?.teamId, 'ENG');
    expect(standing.fourth?.teamId, 'FRA');
    expect(standing.topFour.map((t) => t.teamId).toList(), [
      'ESP',
      'ARG',
      'ENG',
      'FRA',
    ]);
  });

  test('isWorldCupFinished requires every match finished', () {
    expect(
      isWorldCupFinished(
        catalogMatches: [
          _match(
            id: '1',
            stage: 'group',
            home: 'BRA',
            away: 'MAR',
            homeScore: 1,
            awayScore: 0,
          ),
        ],
      ),
      isTrue,
    );
    expect(
      isWorldCupFinished(
        catalogMatches: [
          TournamentMatch(
            id: '2',
            homeTeamId: 'BRA',
            awayTeamId: 'MAR',
            teamIds: const ['BRA', 'MAR'],
            stage: 'group',
            matchTimeUtc: DateTime.utc(2026, 6, 1),
            status: MatchStatus.scheduled,
            homeScore: null,
            awayScore: null,
            homeFlag: null,
            awayFlag: null,
          ),
        ],
      ),
      isFalse,
    );
  });
}
