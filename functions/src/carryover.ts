import { logger } from 'firebase-functions';

export async function applyCarryoverToNextMatch(
  db: FirebaseFirestore.Firestore,
  groupId: string,
): Promise<boolean> {
  const groupRef = db.doc(`groups/${groupId}`);

  return db.runTransaction(async (tx) => {
    const groupSnap = await tx.get(groupRef);
    if (!groupSnap.exists) return false;

    const carryOverPotCents =
      (groupSnap.data()?.carryOverPotCents as number | undefined) ?? 0;
    if (carryOverPotCents <= 0) return false;

    const nextSnap = await tx.get(
      db
        .collection(`groups/${groupId}/matches`)
        .where('excludedByFilter', '==', false)
        .where('status', '==', 'scheduled')
        .orderBy('matchTimeUtc')
        .limit(1),
    );

    const nextDoc = nextSnap.docs[0];
    if (!nextDoc) return false;

    const existingAccum =
      (nextDoc.data().accumulatedFromPreviousCents as number | undefined) ?? 0;
    if (existingAccum > 0) {
      logger.info('Carryover already applied on next match', {
        groupId,
        matchId: nextDoc.id,
        existingAccum,
      });
      return false;
    }

    tx.set(
      nextDoc.ref,
      { accumulatedFromPreviousCents: carryOverPotCents },
      { merge: true },
    );
    tx.set(groupRef, { carryOverPotCents: 0 }, { merge: true });

    logger.info('Applied carryover to next match', {
      groupId,
      matchId: nextDoc.id,
      carryOverPotCents,
    });

    return true;
  });
}
