## ADDED Requirements

### Requirement: Perfect score count is tracked per member per group
The system MUST track, per group member, the number of matches where the member was a winner by exact score.

#### Scenario: Perfect score increments on win
- **WHEN** a match finishes and a user is included in the winners list
- **THEN** the user perfectScoresCount for that group is incremented by 1

### Requirement: Ranking is ordered by perfect score count
The system SHALL present a ranking ordered by descending perfectScoresCount, with deterministic tie-breaking.

#### Scenario: Ranking shows highest first
- **WHEN** the ranking view is opened
- **THEN** members are listed from highest to lowest perfectScoresCount

#### Scenario: Ties are deterministic
- **WHEN** two members have the same perfectScoresCount
- **THEN** the system breaks ties deterministically (e.g., by display name or uid)

