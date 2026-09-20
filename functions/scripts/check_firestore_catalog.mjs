import admin from "firebase-admin";
import { existsSync, readFileSync } from "node:fs";

const saPath = process.env.GOOGLE_APPLICATION_CREDENTIALS;

if (!saPath || !existsSync(saPath)) {
  console.error(
    "Set GOOGLE_APPLICATION_CREDENTIALS to a service-account JSON outside this repo.\n" +
      "See docs/security.md",
  );
  process.exit(1);
}

const sa = JSON.parse(readFileSync(saPath, "utf8"));

admin.initializeApp({
  credential: admin.credential.cert(sa),
  projectId: sa.project_id,
});

const db = admin.firestore();

async function countIncludedCatalogMatches(teamIds, stages) {
  const matches = db.collection("tournaments/wc2026/matches");
  const ids = new Set();

  for (const chunk of chunkList(stages, 10)) {
    const snap = await matches.where("stage", "in", chunk).get();
    for (const doc of snap.docs) ids.add(doc.id);
  }

  for (const chunk of chunkList(teamIds, 10)) {
    const snap = await matches.where("teamIds", "array-contains-any", chunk).get();
    for (const doc of snap.docs) ids.add(doc.id);
  }

  return ids.size;
}

function chunkList(items, size) {
  if (!items.length) return [];
  const chunks = [];
  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }
  return chunks;
}

async function main() {
  const meta = await db.doc("tournaments/wc2026/meta/ingestion").get();
  const all = await db.collection("tournaments/wc2026/matches").count().get();
  const braMatches = await db
    .collection("tournaments/wc2026/matches")
    .where("teamIds", "array-contains", "BRA")
    .count()
    .get();
  const includedCount = await countIncludedCatalogMatches(["BRA"], ["group"]);

  const sample = await db
    .collection("tournaments/wc2026/matches")
    .where("teamIds", "array-contains", "BRA")
    .limit(1)
    .get();

  console.log("project_id:", sa.project_id);
  console.log("ingestion meta:", meta.exists ? JSON.stringify(meta.data()) : null);
  console.log("total matches:", all.data().count);
  console.log("BRA matches:", braMatches.data().count);
  console.log("included count (BRA + group, app logic):", includedCount);

  if (sample.docs[0]) {
    const d = sample.docs[0].data();
    console.log("BRA sample:", {
      id: sample.docs[0].id,
      homeTeamId: d.homeTeamId,
      awayTeamId: d.awayTeamId,
      stage: d.stage,
      matchTimeUtc: d.matchTimeUtc,
      homeFlag: d.homeFlag ? "set" : null,
      source: d.source,
    });
  }

  if (all.data().count < 100) {
    throw new Error(`Expected ~104 matches, got ${all.data().count}`);
  }
  if (braMatches.data().count < 1) {
    throw new Error("Expected at least 1 BRA match");
  }
  if (includedCount < 1) {
    throw new Error("Expected included count > 0 for BRA + group filter");
  }

  console.log("catalog verification passed");
}

main().catch((err) => {
  console.error("Firestore check failed:", err.message ?? err);
  process.exitCode = 1;
});
