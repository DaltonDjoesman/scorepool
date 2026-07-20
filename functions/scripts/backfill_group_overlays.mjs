import admin from "firebase-admin";
import { createRequire } from "node:module";

import { initFirebaseAdmin } from "./firebase_admin_init.mjs";

const require = createRequire(import.meta.url);
const { reconcileAllGroups } = require("../lib/groupMatchReconciliation.js");

/**
 * One-shot: re-copy catalog homeTeamId/awayTeamId (and flags) into every
 * group's match overlays. Fixes knockout TBD placeholders after teams are set.
 */
async function main() {
  initFirebaseAdmin();
  const db = admin.firestore();

  const result = await reconcileAllGroups(db);
  console.log(`Reconciled ${result.groups} group(s).`);
  for (const row of result.results) {
    console.log(
      `  ${row.groupId}: added=${row.added} updated=${row.updated}`,
    );
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
