import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { fetchWc2026Matches, toFirestoreMatchDoc } = require("../lib/footballDataOrg.js");

function requireEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

async function main() {
  const token = requireEnv("FOOTBALL_DATA_TOKEN");
  const { matches, resultSet } = await fetchWc2026Matches(token);

  console.log("resultSet:", JSON.stringify(resultSet));
  console.log("matches.length:", matches.length);

  const sample = matches.find((m) => m.homeTeam?.tla === "BRA" || m.awayTeam?.tla === "BRA");
  if (!sample) {
    console.log("No BRA sample match found in payload");
    return;
  }

  const doc = toFirestoreMatchDoc(sample);
  console.log("sample match id:", sample.id);
  console.log("mapped doc:", JSON.stringify(doc, null, 2));
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
