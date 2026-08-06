# payment-ledger Specification

## Purpose
Defines debt creation between losers and winners, deterministic amounts, paid declarations, and public ledger grouping.

## Requirements


### Requirement: Debts are created for each loser-to-winner pair
When a match finishes with one or more winners, the system MUST create debt items from each in-pot non-winner to each winner for that match.

#### Scenario: Multiple winners produce multiple payees
- **WHEN** a match finishes with 2 winners and 3 in-pot non-winners
- **THEN** the system creates 6 debt items (3 losers × 2 winners)

### Requirement: Debt amounts are deterministic and sum correctly
Debt amounts MUST be computed deterministically in minor currency units (e.g., cents) so that the sum of all debts equals the total amount to be paid by non-winners.

#### Scenario: Rounding does not lose money
- **WHEN** entryFee and winner count produce a fractional split
- **THEN** the system assigns any remainder deterministically so totals match exactly

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

### Requirement: Public ledger is grouped by payment status
The system MUST present a public view of debts grouped by status with pending items shown before paid items.

#### Scenario: Pending debts appear first
- **WHEN** the ledger view is rendered for a match
- **THEN** debts with status=pending are listed before debts with status=paid

