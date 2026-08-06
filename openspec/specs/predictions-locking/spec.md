# predictions-locking Specification

## Purpose
Defines optional predictions, lock-time rules for create/update, and uniqueness per user/match/group.

## Requirements


### Requirement: Prediction is optional
The system SHALL allow a participant to join the pot for a match without submitting any prediction.

#### Scenario: User leaves prediction empty
- **WHEN** a user is inPot=true for a match and does not submit predicted scores
- **THEN** the user is still treated as a financial participant for that match

### Requirement: Prediction can be created or updated before lock time
The system MUST allow users to create or update their prediction only until lock time, defined as matchTime minus predictionLockMinutes.

#### Scenario: Update allowed before lock
- **WHEN** current time is earlier than (matchTime - predictionLockMinutes)
- **THEN** a user can create or update predictedHomeScore and predictedAwayScore

#### Scenario: Update rejected after lock
- **WHEN** current time is at or later than (matchTime - predictionLockMinutes)
- **THEN** attempts to create or update the prediction are rejected

### Requirement: Prediction record is per user per match per group
The system MUST store predictions as a unique record per (groupId, uid, matchId).

#### Scenario: Duplicate prediction cannot exist
- **WHEN** a user submits a second prediction for the same match and group
- **THEN** the system overwrites the existing record (update) rather than creating a second record

