import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

import {
  computeBasePotCents,
  computeDebts,
  computeTotalPotCents,
  debtItemId,
  findWinnerUids,
  PredictionScores,
} from './potMath';
import { applyCarryoverToNextMatch } from './carryover';

export type CatalogFinishedMatch = {
  homeScore: number;
  awayScore: number;
  status: string;
};

export async function closeoutGroupMatch(
  db: FirebaseFirestore.Firestore,
  groupId: string,
  matchId: string,
  finalHomeScore: number,
  finalAwayScore: number,
): Promise<boolean> {
  const matchRef = db.doc(`groups/${groupId}/matches/${matchId}`);
  const matchSnap = await matchRef.get();
  if (!matchSnap.exists) return false;

  const matchData = matchSnap.data() ?? {};
  if (matchData.closeoutAt != null) return false;

  const groupRef = db.doc(`groups/${groupId}`);
  const groupSnap = await groupRef.get();
  if (!groupSnap.exists) return false;

  const groupData = groupSnap.data() ?? {};
  const entryFeeCents = (groupData.entryFeeCents as number | undefined) ?? 0;
  const accumulatedFromPreviousCents =
    (matchData.accumulatedFromPreviousCents as number | undefined) ?? 0;

  const [participationSnap, predictionsSnap, membersSnap] = await Promise.all([
    db.collection(`groups/${groupId}/roundParticipants/${matchId}/users`).get(),
    db
      .collection(`groups/${groupId}/predictions`)
      .where('matchId', '==', matchId)
      .get(),
    db.collection(`groups/${groupId}/members`).get(),
  ]);

  const participationByUid = new Map(
    participationSnap.docs.map((doc) => [doc.id, doc.data().isInPot !== false]),
  );
  const inPotUids = membersSnap.docs
    .map((doc) => doc.id)
    .filter((uid) => participationByUid.get(uid) ?? true)
    .sort();

  const predictions: PredictionScores[] = [];
  for (const doc of predictionsSnap.docs) {
    const data = doc.data();
    const uid = data.uid as string | undefined;
    const predictedHomeScore = data.predictedHomeScore;
    const predictedAwayScore = data.predictedAwayScore;
    if (
      uid == null ||
      typeof predictedHomeScore !== 'number' ||
      typeof predictedAwayScore !== 'number' ||
      !inPotUids.includes(uid)
    ) {
      continue;
    }
    predictions.push({ uid, predictedHomeScore, predictedAwayScore });
  }

  const winnerUids = findWinnerUids(predictions, finalHomeScore, finalAwayScore);
  const loserUids = inPotUids.filter((uid) => !winnerUids.includes(uid));
  const basePotCents = computeBasePotCents(entryFeeCents, inPotUids.length);
  const totalPotCents = computeTotalPotCents(
    basePotCents,
    accumulatedFromPreviousCents,
  );

  const batch = db.batch();
  const closeoutAt = admin.firestore.FieldValue.serverTimestamp();

  batch.set(
    matchRef,
    {
      winnerUids,
      basePotCents,
      totalPotCents,
      closeoutAt,
      status: 'finished',
      lockedInGroup: true,
      homeScore: finalHomeScore,
      awayScore: finalAwayScore,
    },
    { merge: true },
  );

  if (winnerUids.length === 0) {
    batch.set(
      groupRef,
      {
        carryOverPotCents: admin.firestore.FieldValue.increment(totalPotCents),
      },
      { merge: true },
    );
  } else {
    const debts = computeDebts(totalPotCents, loserUids, winnerUids);
    for (const debt of debts) {
      const itemRef = db.doc(
        `groups/${groupId}/debts/${matchId}/items/${debtItemId(debt.fromUid, debt.toUid)}`,
      );
      batch.set(
        itemRef,
        {
          groupId,
          matchId,
          fromUid: debt.fromUid,
          toUid: debt.toUid,
          amountCents: debt.amountCents,
          status: 'pending',
        },
        { merge: true },
      );
    }

    for (const winnerUid of winnerUids) {
      const memberRef = db.doc(`groups/${groupId}/members/${winnerUid}`);
      batch.set(
        memberRef,
        { perfectScoresCount: admin.firestore.FieldValue.increment(1) },
        { merge: true },
      );
    }
  }

  await batch.commit();

  if (winnerUids.length === 0) {
    await applyCarryoverToNextMatch(db, groupId);
  }

  logger.info('Group match closeout complete', {
    groupId,
    matchId,
    winnerCount: winnerUids.length,
    totalPotCents,
    inPotCount: inPotUids.length,
  });

  return true;
}

export async function closeoutCatalogMatch(
  db: FirebaseFirestore.Firestore,
  matchId: string,
  catalog: CatalogFinishedMatch,
): Promise<number> {
  if (catalog.status !== 'finished') return 0;
  if (catalog.homeScore == null || catalog.awayScore == null) return 0;

  // Avoid collectionGroup query (needs a Firestore index). Iterate groups instead.
  const groupsSnap = await db.collection('groups').get();
  let closed = 0;
  for (const groupDoc of groupsSnap.docs) {
    const groupId = groupDoc.id;
    const matchRef = db.doc(`groups/${groupId}/matches/${matchId}`);
    const matchSnap = await matchRef.get();
    if (!matchSnap.exists) continue;

    const didClose = await closeoutGroupMatch(
      db,
      groupId,
      matchId,
      catalog.homeScore,
      catalog.awayScore,
    );
    if (didClose) closed += 1;
  }

  return closed;
}
