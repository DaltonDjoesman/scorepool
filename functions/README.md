# Cloud Functions & WC2026 ingest

Match catalog ingestion uses [football-data.org](https://www.football-data.org/) v4 (competition `WC`, season `2026`).

## Runtime

- **Node.js 20** (`engines.node` in `package.json`) — matches the GitHub Actions ingest workflow.
- On the **Spark** Firebase plan, the **live** ingest/closeout path is GitHub Actions (Admin SDK scripts), not deployed Cloud Functions.
- TypeScript under `src/` is the same business logic, ready to deploy on Blaze when Functions are enabled.

## Secrets

| Secret | Where | Purpose |
|--------|-------|---------|
| `FOOTBALL_DATA_TOKEN` | GitHub Actions + Cloud Functions | API token (`X-Auth-Token` header) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | GitHub Actions | Firestore write access for scheduled ingest |

For local scripts, set `GOOGLE_APPLICATION_CREDENTIALS` to a service-account JSON **outside** this repository (see [`docs/security.md`](../docs/security.md)).

Register at [football-data.org/client/register](https://www.football-data.org/client/register) and copy your API token.

> **Deprecated:** `API_FOOTBALL_KEY` (api-sports.io) is no longer used — the free plan blocks WC 2026.

## Scripts

```bash
cd functions
npm ci
npm run test:mapping    # smoke test stage/status mapping
npm run ingest:wc2026   # requires FOOTBALL_DATA_TOKEN + GOOGLE_APPLICATION_CREDENTIALS
```

## GitHub Actions (live path)

Workflow `.github/workflows/ingest-wc2026.yml` runs on a schedule and upserts into `tournaments/wc2026/matches/{matchId}`, then runs closeout backfill. This is the production dispatcher on Spark.

## Cloud Functions (deployable path)

`ingestWc2026MatchCatalog` and related modules use the same mapping/closeout code as the Actions scripts. Set `FOOTBALL_DATA_TOKEN` as a Functions secret when deploying to Blaze.
