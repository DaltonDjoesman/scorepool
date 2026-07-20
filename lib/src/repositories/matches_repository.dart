import '../firestore/firestore_paths.dart';
import '../models/match.dart';
import '../models/match_status.dart';
import '../models/tournament_team.dart';
import 'firestore_client.dart';

class MatchesRepository {
  MatchesRepository(this._client);

  final FirestoreClient _client;

  Stream<List<GroupMatchOverlay>> watchGroupMatches({
    required String groupId,
    required bool excludedByFilter,
    bool descending = false,
  }) {
    var query = _client.groupMatches(
      groupId,
    ).where('excludedByFilter', isEqualTo: excludedByFilter);

    query = descending
        ? query.orderBy('matchTimeUtc', descending: true)
        : query.orderBy('matchTimeUtc');

    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => GroupMatchOverlay.fromMap(
              matchId: d.id,
              groupId: groupId,
              map: d.data(),
            ),
          )
          .toList(growable: false),
    );
  }

  Stream<GroupMatchOverlay?> watchGroupMatch({
    required String groupId,
    required String matchId,
  }) {
    return _client.groupMatches(groupId).doc(matchId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return GroupMatchOverlay.fromMap(
        matchId: snap.id,
        groupId: groupId,
        map: data,
      );
    });
  }

  static const tournamentId = 'wc2026';

  /// Watches catalog matches for a knockout stage (`final`, `third_place`, …).
  Stream<List<TournamentMatch>> watchCatalogMatchesByStage(String stage) {
    return _client.db
        .collection(FirestorePaths.tournamentMatches(tournamentId))
        .where('stage', isEqualTo: stage)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => TournamentMatch.fromMap(id: d.id, map: d.data()))
              .toList(growable: false),
        );
  }

  /// True when every WC2026 catalog match is finished.
  Stream<bool> watchWorldCupFinished() {
    return _client.db
        .collection(FirestorePaths.tournamentMatches(tournamentId))
        .snapshots()
        .map((snap) {
          if (snap.docs.isEmpty) return false;
          return snap.docs.every((d) {
            final status = d.data()['status'] as String? ?? '';
            return status == MatchStatus.finished.name;
          });
        });
  }

  Future<List<TournamentTeam>> listTournamentTeams(String tournamentId) async {
    await _client.ensureFirebaseAuth();

    final teamsSnap = await _client.db
        .collection(FirestorePaths.tournamentTeams(tournamentId))
        .get();
    if (teamsSnap.docs.isNotEmpty) {
      final teams = teamsSnap.docs
          .map(
            (doc) => TournamentTeam.fromMap(id: doc.id, data: doc.data()),
          )
          .where((team) => !team.id.startsWith('TBD_'))
          .toList();
      teams.sort((a, b) => a.name.compareTo(b.name));
      return teams;
    }

    final matchesSnap = await _client.db
        .collection(FirestorePaths.tournamentMatches(tournamentId))
        .get();
    final byId = <String, TournamentTeam>{};
    for (final doc in matchesSnap.docs) {
      final data = doc.data();
      for (final field in ['homeTeamId', 'awayTeamId']) {
        final id = data[field] as String?;
        if (id == null || id.startsWith('TBD_')) continue;
        byId.putIfAbsent(id, () => TournamentTeam(id: id, name: id));
      }
    }

    final teams = byId.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return teams;
  }

  Future<int> countIncludedCatalogMatches({
    required String tournamentId,
    required List<String> teamIds,
    required List<String> stages,
  }) async {
    await _client.ensureFirebaseAuth();

    final matches =
        _client.db.collection(FirestorePaths.tournamentMatches(tournamentId));

    final ids = <String>{};

    if (stages.isNotEmpty) {
      final chunks = FirestoreClient.chunks(stages, 10);
      for (final chunk in chunks) {
        final snap = await matches.where('stage', whereIn: chunk).get();
        for (final d in snap.docs) {
          ids.add(d.id);
        }
      }
    }

    if (teamIds.isNotEmpty) {
      final chunks = FirestoreClient.chunks(teamIds, 10);
      for (final chunk in chunks) {
        final snap =
            await matches.where('teamIds', arrayContainsAny: chunk).get();
        for (final d in snap.docs) {
          ids.add(d.id);
        }
      }
    }

    return ids.length;
  }
}
