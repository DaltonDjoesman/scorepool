## MODIFIED Requirements

### Requirement: User can declare "paid" after match finishes
For each debt item where fromUid equals the current user, the user SHALL be able to set status=paid when the group match status is `finished` and the debt status is `pending`.

#### Scenario: Paid declaration allowed after finish
- **WHEN** the match status is finished and the user has a pending debt as fromUid
- **THEN** the user can set their debt status to paid

#### Scenario: Paid declaration rejected before finish
- **WHEN** the match status is not finished
- **THEN** attempts to set debt status to paid are rejected

#### Scenario: Only payer can declare
- **WHEN** another group member attempts to declare paid on someone else's debt
- **THEN** the update is rejected
