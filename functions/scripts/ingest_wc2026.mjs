import admin from "firebase-admin";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const {
  TOURNAMENT_ID,
  fetchWc2026Matches,
  toFirestoreMatchDoc,
} = require("../lib/footballDataOrg.js");

function requireEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

async function main() {
  const token = requireEnv("FOOTBALL_DATA_TOKEN");

  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();
  const { matches, resultSet } = await fetchWc2026Matches(token);

  console.log("football-data.org resultSet:", JSON.stringify(resultSet));

  if (!matches.length) {
    throw new Error("No matches returned from football-data.org; nothing to upsert.");
  }

  const col = db.collection("tournaments").doc(TOURNAMENT_ID).collection("matches");
  const batchSize = 400;
  let batch = db.batch();
  let inBatch = 0;
  let written = 0;
  let skipped = 0;

  for (const match of matches) {
    const doc = toFirestoreMatchDoc(match);
    if (!doc || match.id == null) {
      skipped += 1;
      continue;
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

  const metaRef = db.doc(`tournaments/${TOURNAMENT_ID}/meta/ingestion`);
  await metaRef.set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      status: "ok",
      provider: "football-data-org",
      resultSetCount: resultSet.count ?? matches.length,
      upserted: written,
      skipped,
    },
    { merge: true },
  );

  console.log(
    `Upserted ${written} matches into tournaments/${TOURNAMENT_ID}/matches (skipped ${skipped}).`,
  );
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
