import admin from "firebase-admin";
import { createRequire } from "node:module";

import { initFirebaseAdmin } from "./firebase_admin_init.mjs";

const require = createRequire(import.meta.url);
const { TOURNAMENT_ID } = require("../lib/footballDataOrg.js");
const { closeoutCatalogMatch } = require("../lib/matchCloseout.js");

async function main() {
  initFirebaseAdmin();
  const db = admin.firestore();

  const finishedSnap = await db
    .collection(`tournaments/${TOURNAMENT_ID}/matches`)
    .where("status", "==", "finished")
    .get();

  console.log(`Found ${finishedSnap.size} finished catalog matches.`);

  let closedTotal = 0;
  let processed = 0;
  for (const doc of finishedSnap.docs) {
    const data = doc.data();
    const homeScore = data.homeScore;
    const awayScore = data.awayScore;
    if (typeof homeScore !== "number" || typeof awayScore !== "number") {
      continue;
    }
    processed += 1;
    const closed = await closeoutCatalogMatch(db, doc.id, {
      status: "finished",
      homeScore,
      awayScore,
    });
    if (closed > 0) {
      console.log(`Match ${doc.id}: closed ${closed} group(s).`);
    }
    closedTotal += closed;
  }

  console.log(
    `Backfill done. processed=${processed} finishedWithScores, groupsClosed=${closedTotal}.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
