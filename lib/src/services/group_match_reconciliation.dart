import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_paths.dart';
import '../models/group.dart';
import '../models/match.dart';
import '../models/match_status.dart';
import '../utils/team_crest_resolve.dart';

class GroupMatchReconciliation {
  GroupMatchReconciliation(this.db);

  final FirebaseFirestore db;
  static const tournamentId = 'wc2026';

  static bool matchIncludedInFilter(
    TournamentMatch match,
    GroupMatchFilter filter,
  ) {
    if (filter.teamIds.contains(match.homeTeamId) ||
        filter.teamIds.contains(match.awayTeamId)) {
      return true;
    }
    return filter.stages.contains(match.stage);
  }

  static bool isLockedInGroup({
    required TournamentMatch match,
    required int predictionLockMinutes,
    DateTime? now,
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    final lockTime = match.matchTimeUtc.subtract(
      Duration(minutes: predictionLockMinutes),
    );
    return !current.isBefore(lockTime) || match.status != MatchStatus.scheduled;
  }

  static bool canSoftExclude({
    required TournamentMatch match,
    required int predictionLockMinutes,
    DateTime? now,
  }) {
    return match.status == MatchStatus.scheduled &&
        !isLockedInGroup(
          match: match,
          predictionLockMinutes: predictionLockMinutes,
          now: now,
        );
  }

  Future<Map<String, TournamentMatch>> _fetchCatalogMatches(
    GroupMatchFilter filter,
  ) async {
    final matches = <String, TournamentMatch>{};
    final collection = db.collection(
      FirestorePaths.tournamentMatches(tournamentId),
    );

    for (final stageChunk in _chunks(filter.stages, 10)) {
      if (stageChunk.isEmpty) continue;
      final snap = await collection.where('stage', whereIn: stageChunk).get();
      for (final doc in snap.docs) {
        matches[doc.id] = TournamentMatch.fromMap(id: doc.id, map: doc.data());
      }
    }

    for (final teamChunk in _chunks(filter.teamIds, 10)) {
      if (teamChunk.isEmpty) continue;
      final snap = await collection
          .where('teamIds', arrayContainsAny: teamChunk)
          .get();
      for (final doc in snap.docs) {
        matches[doc.id] = TournamentMatch.fromMap(id: doc.id, map: doc.data());
      }
    }

    return matches;
  }

  Future<Map<String, TournamentMatch>> _fetchFinishedCatalogMatches() async {
    final matches = <String, TournamentMatch>{};
    final collection = db.collection(
      FirestorePaths.tournamentMatches(tournamentId),
    );
    final snap = await collection
        .where('status', isEqualTo: MatchStatus.finished.name)
        .get();
    for (final doc in snap.docs) {
      matches[doc.id] = TournamentMatch.fromMap(id: doc.id, map: doc.data());
    }
    return matches;
  }

  Map<String, Object?> _overlayPayload({
    required String groupId,
    required TournamentMatch match,
    required bool excludedByFilter,
    required bool lockedInGroup,
    Map<String, Object?>? existing,
  }) {
    return {
      'matchId': match.id,
      'groupId': groupId,
      'excludedByFilter': excludedByFilter,
      'lockedInGroup': lockedInGroup,
      'winnerUids': existing?['winnerUids'] ?? const <String>[],
      'accumulatedFromPreviousCents':
          (existing?['accumulatedFromPreviousCents'] as num?)?.toInt() ?? 0,
      'status': match.status.name,
      'matchTimeUtc': match.matchTimeUtc.toIso8601String(),
      'homeTeamId': match.homeTeamId,
      'awayTeamId': match.awayTeamId,
      'stage': match.stage,
      'homeFlag': displayCrestUrl(
        teamId: match.homeTeamId,
        apiCrest: match.homeFlag,
      ),
      'awayFlag': displayCrestUrl(
        teamId: match.awayTeamId,
        apiCrest: match.awayFlag,
      ),
      'homeScore': match.homeScore,
      'awayScore': match.awayScore,
      'reconciledAt': FieldValue.serverTimestamp(),
    };
  }

  Future<void> reconcileGroup({
    required String groupId,
    required GroupMatchFilter matchFilter,
    required int predictionLockMinutes,
    DateTime? now,
  }) async {
    final current = (now ?? DateTime.now()).toUtc();
    final catalogById = await _fetchCatalogMatches(matchFilter);
    final finishedById = await _fetchFinishedCatalogMatches();

    final existingSnap = await db
        .collection(FirestorePaths.groupMatches(groupId))
        .get();
    final existingById = {
      for (final doc in existingSnap.docs) doc.id: doc.data(),
    };

    final allMatchIds = <String>{
      ...catalogById.keys,
      ...finishedById.keys,
      ...existingById.keys,
    };

    var batch = db.batch();
    var batchOps = 0;

    Future<void> commitIfNeeded({bool force = false}) async {
      if (batchOps == 0) return;
      if (!force && batchOps < 450) return;
      await batch.commit();
      batch = db.batch();
      batchOps = 0;
    }

    for (final matchId in allMatchIds) {
      final catalog = catalogById[matchId] ?? finishedById[matchId];
      final existing = existingById[matchId];
      final included =
          catalog != null && matchIncludedInFilter(catalog, matchFilter);
      final ref = db.doc(FirestorePaths.groupMatch(groupId, matchId));

      if (included) {
        final catalogMatch = catalog;
        final locked = isLockedInGroup(
          match: catalogMatch,
          predictionLockMinutes: predictionLockMinutes,
          now: current,
        );

        batch.set(
          ref,
          _overlayPayload(
            groupId: groupId,
            match: catalogMatch,
            excludedByFilter: false,
            lockedInGroup: locked,
            existing: existing,
          ),
          SetOptions(merge: true),
        );
        batchOps += 1;
      } else if (catalog != null) {
        final locked = isLockedInGroup(
          match: catalog,
          predictionLockMinutes: predictionLockMinutes,
          now: current,
        );

        if (catalog.status == MatchStatus.finished) {
          batch.set(
            ref,
            _overlayPayload(
              groupId: groupId,
              match: catalog,
              excludedByFilter: true,
              lockedInGroup: locked,
              existing: existing,
            ),
            SetOptions(merge: true),
          );
          batchOps += 1;
        } else if (existing != null) {
          final softExclude = canSoftExclude(
            match: catalog,
            predictionLockMinutes: predictionLockMinutes,
            now: current,
          );

          batch.set(
            ref,
            _overlayPayload(
              groupId: groupId,
              match: catalog,
              excludedByFilter: softExclude
                  ? true
                  : (existing['excludedByFilter'] as bool?) ?? false,
              lockedInGroup: locked,
              existing: existing,
            ),
            SetOptions(merge: true),
          );
          batchOps += 1;
        }
      }

      if (batchOps >= 450) {
        await commitIfNeeded(force: true);
      }
    }

    if (batchOps > 0) {
      await batch.commit();
    }
  }

  static Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    if (items.isEmpty) return;
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size) < items.length ? (i + size) : items.length;
      yield items.sublist(i, end);
    }
  }
}
