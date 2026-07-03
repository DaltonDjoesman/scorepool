import * as admin from 'firebase-admin';
import { onDocumentWritten } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

import {
  TOURNAMENT_ID,
  WC2026_SEASON,
  fetchWc2026Matches,
  toFirestoreMatchDoc,
} from './footballDataOrg';
import { GroupDoc, reconcileGroupMatches } from './groupMatchReconciliation';

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

  for (const match of matches) {
    const doc = toFirestoreMatchDoc(match);
    if (!doc || match.id == null) {
      skipped += 1;
      continue;
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

  await metaRef.set(
    {
      status: 'ok',
      provider: 'football-data-org',
      resultSetCount: resultSet.count ?? matches.length,
      upserted,
      skipped,
      durationMs: Date.now() - startedAt,
    },
    { merge: true },
  );

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
