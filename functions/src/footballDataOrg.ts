export const FOOTBALL_DATA_API_BASE = 'https://api.football-data.org/v4';
export const WC2026_MATCHES_URL = `${FOOTBALL_DATA_API_BASE}/competitions/WC/matches?season=2026`;
export const TOURNAMENT_ID = 'wc2026';
export const WC2026_SEASON = 2026;
export const MATCH_SOURCE = 'football-data-org';

export type AppMatchStatus = 'scheduled' | 'live' | 'finished';

export type FootballDataTeam = {
  id?: number;
  name?: string;
  shortName?: string;
  tla?: string;
  crest?: string;
};

export type FootballDataMatch = {
  id?: number;
  utcDate?: string;
  status?: string;
  stage?: string;
  group?: string | null;
  homeTeam?: FootballDataTeam;
  awayTeam?: FootballDataTeam;
  score?: {
    fullTime?: { home?: number | null; away?: number | null };
  };
};

export type FootballDataResultSet = {
  count?: number;
  first?: string;
  last?: string;
  played?: number;
};

export type FootballDataMatchesResponse = {
  resultSet?: FootballDataResultSet;
  matches?: FootballDataMatch[];
};

export type FirestoreMatchDoc = {
  homeTeamId: string;
  awayTeamId: string;
  teamIds: string[];
  stage: string;
  matchTimeUtc: string;
  status: AppMatchStatus;
  homeScore: number | null;
  awayScore: number | null;
  homeFlag: string | null;
  awayFlag: string | null;
  source: typeof MATCH_SOURCE;
};

const STAGE_MAP: Record<string, string> = {
  GROUP_STAGE: 'group',
  LAST_32: 'round_of_32',
  LAST_16: 'round_of_16',
  QUARTER_FINALS: 'quarterfinal',
  SEMI_FINALS: 'semifinal',
  THIRD_PLACE: 'third_place',
  FINAL: 'final',
};

const FINISHED_STATUSES = new Set(['FINISHED', 'AWARDED']);
const LIVE_STATUSES = new Set(['IN_PLAY', 'PAUSED', 'LIVE']);
const SCHEDULED_STATUSES = new Set([
  'SCHEDULED',
  'TIMED',
  'POSTPONED',
  'SUSPENDED',
  'CANCELLED',
]);

export function mapStage(stage: string | undefined): string {
  if (!stage) return '';
  return STAGE_MAP[stage] ?? stage.toLowerCase();
}

export function mapStatus(status: string | undefined): AppMatchStatus {
  const normalized = (status ?? '').toUpperCase();
  if (FINISHED_STATUSES.has(normalized)) return 'finished';
  if (LIVE_STATUSES.has(normalized)) return 'live';
  if (SCHEDULED_STATUSES.has(normalized)) return 'scheduled';
  return 'scheduled';
}

export function teamIdFromApi(team: FootballDataTeam | undefined): string {
  const tla = team?.tla?.trim();
  if (tla && tla.toUpperCase() !== 'TBD') return tla.toUpperCase();
  if (team?.id != null) return String(team.id);

  const name = team?.shortName?.trim() || team?.name?.trim();
  if (name) {
    return name
      .normalize('NFD')
      .replace(/[\u0300-\u036f]/g, '')
      .toUpperCase()
      .replace(/[^A-Z0-9]+/g, '_')
      .replace(/^_|_$/g, '')
      .slice(0, 40);
  }

  return '';
}

/** Stable placeholder when knockout slots have no team assigned yet. */
export function placeholderTeamId(matchId: number, slot: 'home' | 'away'): string {
  return `TBD_${matchId}_${slot === 'home' ? 'H' : 'A'}`;
}

export type FirestoreTeamDoc = {
  name: string;
  crest?: string;
  source: typeof MATCH_SOURCE;
};

export function teamDocFromApi(
  team: FootballDataTeam | undefined,
  teamId: string,
): FirestoreTeamDoc | null {
  if (!teamId || teamId.startsWith('TBD_')) return null;

  const name = team?.shortName?.trim() || team?.name?.trim() || teamId;
  const crest = team?.crest?.trim();
  return {
    name,
    ...(crest ? { crest } : {}),
    source: MATCH_SOURCE,
  };
}

export function collectTeamsFromMatch(
  match: FootballDataMatch,
  doc: FirestoreMatchDoc,
): Array<{ id: string; doc: FirestoreTeamDoc }> {
  const teams: Array<{ id: string; doc: FirestoreTeamDoc }> = [];
  const home = teamDocFromApi(match.homeTeam, doc.homeTeamId);
  if (home) teams.push({ id: doc.homeTeamId, doc: home });
  const away = teamDocFromApi(match.awayTeam, doc.awayTeamId);
  if (away) teams.push({ id: doc.awayTeamId, doc: away });
  return teams;
}

export function toFirestoreMatchDoc(match: FootballDataMatch): FirestoreMatchDoc | null {
  if (match.id == null) return null;

  const homeTeamId =
    teamIdFromApi(match.homeTeam) || placeholderTeamId(match.id, 'home');
  const awayTeamId =
    teamIdFromApi(match.awayTeam) || placeholderTeamId(match.id, 'away');

  const matchTimeUtc = match.utcDate
    ? new Date(match.utcDate).toISOString()
    : new Date(0).toISOString();

  return {
    homeTeamId,
    awayTeamId,
    teamIds: [homeTeamId, awayTeamId],
    stage: mapStage(match.stage),
    matchTimeUtc,
    status: mapStatus(match.status),
    homeScore: match.score?.fullTime?.home ?? null,
    awayScore: match.score?.fullTime?.away ?? null,
    homeFlag: match.homeTeam?.crest ?? null,
    awayFlag: match.awayTeam?.crest ?? null,
    source: MATCH_SOURCE,
  };
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function fetchJsonWithRetry(
  url: string,
  token: string,
): Promise<FootballDataMatchesResponse> {
  let lastError: unknown;
  for (let attempt = 1; attempt <= 5; attempt += 1) {
    try {
      const res = await fetch(url, {
        headers: {
          'X-Auth-Token': token,
          Accept: 'application/json',
        },
      });

      const text = await res.text();
      let json: FootballDataMatchesResponse;
      try {
        json = JSON.parse(text) as FootballDataMatchesResponse;
      } catch {
        throw new Error(`football-data.org returned non-JSON (status ${res.status}): ${text.slice(0, 500)}`);
      }

      if (!res.ok) {
        throw new Error(`football-data.org HTTP ${res.status}: ${text.slice(0, 2000)}`);
      }

      return json;
    } catch (error) {
      lastError = error;
      const backoff = Math.min(10_000, 500 * 2 ** (attempt - 1));
      await sleep(backoff);
    }
  }

  throw lastError instanceof Error ? lastError : new Error('football-data.org fetch failed');
}

export function validateMatchesResponse(payload: FootballDataMatchesResponse): FootballDataMatch[] {
  const resultSetCount = payload.resultSet?.count ?? 0;
  const matches = Array.isArray(payload.matches) ? payload.matches : [];

  if (resultSetCount > 0 && matches.length === 0) {
    throw new Error(
      `football-data.org resultSet.count=${resultSetCount} but matches array is empty`,
    );
  }

  return matches;
}

export async function fetchWc2026Matches(token: string): Promise<{
  matches: FootballDataMatch[];
  resultSet: FootballDataResultSet;
}> {
  const payload = await fetchJsonWithRetry(WC2026_MATCHES_URL, token);
  const matches = validateMatchesResponse(payload);
  return {
    matches,
    resultSet: payload.resultSet ?? {},
  };
}
