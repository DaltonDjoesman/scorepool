import 'package:cloud_firestore/cloud_firestore.dart';

import '../firestore/firestore_paths.dart';
import '../models/debt.dart';
import '../models/match_status.dart';
import '../models/member.dart';
import '../utils/team_crest_resolve.dart';

/// Stable IDs for the in-memory screenshot demo (not written to production).
abstract final class ScreenshotDemoIds {
  static const groupId = 'prints-copa-2026';
  static const tournamentId = 'wc2026';

  static const ana = 'demo-ana';
  static const bruno = 'demo-bruno';
  static const carla = 'demo-carla';
  static const diego = 'demo-diego';
  static const elena = 'demo-elena';
  static const felipe = 'demo-felipe';

  static const matchQfEspBel = 'demo-qf-esp-bel';
  static const matchSfEspFra = 'demo-sf-esp-fra';
  static const matchSfArgEng = 'demo-sf-arg-eng';
  static const matchThird = 'demo-third-fra-eng';
  static const matchFinal = 'demo-final-esp-arg';
}

/// Populates [db] with a composed WC2026 knockout snapshot for portfolio screenshots.
Future<void> seedScreenshotDemo(FirebaseFirestore db) async {
  final now = DateTime.now().toUtc();
  final groupId = ScreenshotDemoIds.groupId;

  final members = <({String uid, String name, GroupRole role, int scores})>[
    (uid: ScreenshotDemoIds.ana, name: 'Ana', role: GroupRole.admin, scores: 7),
    (
      uid: ScreenshotDemoIds.bruno,
      name: 'Bruno',
      role: GroupRole.member,
      scores: 5,
    ),
    (
      uid: ScreenshotDemoIds.carla,
      name: 'Carla',
      role: GroupRole.member,
      scores: 4,
    ),
    (
      uid: ScreenshotDemoIds.diego,
      name: 'Diego',
      role: GroupRole.member,
      scores: 3,
    ),
    (
      uid: ScreenshotDemoIds.elena,
      name: 'Elena',
      role: GroupRole.member,
      scores: 2,
    ),
    (
      uid: ScreenshotDemoIds.felipe,
      name: 'Felipe',
      role: GroupRole.member,
      scores: 1,
    ),
  ];

  await db.doc(FirestorePaths.group(groupId)).set({
    'name': 'CopaBolão Prints',
    'currency': 'BRL',
    'entryFeeCents': 2000,
    'predictionLockMinutes': 15,
    'adminUids': [ScreenshotDemoIds.ana],
    'matchFilter': {
      'teamIds': <String>[],
      'stages': [
        'quarterfinal',
        'semifinal',
        'third_place',
        'final',
      ],
    },
    'carryOverPotCents': 0,
  });

  for (final m in members) {
    await db.doc(FirestorePaths.groupMember(groupId, m.uid)).set({
      'uid': m.uid,
      'displayName': m.name,
      'photoUrl': null,
      'role': m.role.name,
      'perfectScoresCount': m.scores,
    });
    await db.doc(FirestorePaths.user(m.uid)).set({
      'uid': m.uid,
      'displayName': m.name,
      'photoUrl': null,
      'groupIds': [groupId],
    });
  }

  Future<void> writeCatalogAndOverlay({
    required String matchId,
    required String homeTeamId,
    required String awayTeamId,
    required String stage,
    required DateTime matchTimeUtc,
    required MatchStatus status,
    int? homeScore,
    int? awayScore,
    bool lockedInGroup = false,
    List<String> winnerUids = const [],
    int accumulatedFromPreviousCents = 0,
    int? basePotCents,
    int? totalPotCents,
  }) async {
    final homeFlag = resolveCrestUrl(homeTeamId);
    final awayFlag = resolveCrestUrl(awayTeamId);
    final teamIds = [homeTeamId, awayTeamId];

    await db
        .doc(
          FirestorePaths.tournamentMatch(
            ScreenshotDemoIds.tournamentId,
            matchId,
          ),
        )
        .set({
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
          'source': 'screenshot-demo',
        });

    final overlay = <String, Object?>{
      'matchId': matchId,
      'groupId': groupId,
      'excludedByFilter': false,
      'lockedInGroup': lockedInGroup || status != MatchStatus.scheduled,
      'winnerUids': winnerUids,
      'accumulatedFromPreviousCents': accumulatedFromPreviousCents,
      'status': status.name,
      'matchTimeUtc': matchTimeUtc.toIso8601String(),
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'stage': stage,
      'homeFlag': homeFlag,
      'awayFlag': awayFlag,
      'homeScore': homeScore,
      'awayScore': awayScore,
    };
    if (basePotCents != null) overlay['basePotCents'] = basePotCents;
    if (totalPotCents != null) overlay['totalPotCents'] = totalPotCents;
    if (status == MatchStatus.finished && winnerUids.isNotEmpty) {
      overlay['closeoutAt'] = matchTimeUtc.toIso8601String();
    }

    await db.doc(FirestorePaths.groupMatch(groupId, matchId)).set(overlay);

    for (final m in members) {
      await db
          .doc(FirestorePaths.groupRoundUser(groupId, matchId, m.uid))
          .set({
            'uid': m.uid,
            'groupId': groupId,
            'matchId': matchId,
            'isInPot': true,
          });
    }
  }

  Future<void> writePrediction({
    required String uid,
    required String matchId,
    required int home,
    required int away,
  }) async {
    final id = '${uid}_$matchId';
    await db.doc(FirestorePaths.groupPrediction(groupId, id)).set({
      'groupId': groupId,
      'uid': uid,
      'matchId': matchId,
      'predictedHomeScore': home,
      'predictedAwayScore': away,
    });
  }

  // Finished QF — Spain 2–1 Belgium (real WC2026 result).
  await writeCatalogAndOverlay(
    matchId: ScreenshotDemoIds.matchQfEspBel,
    homeTeamId: 'ESP',
    awayTeamId: 'BEL',
    stage: 'quarterfinal',
    matchTimeUtc: now.subtract(const Duration(days: 5)),
    status: MatchStatus.finished,
    homeScore: 2,
    awayScore: 1,
    lockedInGroup: true,
    winnerUids: [ScreenshotDemoIds.carla],
    basePotCents: 12000,
    totalPotCents: 12000,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.carla,
    matchId: ScreenshotDemoIds.matchQfEspBel,
    home: 2,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.ana,
    matchId: ScreenshotDemoIds.matchQfEspBel,
    home: 1,
    away: 0,
  );

  // Finished SF — Spain 2–0 France (real WC2026 result) + ledger.
  const sfPot = 12000;
  await writeCatalogAndOverlay(
    matchId: ScreenshotDemoIds.matchSfEspFra,
    homeTeamId: 'ESP',
    awayTeamId: 'FRA',
    stage: 'semifinal',
    matchTimeUtc: now.subtract(const Duration(days: 2)),
    status: MatchStatus.finished,
    homeScore: 2,
    awayScore: 0,
    lockedInGroup: true,
    winnerUids: [ScreenshotDemoIds.bruno],
    basePotCents: sfPot,
    totalPotCents: sfPot,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.bruno,
    matchId: ScreenshotDemoIds.matchSfEspFra,
    home: 2,
    away: 0,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.ana,
    matchId: ScreenshotDemoIds.matchSfEspFra,
    home: 1,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.carla,
    matchId: ScreenshotDemoIds.matchSfEspFra,
    home: 2,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.diego,
    matchId: ScreenshotDemoIds.matchSfEspFra,
    home: 0,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.elena,
    matchId: ScreenshotDemoIds.matchSfEspFra,
    home: 3,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.felipe,
    matchId: ScreenshotDemoIds.matchSfEspFra,
    home: 1,
    away: 0,
  );

  // 5 losers × 2400 = 12000 to Bruno.
  const share = 2400;
  final debts = <({String from, DebtStatus status})>[
    (from: ScreenshotDemoIds.ana, status: DebtStatus.pending),
    (from: ScreenshotDemoIds.carla, status: DebtStatus.paid),
    (from: ScreenshotDemoIds.diego, status: DebtStatus.pending),
    (from: ScreenshotDemoIds.elena, status: DebtStatus.paid),
    (from: ScreenshotDemoIds.felipe, status: DebtStatus.pending),
  ];
  for (final d in debts) {
    final id = '${d.from}_${ScreenshotDemoIds.bruno}';
    await db
        .doc(
          FirestorePaths.groupDebtItem(
            groupId,
            ScreenshotDemoIds.matchSfEspFra,
            id,
          ),
        )
        .set({
          'groupId': groupId,
          'matchId': ScreenshotDemoIds.matchSfEspFra,
          'fromUid': d.from,
          'toUid': ScreenshotDemoIds.bruno,
          'amountCents': share,
          'status': d.status.name,
        });
  }

  // Live SF — Argentina vs England, partial 1–1 (composed for Ao vivo tab).
  await writeCatalogAndOverlay(
    matchId: ScreenshotDemoIds.matchSfArgEng,
    homeTeamId: 'ARG',
    awayTeamId: 'ENG',
    stage: 'semifinal',
    matchTimeUtc: now.subtract(const Duration(minutes: 35)),
    status: MatchStatus.live,
    homeScore: 1,
    awayScore: 1,
    lockedInGroup: true,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.ana,
    matchId: ScreenshotDemoIds.matchSfArgEng,
    home: 2,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.bruno,
    matchId: ScreenshotDemoIds.matchSfArgEng,
    home: 1,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.carla,
    matchId: ScreenshotDemoIds.matchSfArgEng,
    home: 1,
    away: 0,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.diego,
    matchId: ScreenshotDemoIds.matchSfArgEng,
    home: 2,
    away: 0,
  );

  // Upcoming 3rd place — France vs England.
  await writeCatalogAndOverlay(
    matchId: ScreenshotDemoIds.matchThird,
    homeTeamId: 'FRA',
    awayTeamId: 'ENG',
    stage: 'third_place',
    matchTimeUtc: now.add(const Duration(days: 2, hours: 4)),
    status: MatchStatus.scheduled,
    lockedInGroup: false,
  );

  // Upcoming final — Spain vs Argentina, kickoff in ~90 min (prediction open).
  await writeCatalogAndOverlay(
    matchId: ScreenshotDemoIds.matchFinal,
    homeTeamId: 'ESP',
    awayTeamId: 'ARG',
    stage: 'final',
    matchTimeUtc: now.add(const Duration(minutes: 90)),
    status: MatchStatus.scheduled,
    lockedInGroup: false,
  );
  // Ana has no prediction yet — empty inputs for the prediction screenshot.
  await writePrediction(
    uid: ScreenshotDemoIds.bruno,
    matchId: ScreenshotDemoIds.matchFinal,
    home: 1,
    away: 0,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.carla,
    matchId: ScreenshotDemoIds.matchFinal,
    home: 2,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.diego,
    matchId: ScreenshotDemoIds.matchFinal,
    home: 1,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.elena,
    matchId: ScreenshotDemoIds.matchFinal,
    home: 0,
    away: 1,
  );
  await writePrediction(
    uid: ScreenshotDemoIds.felipe,
    matchId: ScreenshotDemoIds.matchFinal,
    home: 2,
    away: 0,
  );
}
