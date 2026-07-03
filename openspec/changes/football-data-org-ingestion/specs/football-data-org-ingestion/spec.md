## ADDED Requirements

### Requirement: Ingestion calls football-data.org WC competition endpoint
The system MUST fetch World Cup 2026 matches from football-data.org v4 using `GET /v4/competitions/WC/matches?season=2026` with header `X-Auth-Token`.

#### Scenario: Successful fetch with token
- **WHEN** the ingestion job runs with a valid `FOOTBALL_DATA_TOKEN`
- **THEN** the job receives a JSON payload containing a `matches` array for season 2026

#### Scenario: Missing token fails fast
- **WHEN** the ingestion job runs without `FOOTBALL_DATA_TOKEN`
- **THEN** the job exits with an error and does not write to Firestore

### Requirement: API errors are surfaced explicitly
The ingestion job MUST NOT treat HTTP errors, API error bodies, or unexpected empty results as a silent no-op when the competition should have fixtures.

#### Scenario: HTTP error from API
- **WHEN** football-data.org returns a non-2xx status
- **THEN** the job logs the status and response body (truncated) and fails the run

#### Scenario: Zero matches when resultSet indicates fixtures exist
- **WHEN** the API `resultSet.count` is greater than zero but the parsed `matches` array is empty
- **THEN** the job fails with an explicit error describing the mismatch

### Requirement: football-data.org fields are mapped to Firestore match schema
Each match from the API MUST be transformed into the existing Firestore document shape used by the Flutter app (`homeTeamId`, `awayTeamId`, `teamIds`, `stage`, `matchTimeUtc`, `status`, `homeScore`, `awayScore`, `homeFlag`, `awayFlag`).

#### Scenario: Team identifiers use TLA when present
- **WHEN** a match team includes a non-empty `tla` field (e.g. `BRA`)
- **THEN** the ingested document uses that TLA as `homeTeamId` or `awayTeamId` and includes it in `teamIds`

#### Scenario: Team identifiers fall back to numeric id
- **WHEN** a match team has no `tla`
- **THEN** the ingested document uses the string form of the numeric team `id`

#### Scenario: Stage is normalized to app canonical values
- **WHEN** the API returns `stage` values such as `GROUP_STAGE`, `LAST_32`, `LAST_16`, `QUARTER_FINALS`, `SEMI_FINALS`, `THIRD_PLACE`, or `FINAL`
- **THEN** the ingested document `stage` is one of `group`, `round_of_32`, `round_of_16`, `quarterfinal`, `semifinal`, `third_place`, or `final`

#### Scenario: Status is normalized to app enum
- **WHEN** the API match status is `SCHEDULED`, `TIMED`, `IN_PLAY`, `PAUSED`, or `FINISHED` (and related values)
- **THEN** the ingested document `status` is `scheduled`, `live`, or `finished` respectively

#### Scenario: Scores and crests are persisted
- **WHEN** the API provides `score.fullTime` and team `crest` URLs
- **THEN** the ingested document includes `homeScore`, `awayScore`, `homeFlag`, and `awayFlag`

### Requirement: Ingestion metadata records football-data.org as source
Each upserted match document and the ingestion meta document MUST record `source: football-data-org` and the provider API version/path used.

#### Scenario: Match document source field
- **WHEN** a match is written to `tournaments/wc2026/matches/{matchId}`
- **THEN** the document includes `source` set to `football-data-org`
