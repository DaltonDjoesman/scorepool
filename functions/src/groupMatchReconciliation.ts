import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

import { TOURNAMENT_ID } from './footballDataOrg';
import { applyCarryoverToNextMatch } from './carryover';

export type GroupMatchFilter = {
  teamIds?: string[];
  stages?: string[];
};

export type CatalogMatch = {
  id: string;
  homeTeamId: string;
  awayTeamId: string;
  teamIds: string[];
  stage: string;
  matchTimeUtc: string;
  status: string;
  homeFlag: string | null;
  awayFlag: string | null;
};

export type GroupDoc = {
  matchFilter?: GroupMatchFilter;
  predictionLockMinutes?: number;
};

export function matchIncludedInFilter(
  match: Pick<CatalogMatch, 'homeTeamId' | 'awayTeamId' | 'stage'>,
  filter: GroupMatchFilter,
): boolean {
  const teamIds = filter.teamIds ?? [];
  const stages = filter.stages ?? [];

  if (teamIds.includes(match.homeTeamId) || teamIds.includes(match.awayTeamId)) {
    return true;
  }
  return stages.includes(match.stage);
}

export function isLockedInGroup(
  match: Pick<CatalogMatch, 'matchTimeUtc' | 'status'>,
  predictionLockMinutes: number,
  now: Date,
): boolean {
  const matchTime = new Date(match.matchTimeUtc);
  const lockTimeMs = matchTime.getTime() - predictionLockMinutes * 60 * 1000;
  return now.getTime() >= lockTimeMs || match.status !== 'scheduled';
}

export function canSoftExclude(
  match: Pick<CatalogMatch, 'matchTimeUtc' | 'status'>,
  predictionLockMinutes: number,
  now: Date,
): boolean {
  return match.status === 'scheduled' && !isLockedInGroup(match, predictionLockMinutes, now);
}

export function isFutureMatch(match: Pick<CatalogMatch, 'matchTimeUtc'>, now: Date): boolean {
  return new Date(match.matchTimeUtc).getTime() > now.getTime();
}

function chunk<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

function toCatalogMatch(id: string, data: FirebaseFirestore.DocumentData): CatalogMatch | null {
  const matchTimeUtc = data.matchTimeUtc as string | undefined;
  if (!matchTimeUtc) return null;

  const homeTeamId = (data.homeTeamId as string | undefined) ?? '';
  const awayTeamId = (data.awayTeamId as string | undefined) ?? '';

  return {
    id,
    homeTeamId,
    awayTeamId,
    teamIds: ((data.teamIds as string[] | undefined) ?? [homeTeamId, awayTeamId]).filter(Boolean),
    stage: (data.stage as string | undefined) ?? '',
    matchTimeUtc,
    status: (data.status as string | undefined) ?? 'scheduled',
    homeFlag: (data.homeFlag as string | null | undefined) ?? null,
    awayFlag: (data.awayFlag as string | null | undefined) ?? null,
  };
}

async function fetchCatalogMatchesForFilter(
  db: FirebaseFirestore.Firestore,
  filter: GroupMatchFilter,
): Promise<Map<string, CatalogMatch>> {
  const matches = new Map<string, CatalogMatch>();
  const collection = db.collection(`tournaments/${TOURNAMENT_ID}/matches`);

  const stages = filter.stages ?? [];
  for (const stageChunk of chunk(stages, 10)) {
    if (stageChunk.length === 0) continue;
    const snap = await collection.where('stage', 'in', stageChunk).get();
    for (const doc of snap.docs) {
      const match = toCatalogMatch(doc.id, doc.data());
      if (match) matches.set(doc.id, match);
    }
  }

  const teamIds = filter.teamIds ?? [];
  for (const teamChunk of chunk(teamIds, 10)) {
    if (teamChunk.length === 0) continue;
    const snap = await collection.where('teamIds', 'array-contains-any', teamChunk).get();
    for (const doc of snap.docs) {
      const match = toCatalogMatch(doc.id, doc.data());
      if (match) matches.set(doc.id, match);
    }
  }

  return matches;
}

function overlayPayload(
  groupId: string,
  match: CatalogMatch,
  excludedByFilter: boolean,
  lockedInGroup: boolean,
  existing?: FirebaseFirestore.DocumentData,
): FirebaseFirestore.DocumentData {
  return {
    matchId: match.id,
    groupId,
    excludedByFilter,
    lockedInGroup,
    winnerUids: (existing?.winnerUids as string[] | undefined) ?? [],
    accumulatedFromPreviousCents:
      (existing?.accumulatedFromPreviousCents as number | undefined) ?? 0,
    status: match.status,
    matchTimeUtc: match.matchTimeUtc,
    homeTeamId: match.homeTeamId,
    awayTeamId: match.awayTeamId,
    stage: match.stage,
    homeFlag: match.homeFlag,
    awayFlag: match.awayFlag,
    reconciledAt: admin.firestore.FieldValue.serverTimestamp(),
  };
}

