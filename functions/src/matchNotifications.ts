import * as admin from 'firebase-admin';
import { logger } from 'firebase-functions';

type GroupMatch = {
  matchId: string;
  matchTimeUtc: string;
  status: string;
  excludedByFilter?: boolean;
  accumulatedFromPreviousCents?: number;
  lockWarningSentAt?: FirebaseFirestore.Timestamp;
  kickoffNoticeSentAt?: FirebaseFirestore.Timestamp;
  carryoverNoticeSentAt?: FirebaseFirestore.Timestamp;
};

async function collectGroupTokens(
  db: FirebaseFirestore.Firestore,
  groupId: string,
): Promise<string[]> {
  const members = await db.collection(`groups/${groupId}/members`).get();
  const tokens = members.docs
    .map((doc) => doc.data().fcmToken as string | undefined)
    .filter((token): token is string => typeof token === 'string' && token.length > 0);
  return [...new Set(tokens)];
}

async function sendMulticast(
  tokens: string[],
  title: string,
  body: string,
): Promise<void> {
  if (tokens.length === 0) return;

  const messaging = admin.messaging();
  const response = await messaging.sendEachForMulticast({
    tokens,
    notification: { title, body },
  });

  logger.info('Sent match notifications', {
    title,
    successCount: response.successCount,
    failureCount: response.failureCount,
  });
}

export async function dispatchMatchNotifications(
  db: FirebaseFirestore.Firestore,
  now = new Date(),
): Promise<void> {
  const groups = await db.collection('groups').get();
  const nowMs = now.getTime();

  for (const groupDoc of groups.docs) {
    const groupId = groupDoc.id;
    const predictionLockMinutes =
      (groupDoc.data().predictionLockMinutes as number | undefined) ?? 15;
    const tokens = await collectGroupTokens(db, groupId);
    if (tokens.length === 0) continue;

    const matchesSnap = await db.collection(`groups/${groupId}/matches`).get();
    const activeMatches = matchesSnap.docs
      .map((doc) => ({ id: doc.id, ...(doc.data() as GroupMatch) }))
      .filter((match) => match.excludedByFilter !== true);

    for (const match of activeMatches) {
      const matchTimeMs = new Date(match.matchTimeUtc).getTime();
      const lockTimeMs = matchTimeMs - predictionLockMinutes * 60 * 1000;
      const minutesToLock = (lockTimeMs - nowMs) / 60_000;
      const minutesToKickoff = (matchTimeMs - nowMs) / 60_000;
      const ref = db.doc(`groups/${groupId}/matches/${match.id}`);

      if (
        match.status === 'scheduled' &&
        !match.lockWarningSentAt &&
        minutesToLock > 0 &&
        minutesToLock <= 15
      ) {
        await sendMulticast(
          tokens,
          'Tranca em breve',
          `Palpites trancam em ${Math.ceil(minutesToLock)} min (${match.matchId}).`,
        );
        await ref.set(
          { lockWarningSentAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true },
        );
      }

      if (
        match.status === 'scheduled' &&
        !match.kickoffNoticeSentAt &&
        minutesToKickoff > 0 &&
        minutesToKickoff <= 5
      ) {
        await sendMulticast(
          tokens,
          'Bola rolando',
          `O jogo ${match.matchId} está começando.`,
        );
        await ref.set(
          { kickoffNoticeSentAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true },
        );
      }

      if (
        match.status === 'scheduled' &&
        !match.carryoverNoticeSentAt &&
        (match.accumulatedFromPreviousCents ?? 0) > 0
      ) {
        const amount = ((match.accumulatedFromPreviousCents ?? 0) / 100).toFixed(2);
        await sendMulticast(
          tokens,
          'Pote acumulado',
          `O próximo jogo inclui ${amount} acumulados de rodadas anteriores.`,
        );
        await ref.set(
          { carryoverNoticeSentAt: admin.firestore.FieldValue.serverTimestamp() },
          { merge: true },
        );
      }
    }
  }
}
