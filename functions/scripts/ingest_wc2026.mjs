import admin from "firebase-admin";
import { createRequire } from "node:module";

import { initFirebaseAdmin } from "./firebase_admin_init.mjs";

const require = createRequire(import.meta.url);
const {
  TOURNAMENT_ID,
  fetchWc2026Matches,
  collectTeamsFromMatch,
  toFirestoreMatchDoc,
} = require("../lib/footballDataOrg.js");
const { enrichTournamentCrests } = require("../lib/teamCrestEnrichment.js");
const { closeoutCatalogMatch } = require("../lib/matchCloseout.js");
const { reconcileAllGroups } = require("../lib/groupMatchReconciliation.js");

function requireEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

async function main() {
  const token = requireEnv("FOOTBALL_DATA_TOKEN");

  initFirebaseAdmin();

  const db = admin.firestore();
  const { matches, resultSet } = await fetchWc2026Matches(token);

  console.log("football-data.org resultSet:", JSON.stringify(resultSet));

  if (!matches.length) {
    throw new Error("No matches returned from football-data.org; nothing to upsert.");
  }

  const col = db.collection("tournaments").doc(TOURNAMENT_ID).collection("matches");
  const teamsCol = db.collection("tournaments").doc(TOURNAMENT_ID).collection("teams");
  const batchSize = 400;
  let batch = db.batch();
  let inBatch = 0;
  let written = 0;
  let skipped = 0;
  const teamDocs = new Map();
  const finishedForCloseout = [];

  for (const match of matches) {
    const doc = toFirestoreMatchDoc(match);
    if (!doc || match.id == null) {
      skipped += 1;
      continue;
    }

    if (
      doc.status === "finished" &&
      typeof doc.homeScore === "number" &&
      typeof doc.awayScore === "number"
    ) {
      finishedForCloseout.push({
        matchId: String(match.id),
        homeScore: doc.homeScore,
        awayScore: doc.awayScore,
      });
    }

    for (const team of collectTeamsFromMatch(match, doc)) {
      teamDocs.set(team.id, team.doc);
    }

    const ref = col.doc(String(match.id));
    batch.set(
      ref,
      {
        ...doc,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    inBatch += 1;
    written += 1;

    if (inBatch >= batchSize) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }

  if (inBatch > 0) {
    await batch.commit();
  }

  batch = db.batch();
  inBatch = 0;
  let teamsWritten = 0;

  for (const [teamId, teamDoc] of teamDocs) {
    batch.set(
      teamsCol.doc(teamId),
      {
        ...teamDoc,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    inBatch += 1;
    teamsWritten += 1;

    if (inBatch >= batchSize) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }

  if (inBatch > 0) {
    await batch.commit();
  }

  const metaRef = db.doc(`tournaments/${TOURNAMENT_ID}/meta/ingestion`);
  await metaRef.set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "ok",
      provider: "football-data-org",
      resultSetCount: resultSet.count ?? matches.length,
      upserted: written,
      teamsUpserted: teamsWritten,
      skipped,
    },
    { merge: true },
  );

  console.log(
    `Upserted ${written} matches and ${teamsWritten} teams into tournaments/${TOURNAMENT_ID} (skipped ${skipped}).`,
  );

  const crestResult = await enrichTournamentCrests(db, TOURNAMENT_ID);
  console.log("Crest enrichment:", crestResult);

  await metaRef.set(
    {
      crestEnrichment: crestResult,
      crestEnrichedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  // Keep group overlays in sync when knockout TBDs become real teams.
  const reconcileResult = await reconcileAllGroups(db);
  console.log(
    `Group overlay sync: reconciled ${reconcileResult.groups} group(s).`,
  );

  // Closeout (pote/dívidas/pontos) without Cloud Functions:
  // run it as part of ingestion, which already runs on GitHub Actions schedule.
  let closedTotal = 0;
  for (const finished of finishedForCloseout) {
    const closed = await closeoutCatalogMatch(db, finished.matchId, {
      status: "finished",
      homeScore: finished.homeScore,
      awayScore: finished.awayScore,
    });
    closedTotal += closed;
  }
  console.log(
    `Closeout: processed ${finishedForCloseout.length} finished matches; groups closed=${closedTotal}.`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
