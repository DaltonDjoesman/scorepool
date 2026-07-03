## ADDED Requirements

### Requirement: System ingests tournament match catalog server-side
The system MUST ingest the World Cup 2026 match schedule and updates from an external football API using a server-side job, and persist it as a read-optimized match catalog.

#### Scenario: Catalog is populated initially
- **WHEN** the ingestion job runs for the first time
- **THEN** the system creates match catalog documents for all available matches with IDs, teams, start time, stage, and status

### Requirement: Match catalog includes canonical identifiers
Each match catalog entry MUST include canonical identifiers for teams and stages that are stable across updates.

#### Scenario: Team IDs are stable
- **WHEN** the ingestion job updates a match with new fields (e.g., score/status)
- **THEN** the match keeps the same matchId and teamIds

### Requirement: Match time is stored in a timezone-agnostic format
The match start time MUST be stored in an absolute format (e.g., UTC timestamp) suitable for client-side localization.

#### Scenario: Client can localize match time
- **WHEN** a client reads a match start time from the catalog
- **THEN** it can render the time in the user’s local timezone without ambiguity

### Requirement: Catalog updates include final scores and status
The system SHALL update match status and final score fields when they become available.

#### Scenario: Match becomes finished
- **WHEN** the ingestion job detects a match has finished
- **THEN** the match catalog entry is updated with status=finished and the final scores