export async function reconcileGroupMatches(
  db: FirebaseFirestore.Firestore,
  groupId: string,
  group: GroupDoc,
  now = new Date(),
): Promise<{ added: number; reactivated: number; excluded: number; updated: number; participationCreated: number }> {
  const filter = group.matchFilter ?? { teamIds: [], stages: [] };
  const predictionLockMinutes = group.predictionLockMinutes ?? 15;

  const [catalogById, existingSnap, membersSnap] = await Promise.all([
    fetchCatalogMatchesForFilter(db, filter),
    db.collection(`groups/${groupId}/matches`).get(),
    db.collection(`groups/${groupId}/members`).get(),
  ]);

  const memberUids = membersSnap.docs.map((doc) => doc.id);

  const existingById = new Map<string, FirebaseFirestore.DocumentData>();
  for (const doc of existingSnap.docs) {
    existingById.set(doc.id, doc.data());
  }

  const allMatchIds = new Set<string>([...catalogById.keys(), ...existingById.keys()]);
  let batch = db.batch();
  let batchOps = 0;
  let added = 0;
  let reactivated = 0;
  let excluded = 0;
  let updated = 0;
  let participationCreated = 0;

  const ensureParticipation = async (matchId: string) => {
    if (memberUids.length === 0) return;

    const usersSnap = await db
      .collection(`groups/${groupId}/roundParticipants/${matchId}/users`)
      .get();
    const existingUids = new Set(usersSnap.docs.map((doc) => doc.id));

    for (const uid of memberUids) {
      if (existingUids.has(uid)) continue;
      const userRef = db.doc(
        `groups/${groupId}/roundParticipants/${matchId}/users/${uid}`,
      );
      batch.set(
        userRef,
        { uid, groupId, matchId, isInPot: true },
        { merge: true },
      );
      batchOps += 1;
      participationCreated += 1;
      if (batchOps >= 450) {
        await commitIfNeeded(true);
      }
    }
  };

  const commitIfNeeded = async (force = false) => {
    if (batchOps === 0) return;
    if (!force && batchOps < 450) return;
    await batch.commit();
    batch = db.batch();
    batchOps = 0;
  };

  for (const matchId of allMatchIds) {
    const catalog = catalogById.get(matchId);
    const existing = existingById.get(matchId);
    const included = catalog != null && matchIncludedInFilter(catalog, filter);
    const ref = db.doc(`groups/${groupId}/matches/${matchId}`);

    if (included && catalog) {
      const locked = isLockedInGroup(catalog, predictionLockMinutes, now);
      const future = isFutureMatch(catalog, now);

      if (!existing && future) {
        batch.set(
          ref,
          overlayPayload(groupId, catalog, false, locked),
          { merge: true },
        );
        batchOps += 1;
        added += 1;
        await ensureParticipation(matchId);
      } else if (existing) {
        const wasExcluded = existing.excludedByFilter === true;
        const excludedByFilter = false;
        const payload = overlayPayload(
          groupId,
          catalog,
          excludedByFilter,
          locked,
          existing,
        );

        batch.set(ref, payload, { merge: true });
        batchOps += 1;
        if (wasExcluded) {
          reactivated += 1;
          await ensureParticipation(matchId);
        } else {
          updated += 1;
        }
      }
    } else if (existing && catalog) {
      const locked = isLockedInGroup(catalog, predictionLockMinutes, now);
      const softExclude = canSoftExclude(catalog, predictionLockMinutes, now);

      if (softExclude) {
        batch.set(
          ref,
          overlayPayload(groupId, catalog, true, locked, existing),
          { merge: true },
        );
        batchOps += 1;
        excluded += 1;
      } else {
        batch.set(
          ref,
          overlayPayload(groupId, catalog, existing.excludedByFilter === true, locked, existing),
          { merge: true },
        );
        batchOps += 1;
        updated += 1;
      }
    } else if (existing) {
      // Catalog doc missing — keep overlay, refresh lock flag only.
      const locked = existing.lockedInGroup === true;
      if (locked !== existing.lockedInGroup) {
        batch.set(ref, { lockedInGroup: locked }, { merge: true });
        batchOps += 1;
        updated += 1;
      }
    }

    if (batchOps >= 450) {
      await commitIfNeeded(true);
    }
  }

  await commitIfNeeded(true);

  await applyCarryoverToNextMatch(db, groupId);

  logger.info('Group match reconciliation complete', {
    groupId,
    added,
    reactivated,
    excluded,
    updated,
    participationCreated,
    catalogMatches: catalogById.size,
    existingMatches: existingById.size,
  });

  return { added, reactivated, excluded, updated, participationCreated };
}
