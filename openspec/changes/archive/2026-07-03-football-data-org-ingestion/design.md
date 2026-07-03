## Context

Match catalog ingestion was implemented against **API-Football** (`v3.football.api-sports.io`) in PR #55: GitHub Actions workflow (every 5 min), standalone script `functions/scripts/ingest_wc2026.mjs`, and optional Cloud Function `ingestWc2026MatchCatalog`. The free API-Football plan rejects `season=2026`, so production ingest writes zero documents despite a green CI run.

**football-data.org v4** exposes FIFA World Cup as competition code `WC`. With the project token, `GET /v4/competitions/WC/matches?season=2026` returns 104 matches (June 11 – July 19, 2026). Free tier limits: 10 requests/minute, delayed scores (no live subscription). That is adequate for a betting pool app polling every 5 minutes.

The Flutter app reads `tournaments/wc2026/matches/{id}` with fields defined in `TournamentMatch` (`homeTeamId`, `teamIds`, `stage`, etc.). Group create/edit screens filter by hardcoded TLA codes (`BRA`, `POR`, …) and canonical stage IDs (`group`, `round_of_16`, …).

## Goals / Non-Goals

**Goals:**

- Replace API-Football with football-data.org in both ingest paths (GitHub Actions script + Cloud Function).
- Populate Firestore with ~104 WC2026 matches using the existing document schema.
- Preserve TLA-based team IDs so group filters keep working without UI changes.
- Normalize stages and statuses to app enums.
- Fail loudly on auth/API errors; log match count and `resultSet` for observability.

**Non-Goals:**

- Live score subscription (€12/mo football-data.org tier) — accept delayed updates on free tier.
- Dynamic team picker from API (keep hardcoded team list in Flutter for now).
- Removing the Cloud Function in favor of Actions-only (keep both aligned for now).
- Migrating or deleting stale API-Football documents (none exist in production).

## Decisions

### 1. Single endpoint, no pagination loop

**Decision:** One request to `/v4/competitions/WC/matches?season=2026` returns all matches (~104).

**Rationale:** WC fixture count fits in one response; avoids pagination complexity and stays within 10 req/min quota.

**Alternative:** Paginate if API adds paging — not needed today.

### 2. Shared mapping module

**Decision:** Extract pure mapping helpers (`mapStage`, `mapStatus`, `teamIdFromApi`, `toFirestoreMatch`) into `functions/src/footballDataOrg.ts` and import from both `index.ts` and the `.mjs` script (or duplicate minimal mapping in `.mjs` if ESM/CJS friction — prefer shared compiled output or a small `functions/src/mapping/` imported via dynamic import in script).

**Rationale:** One source of truth for stage/status/team mapping; reduces drift between Actions and Cloud Function.

### 3. Team ID = TLA, fallback numeric string

**Decision:** `homeTeamId = team.tla?.toUpperCase() || String(team.id)`.

**Rationale:** Group filter UI uses TLAs; football-data.org provides `tla` for national teams. Uppercase for consistency with hardcoded list.

### 4. Stage mapping table

| football-data.org `stage` | Firestore `stage` |
|---------------------------|-------------------|
| `GROUP_STAGE`             | `group`           |
| `LAST_32`                 | `round_of_32`     |
| `LAST_16`                 | `round_of_16`     |
| `QUARTER_FINALS`          | `quarterfinal`    |
| `SEMI_FINALS`             | `semifinal`       |
| `THIRD_PLACE`             | `third_place`     |
| `FINAL`                   | `final`           |
| (unknown)                 | lowercased raw value |

Include `group` field from API (e.g. `GROUP_A`) only in optional metadata if needed later — not in `stage` (filter uses canonical stage id).

### 5. Status mapping

| API status (subset) | App `status` |
|---------------------|--------------|
| `SCHEDULED`, `TIMED`, `POSTPONED`, `SUSPENDED`, `CANCELLED` | `scheduled` |
| `IN_PLAY`, `PAUSED`, `LIVE` | `live` |
| `FINISHED`, `AWARDED`, `POSTPONED` (if ended) | `finished` |

Use `score.fullTime.home/away` when present; null before kickoff.

### 6. Document ID = API match `id`

**Decision:** Firestore doc id = `String(match.id)` (football-data.org match id).

**Rationale:** Stable primary key from provider; different from API-Football fixture ids but no production data to migrate.

### 7. Secrets and env

**Decision:** Replace `API_FOOTBALL_KEY` with `FOOTBALL_DATA_TOKEN` in workflow and Cloud Functions secrets. Header: `X-Auth-Token`.

**Rationale:** Token already configured on GitHub; verified working locally.

### 8. Align script schema with Cloud Function

**Decision:** Update `ingest_wc2026.mjs` to write the **same flat schema** as `index.ts` (`homeTeamId`, `matchTimeUtc` ISO string, etc.), not the richer nested `toFirestoreMatch` shape currently in the script.

**Rationale:** Flutter `TournamentMatch.fromMap` expects the flat schema used by the Cloud Function.

### 9. Ingestion meta document

**Decision:** Continue updating `tournaments/wc2026/meta/ingestion` with `status`, `upserted`, `durationMs`, `provider: 'football-data-org'`, `resultSetCount`.

## Risks / Trade-offs

- **[Delayed scores on free tier]** → Acceptable for pool app; document that live status may lag during matches. Upgrade path: paid football-data.org live scores.
- **[TLA missing for some teams]** → Fallback to numeric id breaks filter match for those teams; log warning when TLA absent; expand hardcoded team list as needed.
- **[Stage enum drift]** → Unknown stages logged and stored lowercased; add mapping when API introduces new values.
- **[Rate limit 10/min]** → Single request per run; 5-min cron is safe.
- **[Exposed API token in chat/terminal]** → User should rotate token; never commit secrets.

## Migration Plan

1. Implement mapping + rewrite ingest script and Cloud Function.
2. Update GitHub workflow env to `FOOTBALL_DATA_TOKEN`.
3. Run workflow manually (`workflow_dispatch`) and verify Firestore has ~104 matches.
4. Confirm group create screen “included matches” count > 0 when selecting teams/stages.
5. Remove references to `API_FOOTBALL_KEY` from docs/README; optional: delete secret from GitHub repo settings.
6. Rollback: revert PR and restore `API_FOOTBALL_KEY` workflow (would return to 0 matches on free plan).

## Open Questions

- None blocking implementation. Optional follow-up: load team list from `GET /v4/competitions/WC/teams` instead of hardcoded Flutter list.
