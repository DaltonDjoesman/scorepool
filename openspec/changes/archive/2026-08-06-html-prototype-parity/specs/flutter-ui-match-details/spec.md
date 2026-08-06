## ADDED Requirements

### Requirement: Estimated pot on pre-match hero
The match hero SHALL display estimated pot (`entryFee × in-pot participants + carryover`) for scheduled and live matches.

#### Scenario: Display estimated pot on hero
- **WHEN** the user views the match details screen for a scheduled or live match
- **THEN** the match hero SHALL display the calculated estimated pot value

### Requirement: Participant list on scheduled and live details
The match details screen SHALL show a searchable participant list with in-pot / out-of-pot status for scheduled and live matches.

#### Scenario: Search participant list
- **WHEN** the user searches in the participant list on a scheduled or live match details screen
- **THEN** the list SHALL filter participants by their name matching the search query

### Requirement: Group predictions show opt-out and outcome
After lock, the group predictions list SHALL include all members, show "Fora do Pote" for opted-out users, and show win/loss on finished matches.

#### Scenario: Member list after lock
- **WHEN** the user views group predictions after prediction lock
- **THEN** the list SHALL show all group members, marking opted-out users as "Fora do Pote"

### Requirement: Payment ledger only on finished matches with winners
The payment ledger section SHALL appear only when the match is finished and has at least one winner.

#### Scenario: Ledger visibility
- **WHEN** the match is finished and has at least one winner
- **THEN** the payment ledger section SHALL be displayed
