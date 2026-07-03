import * as admin from 'firebase-admin';

/** Keep in sync with lib/src/utils/team_flag_emoji.dart */
export const TEAM_ID_TO_ISO2: Record<string, string> = {
  BRA: 'BR',
  ARG: 'AR',
  URU: 'UY',
  USA: 'US',
  MEX: 'MX',
  FRA: 'FR',
  ESP: 'ES',
  POR: 'PT',
  ENG: 'GB',
  GER: 'DE',
  ITA: 'IT',
  NED: 'NL',
  COL: 'CO',
  CHI: 'CL',
  ECU: 'EC',
  PER: 'PE',
  PAR: 'PY',
  BOL: 'BO',
  VEN: 'VE',
  CRC: 'CR',
  PAN: 'PA',
  JAM: 'JM',
  CAN: 'CA',
  JPN: 'JP',
  KOR: 'KR',
  AUS: 'AU',
  NZL: 'NZ',
  MAR: 'MA',
  SEN: 'SN',
  NGA: 'NG',
  GHA: 'GH',
  CMR: 'CM',
  CIV: 'CI',
  TUN: 'TN',
  ALG: 'DZ',
  EGY: 'EG',
  SAU: 'SA',
  QAT: 'QA',
  IRN: 'IR',
  CRO: 'HR',
  SRB: 'RS',
  SUI: 'CH',
  BEL: 'BE',
  POL: 'PL',
  DEN: 'DK',
  SWE: 'SE',
  NOR: 'NO',
  AUT: 'AT',
  CZE: 'CZ',
  UKR: 'UA',
  TUR: 'TR',
  WAL: 'GB',
  SCO: 'GB',
  BIH: 'BA',
  COD: 'CD',
  CPV: 'CV',
  CUW: 'CW',
  HAI: 'HT',
  IRQ: 'IQ',
  JOR: 'JO',
  KSA: 'SA',
  RSA: 'ZA',
  UZB: 'UZ',
};

/** flagcdn.com codes for nations that share a generic ISO2 (UK home nations). */
export const TEAM_FLAGCDN_CODE: Record<string, string> = {
  ENG: 'gb-eng',
  WAL: 'gb-wls',
  SCO: 'gb-sct',
};

export const FLAGCDN_WIDTH = 80;

export function flagCdnCrestUrl(flagCode: string, width = FLAGCDN_WIDTH): string {
  return `https://flagcdn.com/w${width}/${flagCode.toLowerCase()}.png`;
}

export function iso2ForTeamId(teamId: string): string | null {
  const normalized = teamId.trim().toUpperCase();
  return TEAM_ID_TO_ISO2[normalized] ?? null;
}

export function resolveCrestUrl(teamId: string): string | null {
  const normalized = teamId.trim().toUpperCase();
  if (!normalized || normalized.startsWith('TBD_')) return null;

  const flagCode = TEAM_FLAGCDN_CODE[normalized] ?? iso2ForTeamId(normalized);
  if (!flagCode) return null;

  return flagCdnCrestUrl(flagCode);
}

export function isSvgCrestUrl(url: string): boolean {
  const path = (() => {
    try {
      return new URL(url).pathname.toLowerCase();
    } catch {
      return url.toLowerCase();
    }
  })();
  return path.endsWith('.svg');
}

/** Flutter cannot render SVG; use flagcdn PNG when the API sends SVG. */
export function displayCrestUrl(teamId: string, apiCrest?: string | null): string | null {
  const api = apiCrest?.trim();
  if (api && !isSvgCrestUrl(api)) return api;
  return resolveCrestUrl(teamId);
}

function isEmptyCrest(value: unknown): boolean {
  return value == null || (typeof value === 'string' && value.trim() === '');
}

export type EnrichCrestsResult = {
  teamsUpdated: number;
  teamsSkipped: number;
  matchesUpdated: number;
  matchesSkipped: number;
};

