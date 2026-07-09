import admin from "firebase-admin";
import { createRequire } from "node:module";

import { initFirebaseAdmin } from "./firebase_admin_init.mjs";

const require = createRequire(import.meta.url);
const { closeoutGroupMatch } = require("../lib/matchCloseout.js");

const matchId = process.argv[2];
const groupId = process.argv[3];

if (!matchId || !groupId) {
  console.error("Usage: node ./scripts/reclose_group_match.mjs <matchId> <groupId>");
  process.exit(1);
}

async function main() {
  initFirebaseAdmin();
  const db = admin.firestore();

  const catalogRef = db.doc(`tournaments/wc2026/matches/${matchId}`);
  const catalogSnap = await catalogRef.get();
  if (!catalogSnap.exists) {
    throw new Error(`Catalog match ${matchId} not found.`);
  }
  const catalog = catalogSnap.data();
  const homeScore = catalog.homeScore;
  const awayScore = catalog.awayScore;
  if (catalog.status !== "finished" || typeof homeScore !== "number" || typeof awayScore !== "number") {
    throw new Error(`Catalog match ${matchId} is not finished with scores.`);
  }

  const matchRef = db.doc(`groups/${groupId}/matches/${matchId}`);
  const matchSnap = await matchRef.get();
  if (!matchSnap.exists) {
    throw new Error(`Group overlay ${groupId}/${matchId} not found.`);
  }

  const groupRef = db.doc(`groups/${groupId}`);
  const matchData = matchSnap.data() ?? {};
  const previousPot = matchData.totalPotCents ?? 0;

  if (matchData.closeoutAt != null && previousPot > 0) {
    await groupRef.set(
      {
        carryOverPotCents: admin.firestore.FieldValue.increment(-previousPot),
      },
      { merge: true },
    );
  }

  const debtsSnap = await db.collection(`groups/${groupId}/debts/${matchId}/items`).get();
  if (!debtsSnap.empty) {
    let batch = db.batch();
    let ops = 0;
    for (const debt of debtsSnap.docs) {
      batch.delete(debt.ref);
      ops += 1;
      if (ops >= 450) {
        await batch.commit();
        batch = db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();
  }

  const previousWinners = (matchData.winnerUids ?? []).filter(Boolean);
  if (previousWinners.length > 0) {
    let batch = db.batch();
    for (const uid of previousWinners) {
      batch.set(
        db.doc(`groups/${groupId}/members/${uid}`),
        { perfectScoresCount: admin.firestore.FieldValue.increment(-1) },
        { merge: true },
      );
    }
    await batch.commit();
  }

  await matchRef.set(
    {
      closeoutAt: admin.firestore.FieldValue.delete(),
      winnerUids: [],
      basePotCents: admin.firestore.FieldValue.delete(),
      totalPotCents: admin.firestore.FieldValue.delete(),
    },
    { merge: true },
  );

  const closed = await closeoutGroupMatch(db, groupId, matchId, homeScore, awayScore);
  console.log(`Reclosed ${groupId}/${matchId}: ${closed ? "ok" : "skipped"}`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
