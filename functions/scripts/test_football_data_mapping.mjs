import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const {
  mapStage,
  mapStatus,
  teamIdFromApi,
  toFirestoreMatchDoc,
} = require("../lib/footballDataOrg.js");

function assertEqual(actual, expected, label) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${JSON.stringify(expected)}, got ${JSON.stringify(actual)}`);
  }
}

const stageCases = [
  ["GROUP_STAGE", "group"],
  ["LAST_32", "round_of_32"],
  ["LAST_16", "round_of_16"],
  ["QUARTER_FINALS", "quarterfinal"],
  ["SEMI_FINALS", "semifinal"],
  ["THIRD_PLACE", "third_place"],
  ["FINAL", "final"],
];

for (const [input, expected] of stageCases) {
  assertEqual(mapStage(input), expected, `mapStage(${input})`);
}

const statusCases = [
  ["SCHEDULED", "scheduled"],
  ["TIMED", "scheduled"],
  ["IN_PLAY", "live"],
  ["PAUSED", "live"],
  ["FINISHED", "finished"],
  ["AWARDED", "finished"],
];

for (const [input, expected] of statusCases) {
  assertEqual(mapStatus(input), expected, `mapStatus(${input})`);
}

assertEqual(teamIdFromApi({ tla: "bra", id: 764 }), "BRA", "teamIdFromApi tla");
assertEqual(teamIdFromApi({ id: 764 }), "764", "teamIdFromApi numeric");
assertEqual(
  teamIdFromApi({ shortName: "Winner Match 1" }),
  "WINNER_MATCH_1",
  "teamIdFromApi name slug",
);

const placeholderDoc = toFirestoreMatchDoc({
  id: 537390,
  utcDate: "2026-07-19T19:00:00Z",
  status: "SCHEDULED",
  stage: "FINAL",
  homeTeam: { id: null, name: null, shortName: null, tla: null },
  awayTeam: { id: null, name: null, shortName: null, tla: null },
  score: { fullTime: { home: null, away: null } },
});
if (!placeholderDoc) throw new Error("placeholder toFirestoreMatchDoc returned null");
assertEqual(placeholderDoc.homeTeamId, "TBD_537390_H", "placeholder home");
assertEqual(placeholderDoc.awayTeamId, "TBD_537390_A", "placeholder away");
assertEqual(placeholderDoc.stage, "final", "placeholder stage");

const doc = toFirestoreMatchDoc({
  id: 331341,
  utcDate: "2026-06-11T19:00:00Z",
  status: "SCHEDULED",
  stage: "GROUP_STAGE",
  homeTeam: { id: 764, tla: "BRA", crest: "https://example.com/bra.png" },
  awayTeam: { id: 758, tla: "ARG", crest: "https://example.com/arg.png" },
  score: { fullTime: { home: null, away: null } },
});

if (!doc) throw new Error("toFirestoreMatchDoc returned null");
assertEqual(doc.homeTeamId, "BRA", "doc.homeTeamId");
assertEqual(doc.awayTeamId, "ARG", "doc.awayTeamId");
assertEqual(doc.stage, "group", "doc.stage");
assertEqual(doc.status, "scheduled", "doc.status");
assertEqual(doc.source, "football-data-org", "doc.source");
assertEqual(doc.homeFlag, "https://example.com/bra.png", "doc.homeFlag");

console.log("football-data.org mapping smoke test passed");
