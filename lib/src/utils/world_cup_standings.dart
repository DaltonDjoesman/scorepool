import '../models/match.dart';
import '../models/match_status.dart';
import 'team_metadata.dart';

class WorldCupTeamResult {
  const WorldCupTeamResult({
    required this.rank,
    required this.teamId,
    this.crestUrl,
  });

  final int rank;
  final String teamId;
  final String? crestUrl;

  String get label => TeamMetadata.label(teamId);
}

/// Podium derived from finished WC `final` + `third_place` catalog matches.
class WorldCupFinaleStanding {
  const WorldCupFinaleStanding({
    required this.champion,
    required this.runnerUp,
    this.third,
    this.fourth,
  });

  final WorldCupTeamResult champion;
  final WorldCupTeamResult runnerUp;
  final WorldCupTeamResult? third;
  final WorldCupTeamResult? fourth;

  List<WorldCupTeamResult> get topFour => [
        champion,
        runnerUp,
        ?third,
        ?fourth,
      ];
}

({String winnerId, String loserId, String? winnerFlag, String? loserFlag})?
    _winnerLoser(TournamentMatch match) {
  if (match.status != MatchStatus.finished) return null;
  if (TeamMetadata.isPlaceholder(match.homeTeamId) ||
      TeamMetadata.isPlaceholder(match.awayTeamId)) {
    return null;
  }
  final home = match.homeScore;
  final away = match.awayScore;
  if (home == null || away == null) return null;
  if (home == away) return null; // unexpected for knockout; skip

  final homeWins = home > away;
  return (
    winnerId: homeWins ? match.homeTeamId : match.awayTeamId,
    loserId: homeWins ? match.awayTeamId : match.homeTeamId,
    winnerFlag: homeWins ? match.homeFlag : match.awayFlag,
    loserFlag: homeWins ? match.awayFlag : match.homeFlag,
  );
}

/// Builds standings when the final (and optionally 3rd-place) is finished.
WorldCupFinaleStanding? worldCupFinaleStanding({
  TournamentMatch? finalMatch,
  TournamentMatch? thirdPlaceMatch,
}) {
  if (finalMatch == null) return null;
  final finalResult = _winnerLoser(finalMatch);
  if (finalResult == null) return null;

  WorldCupTeamResult? third;
  WorldCupTeamResult? fourth;
  if (thirdPlaceMatch != null) {
    final thirdResult = _winnerLoser(thirdPlaceMatch);
    if (thirdResult != null) {
      third = WorldCupTeamResult(
        rank: 3,
        teamId: thirdResult.winnerId,
        crestUrl: thirdResult.winnerFlag,
      );
      fourth = WorldCupTeamResult(
        rank: 4,
        teamId: thirdResult.loserId,
        crestUrl: thirdResult.loserFlag,
      );
    }
  }

  return WorldCupFinaleStanding(
    champion: WorldCupTeamResult(
      rank: 1,
      teamId: finalResult.winnerId,
      crestUrl: finalResult.winnerFlag,
    ),
    runnerUp: WorldCupTeamResult(
      rank: 2,
      teamId: finalResult.loserId,
      crestUrl: finalResult.loserFlag,
    ),
    third: third,
    fourth: fourth,
  );
}

bool isWorldCupFinished({
  required Iterable<TournamentMatch> catalogMatches,
}) {
  final matches = catalogMatches.toList(growable: false);
  if (matches.isEmpty) return false;
  return matches.every((m) => m.status == MatchStatus.finished);
}
