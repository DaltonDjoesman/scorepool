#!/usr/bin/env node
/**
 * Seeds the public demo Firebase project (copabolaao-demo) with a minimal
 * WC2026 catalog so the installable APK is usable after register/login.
 *
 * Uses the logged-in Firebase CLI OAuth token (project owner) — no service
 * account JSON required. Does not touch production.
 *
 * Usage (from repo root):
 *   node functions/scripts/seed_demo_catalog.mjs
 */
import { readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const PROJECT_ID = "copabolaao-demo";
const TOURNAMENT_ID = "wc2026";

const TEAM_IDS = [
  "ALG", "ARG", "AUS", "AUT", "BEL", "BIH", "BRA", "CAN", "CIV", "COD",
  "COL", "CPV", "CRO", "CUW", "CZE", "ECU", "EGY", "ENG", "ESP", "FRA",
  "GER", "GHA", "HAI", "IRN", "IRQ", "JOR", "JPN", "KOR", "KSA", "MAR",
  "MEX", "NED", "NOR", "NZL", "PAN", "PAR", "POR", "QAT", "RSA", "SCO",
  "SEN", "SUI", "SWE", "TUN", "TUR", "URU", "USA", "UZB",
];

const LABELS = {
  ALG: "Algeria", ARG: "Argentina", AUS: "Australia", AUT: "Austria",
  BEL: "Belgium", BIH: "Bosnia and Herzegovina", BRA: "Brazil", CAN: "Canada",
  CIV: "Côte d'Ivoire", COD: "DR Congo", COL: "Colombia", CPV: "Cabo Verde",
  CRO: "Croatia", CUW: "Curaçao", CZE: "Czechia", ECU: "Ecuador", EGY: "Egypt",
  ENG: "England", ESP: "Spain", FRA: "France", GER: "Germany", GHA: "Ghana",
  HAI: "Haiti", IRN: "Iran", IRQ: "Iraq", JOR: "Jordan", JPN: "Japan",
  KOR: "Korea Republic", KSA: "Saudi Arabia", MAR: "Morocco", MEX: "Mexico",
  NED: "Netherlands", NOR: "Norway", NZL: "New Zealand", PAN: "Panama",
  PAR: "Paraguay", POR: "Portugal", QAT: "Qatar", RSA: "South Africa",
  SCO: "Scotland", SEN: "Senegal", SUI: "Switzerland", SWE: "Sweden",
  TUN: "Tunisia", TUR: "Türkiye", URU: "Uruguay", USA: "USA", UZB: "Uzbekistan",
};

function crest(teamId) {
  return `https://crests.football-data.org/${teamId}.png`;
}

function accessToken() {
  const path = join(homedir(), ".config/configstore/firebase-tools.json");
  const cfg = JSON.parse(readFileSync(path, "utf8"));
  const token = cfg?.tokens?.access_token;
  if (!token) {
    throw new Error("No Firebase CLI access token. Run: npx firebase-tools@latest login");
  }
  return token;
}

async function upsert(token, docPath, fields) {
  const url =
    `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
    `/databases/(default)/documents/${docPath}`;
  const res = await fetch(url, {
    method: "PATCH",
    headers: {
      Authorization: `Bearer ${token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ fields }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Upsert failed ${docPath}: ${res.status} ${body}`);
  }
}

function stringValue(s) {
  return { stringValue: s };
}
function integerValue(n) {
  return { integerValue: String(n) };
}
function booleanValue(b) {
  return { booleanValue: b };
}
function timestampValue(iso) {
  return { timestampValue: iso };
}
function arrayValue(strings) {
  return { arrayValue: { values: strings.map(stringValue) } };
}

function matchFields({
  id,
  home,
  away,
  stage,
  status,
  matchTimeUtc,
  homeScore,
  awayScore,
}) {
  const fields = {
    homeTeamId: stringValue(home),
    awayTeamId: stringValue(away),
    teamIds: arrayValue([home, away]),
    stage: stringValue(stage),
    status: stringValue(status),
    // Client parses ISO strings via DateTime.tryParse — keep as stringValue.
    matchTimeUtc: stringValue(matchTimeUtc),
    homeFlag: stringValue(crest(home)),
    awayFlag: stringValue(crest(away)),
    source: stringValue("demo-seed"),
  };
  if (homeScore != null) fields.homeScore = integerValue(homeScore);
  if (awayScore != null) fields.awayScore = integerValue(awayScore);
  return fields;
}

async function main() {
  const token = accessToken();
  console.log(`Seeding ${PROJECT_ID} tournament ${TOURNAMENT_ID}…`);

  for (const teamId of TEAM_IDS) {
    await upsert(token, `tournaments/${TOURNAMENT_ID}/teams/${teamId}`, {
      name: stringValue(LABELS[teamId] ?? teamId),
      crest: stringValue(crest(teamId)),
    });
  }
  console.log(`  teams: ${TEAM_IDS.length}`);

  const now = Date.now();
  const day = 24 * 60 * 60 * 1000;
  const matches = [
    {
      id: "demo-sf-esp-fra",
      home: "ESP",
      away: "FRA",
      stage: "semifinal",
      status: "finished",
      matchTimeUtc: new Date(now - 5 * day).toISOString(),
      homeScore: 2,
      awayScore: 1,
    },
    {
      id: "demo-sf-arg-eng",
      home: "ARG",
      away: "ENG",
      stage: "semifinal",
      status: "live",
      matchTimeUtc: new Date(now - 30 * 60 * 1000).toISOString(),
      homeScore: 1,
      awayScore: 1,
    },
    {
      id: "demo-final-esp-arg",
      home: "ESP",
      away: "ARG",
      stage: "final",
      status: "scheduled",
      matchTimeUtc: new Date(now + 3 * day).toISOString(),
    },
    {
      id: "demo-third-fra-eng",
      home: "FRA",
      away: "ENG",
      stage: "third_place",
      status: "scheduled",
      matchTimeUtc: new Date(now + 2 * day).toISOString(),
    },
  ];

  for (const m of matches) {
    await upsert(
      token,
      `tournaments/${TOURNAMENT_ID}/matches/${m.id}`,
      matchFields(m),
    );
  }
  console.log(`  matches: ${matches.length}`);

  await upsert(token, `tournaments/${TOURNAMENT_ID}/meta/ingestion`, {
    source: stringValue("demo-seed"),
    lastIngestAt: timestampValue(new Date().toISOString()),
    matchCount: integerValue(matches.length),
    note: stringValue("Portfolio demo catalog — not live football-data.org"),
  });

  console.log("Demo catalog seed complete.");
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exitCode = 1;
});
