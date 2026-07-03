import { createRequire } from "node:module";

import { initFirebaseAdmin } from "./firebase_admin_init.mjs";

const require = createRequire(import.meta.url);
const { TOURNAMENT_ID } = require("../lib/footballDataOrg.js");
const { enrichTournamentCrests } = require("../lib/teamCrestEnrichment.js");

const admin = initFirebaseAdmin();
const db = admin.firestore();

async function main() {
  const tournamentId = process.env.TOURNAMENT_ID ?? TOURNAMENT_ID;
  console.log(`Enriching missing crests for tournaments/${tournamentId}…`);

  const result = await enrichTournamentCrests(db, tournamentId);

  const metaRef = db.doc(`tournaments/${tournamentId}/meta/crestEnrichment`);
  await metaRef.set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "ok",
      provider: "flagcdn",
      ...result,
    },
    { merge: true },
  );

  console.log("Crest enrichment complete:", result);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
