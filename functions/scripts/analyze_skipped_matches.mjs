import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { fetchWc2026Matches, toFirestoreMatchDoc, teamIdFromApi } = require("../lib/footballDataOrg.js");

function requireEnv(name) {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required env var: ${name}`);
  return value;
}

async function main() {
  const token = requireEnv("FOOTBALL_DATA_TOKEN");
  const { matches } = await fetchWc2026Matches(token);

  const skipped = [];
  for (const match of matches) {
    if (toFirestoreMatchDoc(match)) continue;
    skipped.push({
      id: match.id,
      stage: match.stage,
      home: match.homeTeam,
      away: match.awayTeam,
      homeId: teamIdFromApi(match.homeTeam),
      awayId: teamIdFromApi(match.awayTeam),
    });
  }

  console.log(`total=${matches.length} skipped=${skipped.length}`);
  for (const row of skipped) {
    console.log(JSON.stringify(row));
  }
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
