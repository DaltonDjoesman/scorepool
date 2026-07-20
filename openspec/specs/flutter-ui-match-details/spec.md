# flutter-ui-match-details Specification

## Purpose
Specifies the match details view including hero information, prediction status, and payment ledgers.

## Requirements


### Requirement: Match details hero summarizes game outcome
The match details screen SHALL open with a hero section showing date/time, phase, status, teams with flags, final or live score, distributed pot amount, and winner split summary (or accumulation message), matching the HTML `postgame-hero`.

#### Scenario: Finished game with winners
- **WHEN** the match is finished with one or more winners
- **THEN** the hero shows pot total and per-winner share amount

#### Scenario: Finished game without winners
- **WHEN** the match ended with no exact-score winners
- **THEN** the hero shows that the pot accumulated to the next match

### Requirement: Lock countdown banner is visually integrated
The existing lock countdown logic SHALL be rendered with prototype styling (timer vs locked states, accent vs muted container).

#### Scenario: Countdown before lock
- **WHEN** the match is scheduled and before lock time
- **THEN** a banner shows remaining time updating at least every second

#### Scenario: Locked state
- **WHEN** lock time has passed
- **THEN** the banner shows "Palpites trancados" with lock icon and muted styling

### Requirement: Prediction and participation cards match prototype
The screen SHALL retain prediction input/clear/save, participation opt-out switch with per-game note, and read-only states after lock, using card layout and iOS-style switch appearance from the HTML prototype.

#### Scenario: Opt-out visible when disabled
- **WHEN** the user opts out of the pot for this match
- **THEN** the card shows "Fora do pote" with optional opt-out timestamp and the per-game disclaimer

### Requirement: Group predictions list shows after lock
When predictions are locked and the match is live or finished, the app SHALL list all members' predictions with opt-out members marked "Fora do Pote", sorted by display name.

#### Scenario: Live locked predictions visible
- **WHEN** the match is live and past lock
- **THEN** the "Palpites do Grupo" section lists each member's prediction or opt-out status

### Requirement: Payment ledger uses grouped transparency list for finished matches
For finished matches with winners, the screen SHALL show a ledger section with pending count summary, personal loser CTA ("Já paguei"), personal winner banner, searchable participant list, and groups: Pendentes, Pagamento Declarado, and Vencedores — backed by existing `DebtItem` streams and declare-paid actions.

#### Scenario: Loser declares payment
- **WHEN** the current user owes a pending debt before kickoff (or per existing business rules) and taps Já paguei
- **THEN** the debt is marked paid in Firestore and the UI moves the row to the paid group

#### Scenario: Search filters transparency list
- **WHEN** the user types in the participant search field
- **THEN** the grouped ledger rows filter by member display name

#### Scenario: Multiple winners payee selection
- **WHEN** there are multiple winners and a debtor has not chosen a payee
- **THEN** the UI allows selecting which winner receives payment (if supported by data model) or shows auto-assigned payee per existing ledger rules

### Requirement: Back navigation returns to feed
Match details SHALL provide back navigation to the feed shell without signing the user out.

#### Scenario: Back from details
- **WHEN** the user taps the back control
- **THEN** navigation returns to `/feed` on the Feed tab