export async function enrichTournamentCrests(
  db: admin.firestore.Firestore,
  tournamentId: string,
): Promise<EnrichCrestsResult> {
  const result: EnrichCrestsResult = {
    teamsUpdated: 0,
    teamsSkipped: 0,
    matchesUpdated: 0,
    matchesSkipped: 0,
  };

  const teamsCol = db.collection('tournaments').doc(tournamentId).collection('teams');
  const matchesCol = db.collection('tournaments').doc(tournamentId).collection('matches');
  const matchesSnap = await matchesCol.get();

  const crestByTeamId = new Map<string, string>();

  for (const doc of matchesSnap.docs) {
    const data = doc.data();
    const homeTeamId = String(data.homeTeamId ?? '');
    const awayTeamId = String(data.awayTeamId ?? '');
    const homeFlag = data.homeFlag;
    const awayFlag = data.awayFlag;

    if (homeTeamId && !homeTeamId.startsWith('TBD_') && !isEmptyCrest(homeFlag)) {
      crestByTeamId.set(homeTeamId, String(homeFlag));
    }
    if (awayTeamId && !awayTeamId.startsWith('TBD_') && !isEmptyCrest(awayFlag)) {
      crestByTeamId.set(awayTeamId, String(awayFlag));
    }
  }

  const teamsSnap = await teamsCol.get();
  for (const doc of teamsSnap.docs) {
    const crest = doc.data().crest;
    if (!isEmptyCrest(crest)) {
      crestByTeamId.set(doc.id, String(crest));
    }
  }

  let batch = db.batch();
  let batchOps = 0;

  const flushBatch = async () => {
    if (batchOps === 0) return;
    await batch.commit();
    batch = db.batch();
    batchOps = 0;
  };

  const knownTeamIds = new Set<string>();
  for (const doc of teamsSnap.docs) knownTeamIds.add(doc.id);
  for (const doc of matchesSnap.docs) {
    const data = doc.data();
    for (const teamId of [String(data.homeTeamId ?? ''), String(data.awayTeamId ?? '')]) {
      if (!teamId || teamId.startsWith('TBD_')) continue;
      knownTeamIds.add(teamId);
    }
  }

  for (const teamId of knownTeamIds) {
    const teamRef = teamsCol.doc(teamId);
    const existing = teamsSnap.docs.find((d) => d.id === teamId)?.data();
    const existingCrest = existing?.crest ?? crestByTeamId.get(teamId);
    const displayUrl = displayCrestUrl(teamId, existingCrest as string | undefined);

    if (!displayUrl) {
      result.teamsSkipped += 1;
      continue;
    }

    if (!isEmptyCrest(existingCrest) && String(existingCrest) === displayUrl) {
      crestByTeamId.set(teamId, displayUrl);
      result.teamsSkipped += 1;
      continue;
    }

    batch.set(
      teamRef,
      {
        name: (existing?.name as string | undefined) ?? teamId,
        crest: displayUrl,
        crestSource: displayUrl.includes('flagcdn.com') ? 'flagcdn' : 'football-data-org',
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    crestByTeamId.set(teamId, displayUrl);
    result.teamsUpdated += 1;
    batchOps += 1;

    if (batchOps >= 450) await flushBatch();
  }

  await flushBatch();

  for (const doc of matchesSnap.docs) {
    const data = doc.data();
    const patch: Record<string, string> = {};

    const homeTeamId = String(data.homeTeamId ?? '');
    const homeDisplay = !homeTeamId.startsWith('TBD_')
      ? displayCrestUrl(homeTeamId, data.homeFlag as string | undefined)
      : null;
    if (homeDisplay && homeDisplay !== data.homeFlag) {
      patch.homeFlag = homeDisplay;
    }

    const awayTeamId = String(data.awayTeamId ?? '');
    const awayDisplay = !awayTeamId.startsWith('TBD_')
      ? displayCrestUrl(awayTeamId, data.awayFlag as string | undefined)
      : null;
    if (awayDisplay && awayDisplay !== data.awayFlag) {
      patch.awayFlag = awayDisplay;
    }

    if (Object.keys(patch).length === 0) {
      result.matchesSkipped += 1;
      continue;
    }

    batch.set(
      doc.ref,
      {
        ...patch,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    result.matchesUpdated += 1;
    batchOps += 1;

    if (batchOps >= 450) await flushBatch();
  }

  await flushBatch();

  return result;
}
