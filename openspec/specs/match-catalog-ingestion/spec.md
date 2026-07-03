## Purpose

Define how the app ingests and maintains the global World Cup 2026 match catalog as the single source of truth for schedules, scores, and match metadata consumed by groups and predictions.
## Requirements
### Requirement: System ingests tournament match catalog server-side
The system MUST ingest the World Cup 2026 match schedule and updates from **football-data.org v4** (competition code `WC`, season `2026`) using a server-side job, and persist it as a read-optimized match catalog.

#### Scenario: Catalog is populated initially
- **WHEN** the ingestion job runs for the first time with a valid football-data.org token
- **THEN** the system creates match catalog documents for all available matches (expected ~104 for WC2026) with IDs, teams, start time, stage, and status

### Requirement: Match catalog includes canonical identifiers
Each match catalog entry MUST include canonical identifiers for teams and stages that are stable across updates. Team identifiers MUST prefer FIFA three-letter codes (`tla`) when provided by the API; otherwise numeric team IDs as strings.

#### Scenario: Team IDs are stable
- **WHEN** the ingestion job updates a match with new fields (e.g., score/status)
- **THEN** the match keeps the same matchId and teamIds

#### Scenario: Team TLA aligns with group filter
- **WHEN** a user filters a group by team code `BRA`
- **THEN** ingested matches involving Brazil include `BRA` in `teamIds`

### Requirement: Match time is stored in a timezone-agnostic format
The match start time MUST be stored in an absolute format (UTC ISO-8601 string from the API `utcDate` field) suitable for client-side localization.

#### Scenario: Client can localize match time
- **WHEN** a client reads a match start time from the catalog
- **THEN** it can render the time in the user’s local timezone without ambiguity

### Requirement: Catalog updates include final scores and status
The system SHALL update match status and final score fields when they become available from football-data.org (free tier may provide delayed updates).

#### Scenario: Match becomes finished
- **WHEN** the ingestion job detects a match has status `FINISHED` (or equivalent)
- **THEN** the match catalog entry is updated with status=finished and the final scores from `score.fullTime`

