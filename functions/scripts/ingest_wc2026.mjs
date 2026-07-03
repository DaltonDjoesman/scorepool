import admin from "firebase-admin";

const API_BASE = "https://v3.football.api-sports.io";
const WC_LEAGUE_ID = 1;
const WC_SEASON = 2026;

function requireEnv(name) {
  const v = process.env[name];
  if (!v) throw new Error(`Missing required env var: ${name}`);
  return v;
}

async function apiGet(pathWithQuery, apiKey) {
  const res = await fetch(`${API_BASE}${pathWithQuery}`, {
    headers: {
      "x-apisports-key": apiKey,
      Accept: "application/json",
    },
  });

  const text = await res.text();
  let json;
  try {
    json = JSON.parse(text);
  } catch {
    throw new Error(`API returned non-JSON (status ${res.status}): ${text.slice(0, 500)}`);
  }

  if (!res.ok) {
    throw new Error(`API error (status ${res.status}): ${JSON.stringify(json).slice(0, 2000)}`);
  }

  return json;
}

function toFirestoreMatch(doc) {
  const fixture = doc?.fixture ?? {};
  const teams = doc?.teams ?? {};
  const goals = doc?.goals ?? {};
  const score = doc?.score ?? {};
  const league = doc?.league ?? {};

  const fixtureId = fixture?.id;
  const isoDate = fixture?.date; // usually ISO8601 UTC
  const matchTime = isoDate ? new Date(isoDate) : null;

  return {
    fixtureId,
    tournamentKey: "wc2026",
    season: WC_SEASON,
    leagueId: WC_LEAGUE_ID,

    matchTimeUtc: matchTime ? admin.firestore.Timestamp.fromDate(matchTime) : null,
    matchTimeIso: isoDate ?? null,

    stage: league?.round ?? null, // e.g. "Group Stage - 1", "Quarter-finals"
    round: league?.round ?? null,

    status: {
      short: fixture?.status?.short ?? null, // NS, 1H, HT, FT, etc.
      long: fixture?.status?.long ?? null,
      elapsed: fixture?.status?.elapsed ?? null,
    },

    venue: fixture?.venue
      ? {
          id: fixture.venue.id ?? null,
          name: fixture.venue.name ?? null,
          city: fixture.venue.city ?? null,
        }
      : null,

    homeTeam: teams?.home
      ? { id: teams.home.id ?? null, name: teams.home.name ?? null }
      : null,
    awayTeam: teams?.away
      ? { id: teams.away.id ?? null, name: teams.away.name ?? null }
      : null,

    goals: {
      home: goals?.home ?? null,
      away: goals?.away ?? null,
    },
    score: {
      halftime: score?.halftime ?? null,
      fulltime: score?.fulltime ?? null,
      extratime: score?.extratime ?? null,
      penalty: score?.penalty ?? null,
    },
  };
}

async function main() {
  const apiKey = requireEnv("API_FOOTBALL_KEY");

  // Prefer Application Default Credentials (GitHub Action writes service account JSON
  // and sets GOOGLE_APPLICATION_CREDENTIALS).
  admin.initializeApp({
    credential: admin.credential.applicationDefault(),
  });

  const db = admin.firestore();

  const payload = await apiGet(`/fixtures?league=${WC_LEAGUE_ID}&season=${WC_SEASON}`, apiKey);
  const fixtures = Array.isArray(payload?.response) ? payload.response : [];

  if (!fixtures.length) {
    console.log("No fixtures returned; nothing to upsert.");
    return;
  }

  const col = db.collection("tournaments").doc("wc2026").collection("matches");
  const batchSize = 400;
  let batch = db.batch();
  let inBatch = 0;
  let written = 0;

  for (const f of fixtures) {
    const match = toFirestoreMatch(f);
    if (!match.fixtureId) continue;

    const ref = col.doc(String(match.fixtureId));
    batch.set(
      ref,
      {
        ...match,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        source: "api-football",
      },
      { merge: true },
    );
    inBatch++;
    written++;

    if (inBatch >= batchSize) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }

  if (inBatch > 0) {
    await batch.commit();
  }

  console.log(`Upserted ${written} matches into tournaments/wc2026/matches.`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});

