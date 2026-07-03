## ADDED Requirements

### Requirement: Default participation in pot is enabled
For each included group match, all group members MUST default to isInPot=true unless they explicitly opt out before lock.

#### Scenario: New match initializes participants
- **WHEN** a match becomes included for a group
- **THEN** the system initializes round participation for members with isInPot=true

### Requirement: User can opt out before lock time
The system SHALL allow a user to opt out of the pot for a specific match until lock time, defined as matchTime minus predictionLockMinutes.

#### Scenario: Opt-out succeeds before lock
- **WHEN** current time is earlier than (matchTime - predictionLockMinutes) and a user toggles opt-out
- **THEN** the user round participation is updated to isInPot=false

#### Scenario: Opt-out rejected after lock
- **WHEN** current time is at or later than (matchTime - predictionLockMinutes)
- **THEN** attempts to opt out are rejected

### Requirement: Opt-out only affects the selected match
Opt-out MUST apply only to the specific match and MUST NOT affect participation in other matches.

#### Scenario: Opt-out does not propagate
- **WHEN** a user opts out of match A
- **THEN** the user remains isInPot=true for match B unless they opt out separately

