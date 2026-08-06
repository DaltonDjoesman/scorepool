# flutter-ui-feed Specification

## Purpose
Specifies the match feed organization, tabs, states, and action flows.

## Requirements


### Requirement: Feed organizes matches in active and archived views
The feed tab SHALL provide a toggle between "Jogos Ativos" and "Arquivados" and, within active games, sub-tabs for Próximos, Ao vivo, and Encerrados, backed by existing Firestore queries (`excludedByFilter`, `MatchStatus`).

#### Scenario: Archived matches list
- **WHEN** the user selects Arquivados
- **THEN** matches excluded by the group filter are listed with reduced emphasis and an "Excluído do Bolão" label

#### Scenario: Empty tab state
- **WHEN** a sub-tab has no matches
- **THEN** the app shows the appropriate empty message for that tab

### Requirement: Match cards use rich visual layout from prototype
Each match card SHALL show status badge, local date/time, teams with flags and names, center score or prediction inputs, accumulation banner when applicable, and footer actions/status per game state.

#### Scenario: Scheduled match inline prediction
- **WHEN** a match is scheduled and before lock
- **THEN** the card shows inline numeric inputs for home/away scores and a "Salvar Palpite" button that persists via Firestore without leaving the feed

#### Scenario: Live match locked prediction and secar action
- **WHEN** a match is live and predictions are locked
- **THEN** the card shows the user's locked prediction with lock icon and a "Secar Palpites da Galera" button

#### Scenario: Finished match summary
- **WHEN** a match is finished
- **THEN** the card highlights winners or "sem vencedores — pote acumulado", shows total pot, and "Ver Detalhes" affordance; tap navigates to match details

#### Scenario: Accumulated pot banner
- **WHEN** a match has `accumulatedFromPreviousCents > 0`
- **THEN** a prominent banner shows the accumulated pot amount

### Requirement: Secar Palpites drawer shows group predictions during live matches
Tapping "Secar Palpites da Galera" SHALL open a bottom sheet or drawer listing all members' locked predictions for that match, visible only after lock while the match is live.

#### Scenario: Open secar drawer
- **WHEN** the user taps Secar Palpites on a live locked match
- **THEN** a drawer opens with participant names and their predictions, highlighting the current user

#### Scenario: Close secar drawer
- **WHEN** the user dismisses the drawer overlay or close button
- **THEN** the drawer closes and the feed remains on the same scroll position

### Requirement: Feed uses real-time data with friendly errors
The feed SHALL continue using Firestore streams for members, group, and matches, and SHALL surface index-building errors with the existing friendly message pattern.

#### Scenario: Firestore index pending
- **WHEN** the matches query fails with failed-precondition
- **THEN** the feed shows the index-building guidance message instead of a raw exception


### Requirement: Scheduled feed cards navigate to details
Tapping a scheduled match card SHALL navigate to match details; inline prediction inputs SHALL not trigger navigation.

#### Scenario: Navigation on tap
- **WHEN** the user taps a scheduled match card
- **THEN** the app SHALL navigate to the match details view

#### Scenario: Prediction inputs inline
- **WHEN** the user interacts with prediction inputs inline on the card
- **THEN** the app SHALL NOT navigate to the match details view

### Requirement: Feed shows estimated pot when applicable
Scheduled and live feed cards SHALL display pot value using the same estimation formula as match details when carryover or entry-fee pot applies.

#### Scenario: Feed card displays estimated pot
- **WHEN** a match card is displayed in the feed and the match has entry fees
- **THEN** the feed card SHALL display the estimated pot calculated using the entry-fee formula
