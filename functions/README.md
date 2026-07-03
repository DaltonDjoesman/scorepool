# Cloud Functions & WC2026 ingest

Match catalog ingestion uses [football-data.org](https://www.football-data.org/) v4 (competition `WC`, season `2026`).

## Secrets

| Secret | Where | Purpose |
|--------|-------|---------|
| `FOOTBALL_DATA_TOKEN` | GitHub Actions + Cloud Functions | API token (`X-Auth-Token` header) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | GitHub Actions | Firestore write access for scheduled ingest |

Register at [football-data.org/client/register](https://www.football-data.org/client/register) and copy your API token.

> **Deprecated:** `API_FOOTBALL_KEY` (api-sports.io) is no longer used — the free plan blocks WC 2026.

## Scripts

```bash
cd functions
npm ci
npm run test:mapping    # smoke test stage/status mapping
npm run ingest:wc2026   # requires FOOTBALL_DATA_TOKEN + GOOGLE_APPLICATION_CREDENTIALS
```

## GitHub Actions

Workflow `.github/workflows/ingest-wc2026.yml` runs every 5 minutes and upserts into `tournaments/wc2026/matches/{matchId}`.

## Cloud Function

`ingestWc2026MatchCatalog` (scheduled every 6 hours) uses the same mapping module as the Actions script. Set `FOOTBALL_DATA_TOKEN` as a Functions secret when deploying to Blaze.
