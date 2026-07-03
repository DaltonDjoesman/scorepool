## Why

The current match catalog ingestion uses API-Football (api-sports.io), but the free plan blocks the 2026 World Cup season. GitHub Actions runs successfully yet upserts **0 matches**, leaving Firestore empty for WC2026. football-data.org’s free tier includes FIFA World Cup (WC) competition data and returns **104 matches** for season 2026 with the project token — sufficient for a pool app that polls every 5 minutes.

## What Changes

- Replace API-Football as the external data source with **football-data.org v4** (`GET /v4/competitions/WC/matches?season=2026`).
- Rewrite the ingest script (`functions/scripts/ingest_wc2026.mjs`) and scheduled Cloud Function (`functions/src/index.ts`) to call football-data.org and map its response to the existing Firestore match schema.
- Switch GitHub Actions secret from `API_FOOTBALL_KEY` to `FOOTBALL_DATA_TOKEN` (header `X-Auth-Token`).
- Map football-data.org **stage** enums (`GROUP_STAGE`, `LAST_16`, …) to the app’s canonical stage IDs (`group`, `round_of_16`, …).
- Use team **TLA** (3-letter code, e.g. `BRA`) as `homeTeamId` / `awayTeamId` when available, preserving compatibility with the group filter UI; fall back to numeric string IDs when TLA is missing.
- Map football-data.org **status** values to app statuses (`scheduled`, `live`, `finished`); accept free-tier delayed scores (no live subscription required for MVP).
- Fail loudly on API errors or empty responses when the API reports matches — no silent “0 fixtures” success.
- Remove API-Football-specific env vars, headers, and documentation references.
- Set Firestore `source` field to `football-data-org` on ingested documents.

## Capabilities

### New Capabilities

- `football-data-org-ingestion`: Server-side ingestion from football-data.org v4 WC competition API, including field mapping, error handling, and CI/Functions configuration.

### Modified Capabilities

- `match-catalog-ingestion`: External provider changes from API-Football to football-data.org; canonical team IDs prefer FIFA TLA codes; stage values normalized to app enum; ingestion metadata reflects new provider.

## Impact

- **Backend**: `functions/scripts/ingest_wc2026.mjs`, `functions/src/index.ts`, `functions/package.json` (if scripts change).
- **CI**: `.github/workflows/ingest-wc2026.yml` — secret rename and env wiring.
- **Secrets**: GitHub `FOOTBALL_DATA_TOKEN` (already configured); deprecate `API_FOOTBALL_KEY`.
- **Firestore**: `tournaments/wc2026/matches/*` documents populated with new `source`; existing empty catalog gets first real data on next run.
- **Flutter app**: No breaking model changes expected if TLA mapping succeeds; group filter hardcoded team list should align with ingested `teamIds`.
- **Docs / OpenSpec**: Update references in `worldcup-bet-tracker-spec` design/proposal where they mention API-Football (informational only).
