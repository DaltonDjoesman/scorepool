import * as admin from 'firebase-admin';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { logger } from 'firebase-functions';

admin.initializeApp();

type ApiFootballFixtureResponse = {
  response?: Array<{
    fixture?: {
      id?: number;
      date?: string; // ISO
      status?: { short?: string };
    };
    league?: { round?: string };
    teams?: {
      home?: { id?: number; name?: string; code?: string; logo?: string };
      away?: { id?: number; name?: string; code?: string; logo?: string };
    };
    goals?: { home?: number | null; away?: number | null };
  }>;
  paging?: { current?: number; total?: number };
};

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function statusFromApiFootball(short: string | undefined): 'scheduled' | 'live' | 'finished' {
  const s = (short ?? '').toUpperCase();
  if (
    s === 'FT' ||
    s === 'AET' ||
    s === 'PEN' ||
    s === 'CANC' ||
    s === 'PST' ||
    s === 'ABD' ||
    s === 'AWD' ||
    s === 'WO'
  ) {
    return 'finished';
  }
  if (
    s === '1H' ||
    s === '2H' ||
    s === 'ET' ||
    s === 'BT' ||
    s === 'P' ||
    s === 'INT' ||
    s === 'HT' ||
    s === 'LIVE'
  ) {
    return 'live';
  }
  return 'scheduled';
}

async function fetchJsonWithRetry(url: string, apiKey: string): Promise<ApiFootballFixtureResponse> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    try {
      const res = await fetch(url, {
        headers: {
          'x-apisports-key': apiKey,
        },
      });
      if (!res.ok) {
        const body = await res.text().catch(() => '');
        throw new Error(`API-Football HTTP ${res.status}: ${body}`.slice(0, 4000));
      }
      return (await res.json()) as ApiFootballFixtureResponse;
    } catch (e) {
      lastError = e;
      const backoff = Math.min(10_000, 500 * 2 ** (attempt - 1));
      await sleep(backoff);
    }
  }
  throw lastError instanceof Error ? lastError : new Error('fetch failed');
}

const TOURNAMENT_ID = 'wc2026';
const WC2026_LEAGUE_ID = 1;
const WC2026_SEASON = 2026;
const API_FOOTBALL_BASE_URL = 'https://v3.football.api-sports.io';

export const ingestWc2026MatchCatalog = onSchedule('every 6 hours', async () => {
  const db = admin.firestore();

  const apiKey = process.env.API_FOOTBALL_KEY;
  if (!apiKey) {
    throw new Error('Missing API_FOOTBALL_KEY in environment (use Functions secrets).');
  }

  const metaRef = db.doc(`tournaments/${TOURNAMENT_ID}/meta/ingestion`);
  const startedAt = Date.now();

  await metaRef.set(
    {
      lastRunAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'running',
      leagueId: WC2026_LEAGUE_ID,
      season: WC2026_SEASON,
    },
    { merge: true },
  );

  let currentPage = 1;
  let totalPages = 1;
  let upserted = 0;

  while (currentPage <= totalPages) {
    const url =
      `${API_FOOTBALL_BASE_URL}/fixtures` +
      `?league=${WC2026_LEAGUE_ID}` +
      `&season=${WC2026_SEASON}` +
      `&timezone=UTC` +
      `&page=${currentPage}`;

    const payload = await fetchJsonWithRetry(url, apiKey);
    totalPages = payload.paging?.total ?? totalPages;

    const fixtures = payload.response ?? [];

    // Minimal quota usage: batch writes and a small delay between pages.
    const batch = db.batch();
    let batchOps = 0;

    for (const item of fixtures) {
      const fixtureId = item.fixture?.id;
      if (!fixtureId) continue;

      const matchId = String(fixtureId);
      const homeId = item.teams?.home?.code ?? String(item.teams?.home?.id ?? '');
      const awayId = item.teams?.away?.code ?? String(item.teams?.away?.id ?? '');

      const matchTimeUtc = item.fixture?.date
        ? new Date(item.fixture.date).toISOString()
        : new Date(0).toISOString();

      const stage = item.league?.round ?? '';
      const status = statusFromApiFootball(item.fixture?.status?.short);

      const homeScore = item.goals?.home ?? null;
      const awayScore = item.goals?.away ?? null;

      const docRef = db.doc(`tournaments/${TOURNAMENT_ID}/matches/${matchId}`);
      batch.set(
        docRef,
        {
          homeTeamId: homeId,
          awayTeamId: awayId,
          teamIds: [homeId, awayId].filter(Boolean),
          stage,
          matchTimeUtc,
          status,
          homeScore,
          awayScore,
          homeFlag: item.teams?.home?.logo ?? null,
          awayFlag: item.teams?.away?.logo ?? null,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      batchOps += 1;

      if (batchOps >= 450) {
        // Keep under 500 writes per batch.
        break;
      }
    }

    if (batchOps > 0) {
      await batch.commit();
      upserted += batchOps;
    }

    logger.info('Ingested fixtures page', { currentPage, totalPages, batchOps });
    currentPage += 1;
    await sleep(350);
  }

  await metaRef.set(
    {
      status: 'ok',
      upserted,
      durationMs: Date.now() - startedAt,
    },
    { merge: true },
  );
});

