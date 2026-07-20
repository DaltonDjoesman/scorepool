import '../repositories/matches_repository.dart';

class IncludedMatchRecountResult {
  const IncludedMatchRecountResult.success(this.count) : errorMessage = null;
  const IncludedMatchRecountResult.failure(this.errorMessage) : count = null;

  final int? count;
  final String? errorMessage;

  bool get isSuccess => errorMessage == null;
}

/// Counts catalog matches included by a group filter selection.
Future<IncludedMatchRecountResult> recountIncludedCatalogMatches({
  required MatchesRepository matches,
  required String tournamentId,
  required Iterable<String> teamIds,
  required Iterable<String> stages,
  String Function(Object error)? mapError,
}) async {
  try {
    final count = await matches.countIncludedCatalogMatches(
      tournamentId: tournamentId,
      teamIds: teamIds.toList(growable: false),
      stages: stages.toList(growable: false),
    );
    return IncludedMatchRecountResult.success(count);
  } catch (e) {
    final message = mapError?.call(e) ?? e.toString();
    return IncludedMatchRecountResult.failure(message);
  }
}
