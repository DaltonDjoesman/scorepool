## 1. Shared football-data.org mapping

- [x] 1.1 Add `functions/src/footballDataOrg.ts` with types for football-data.org match response, `mapStage`, `mapStatus`, `teamIdFromApi`, and `toFirestoreMatchDoc` producing the flat schema used by `TournamentMatch`
- [x] 1.2 Add unit-style tests or a small Node script to validate stage/status mapping against known API enum values (optional smoke test in CI)

## 2. Rewrite GitHub Actions ingest script

- [x] 2.1 Update `functions/scripts/ingest_wc2026.mjs` to call `GET https://api.football-data.org/v4/competitions/WC/matches?season=2026` with `X-Auth-Token: FOOTBALL_DATA_TOKEN`
- [x] 2.2 Replace nested `toFirestoreMatch` with flat schema output aligned with Cloud Function (`homeTeamId`, `awayTeamId`, `teamIds`, `stage`, `matchTimeUtc`, `status`, scores, flags, `source: football-data-org`)
- [x] 2.3 Fail on HTTP errors; fail when `resultSet.count > 0` but `matches.length === 0`; log `resultSet` and upsert count
- [x] 2.4 Update `functions/package.json` ingest script if env var name changes (`FOOTBALL_DATA_TOKEN`)

## 3. Rewrite Cloud Function scheduled ingest

- [x] 3.1 Refactor `functions/src/index.ts` to use football-data.org endpoint and shared mapping module
- [x] 3.2 Replace `API_FOOTBALL_KEY` with `FOOTBALL_DATA_TOKEN` (Functions secret / env)
- [x] 3.3 Update ingestion meta doc with `provider: football-data-org` and `resultSetCount`
- [x] 3.4 Remove API-Football-specific types, pagination loop, and headers

## 4. CI and secrets

- [x] 4.1 Update `.github/workflows/ingest-wc2026.yml` to pass `FOOTBALL_DATA_TOKEN` instead of `API_FOOTBALL_KEY`
- [x] 4.2 Document secret setup in README or functions/README (`FOOTBALL_DATA_TOKEN` from football-data.org)

## 5. Verification

- [x] 5.1 Run ingest locally with `FOOTBALL_DATA_TOKEN` and confirm ~104 documents in `tournaments/wc2026/matches`
- [x] 5.2 Trigger GitHub Actions workflow manually and confirm successful upsert in Firestore
- [x] 5.3 Smoke-test group create screen: selecting `BRA` + `group` stage returns included match count > 0
- [x] 5.4 Verify sample match fields: TLA team ids, normalized stage, ISO `matchTimeUtc`, crest URLs in `homeFlag`/`awayFlag`

## 6. Cleanup

- [x] 6.1 Remove remaining API-Football references from code comments and OpenSpec task 6.x notes where applicable
- [x] 6.2 Note in PR/changelog that `API_FOOTBALL_KEY` GitHub secret is deprecated
