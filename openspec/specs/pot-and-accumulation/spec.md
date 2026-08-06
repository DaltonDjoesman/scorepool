# pot-and-accumulation Specification

## Purpose
Defines winner determination, pot calculation, equal split among winners, and carryover when there are no winners.

## Requirements


### Requirement: Winners are exact score matches
For a group match, a user SHALL be a winner only if they submitted a prediction and both predicted scores exactly match the final match scores.

#### Scenario: Exact score wins
- **WHEN** a match finishes with score 2x1 and a user predicted 2x1
- **THEN** the user is included in the winners list for that group match

#### Scenario: Correct outcome but wrong score does not win
- **WHEN** a match finishes 2x1 and a user predicted 1x0
- **THEN** the user is not a winner

### Requirement: Pot amount is based on in-pot participants
The base pot for a group match MUST be entryFee multiplied by the number of participants with isInPot=true for that match.

#### Scenario: User without prediction still contributes
- **WHEN** a user is isInPot=true but has no prediction
- **THEN** they are counted in the base pot calculation

### Requirement: Pot is divided equally among winners
If there is at least one winner, the total pot SHALL be divided equally among all winners.

#### Scenario: Two winners split pot equally
- **WHEN** totalPot is 100 and there are 2 winners
- **THEN** each winner receives 50 (subject to rounding rules)

### Requirement: Full pot accumulates when there are no winners
If a group match finishes with zero winners, the total pot MUST fully accumulate to the next eligible group match.

#### Scenario: No winners triggers carryover
- **WHEN** a match finishes and winners list is empty
- **THEN** the match totalPot is added to the group carryOverPot

### Requirement: Carryover is applied to next eligible group match
The system MUST apply the group carryOverPot to the next included match for the group (by matchTime) and then reset carryOverPot to zero.

#### Scenario: Carryover applied on next match activation
- **WHEN** a group has carryOverPot > 0 and the next included match is prepared for betting
- **THEN** the match accumulatedFromPrevious is set to carryOverPot and group carryOverPot becomes 0

