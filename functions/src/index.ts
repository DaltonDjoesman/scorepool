import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

import {
  TOURNAMENT_ID,
  WC2026_SEASON,
  collectTeamsFromMatch,
  fetchWc2026Matches,
  toFirestoreMatchDoc,
  type FirestoreTeamDoc,
} from './footballDataOrg';
import { enrichTournamentCrests } from './teamCrestEnrichment';
import { GroupDoc, reconcileGroupMatches, reconcileAllGroups } from './groupMatchReconciliation';
import { closeoutCatalogMatch } from './matchCloseout';
import { dispatchMatchNotifications } from './matchNotifications';

admin.initializeApp();

export const ingestWc2026MatchCatalog = onSchedule('every 6 hours', async () => {
  const db = admin.firestore();

  const token = process.env.FOOTBALL_DATA_TOKEN;
  if (!token) {
    throw new Error('Missing FOOTBALL_DATA_TOKEN in environment (use Functions secrets).');
  }

  const metaRef = db.doc(`tournaments/${TOURNAMENT_ID}/meta/ingestion`);
  const startedAt = Date.now();

  await metaRef.set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'running',
      provider: 'football-data-org',
      season: WC2026_SEASON,
    },
    { merge: true },
  );

  const { matches, resultSet } = await fetchWc2026Matches(token);
  logger.info('Fetched WC2026 matches', { resultSet, count: matches.length });

  let upserted = 0;
  let skipped = 0;
  let batch = db.batch();
  let batchOps = 0;
  const teamDocs = new Map<string, FirestoreTeamDoc>();

  for (const match of matches) {
    const doc = toFirestoreMatchDoc(match);
    if (!doc || match.id == null) {
      skipped += 1;
      continue;
    }

    for (const team of collectTeamsFromMatch(match, doc)) {
      teamDocs.set(team.id, team.doc);
    }

    const docRef = db.doc(`tournaments/${TOURNAMENT_ID}/matches/${match.id}`);
    batch.set(
      docRef,
      {
        ...doc,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    batchOps += 1;
    upserted += 1;

    if (batchOps >= 450) {
      await batch.commit();
      batch = db.batch();
      batchOps = 0;
    }
  }

  if (batchOps > 0) {
    await batch.commit();
  }

  let teamBatch = db.batch();
  let teamBatchOps = 0;
  let teamsUpserted = 0;

  for (const [teamId, teamDoc] of teamDocs) {
    const teamRef = db.doc(`tournaments/${TOURNAMENT_ID}/teams/${teamId}`);
    teamBatch.set(
      teamRef,
      {
        ...teamDoc,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    teamBatchOps += 1;
    teamsUpserted += 1;

    if (teamBatchOps >= 450) {
      await teamBatch.commit();
      teamBatch = db.batch();
      teamBatchOps = 0;
    }
  }

  if (teamBatchOps > 0) {
    await teamBatch.commit();
  }

  const crestResult = await enrichTournamentCrests(db, TOURNAMENT_ID);
  logger.info('Crest enrichment complete', crestResult);

  await metaRef.set(
    {
      status: 'ok',
      provider: 'football-data-org',
      resultSetCount: resultSet.count ?? matches.length,
      upserted,
      teamsUpserted,
      skipped,
      durationMs: Date.now() - startedAt,
      crestEnrichment: crestResult,
    },
    { merge: true },
  );

  const reconcileResult = await reconcileAllGroups(db);
  logger.info('Post-ingest group overlay sync', reconcileResult);

  logger.info('Ingestion complete', { upserted, skipped, resultSetCount: resultSet.count });
});

function matchFilterChanged(
  before: admin.firestore.DocumentData | undefined,
  after: admin.firestore.DocumentData,
): boolean {
  if (!before) return true;
  return JSON.stringify(before.matchFilter ?? {}) !== JSON.stringify(after.matchFilter ?? {});
}

export const reconcileGroupMatchesOnFilterChange = onDocumentWritten(
  'groups/{groupId}',
  async (event) => {
    const afterSnap = event.data?.after;
    if (!afterSnap?.exists) return;

    const before = event.data?.before?.data();
    const after = afterSnap.data();
    if (!after?.matchFilter) return;
    if (!matchFilterChanged(before, after)) return;

    const groupId = event.params.groupId;
    await reconcileGroupMatches(
      admin.firestore(),
      groupId,
      after as GroupDoc,
    );
  },
);

export const closeoutOnCatalogMatchFinished = onDocumentWritten(
  `tournaments/${TOURNAMENT_ID}/matches/{matchId}`,
  async (event) => {
    const before = event.data?.before?.data();
    const afterSnap = event.data?.after;
    if (!afterSnap?.exists) return;

    const after = afterSnap.data();
    if (!after || after.status !== 'finished') return;
    if (before?.status === 'finished') return;

    const homeScore = after.homeScore;
    const awayScore = after.awayScore;
    if (typeof homeScore !== 'number' || typeof awayScore !== 'number') return;

    const closed = await closeoutCatalogMatch(
      admin.firestore(),
      event.params.matchId,
      {
        homeScore,
        awayScore,
        status: 'finished',
      },
    );

    logger.info('Catalog match closeout processed', {
      matchId: event.params.matchId,
      groupsClosed: closed,
    });
  },
);

// Safety net: periodically backfill closeouts for finished matches.
// This handles cases where Functions were deployed late or triggers were missed.
export const backfillFinishedMatchCloseouts = onSchedule('every 30 minutes', async () => {
  const db = admin.firestore();
  const finishedSnap = await db
    .collection(`tournaments/${TOURNAMENT_ID}/matches`)
    .where('status', '==', 'finished')
    .get();

  let processed = 0;
  for (const doc of finishedSnap.docs) {
    const data = doc.data();
    const homeScore = data.homeScore;
    const awayScore = data.awayScore;
    if (typeof homeScore !== 'number' || typeof awayScore !== 'number') continue;
    processed += 1;
    await closeoutCatalogMatch(db, doc.id, {
      homeScore,
      awayScore,
      status: 'finished',
    });
  }

  logger.info('Backfill closeouts finished', {
    finishedCatalogMatches: finishedSnap.size,
    processedWithScores: processed,
  });
});

export const dispatchMatchNotificationsJob = onSchedule(
  'every 15 minutes',
  async () => {
    await dispatchMatchNotifications(admin.firestore());
  },
);
