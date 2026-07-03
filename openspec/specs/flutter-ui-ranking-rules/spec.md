## ADDED Requirements

### Requirement: Ranking tab shows podium and full standings
The Ranking tab inside the feed shell SHALL display a "Ranking de Bruxos" header, subtitle about exact scores, a podium for positions 1–3 when at least three members exist, and a scrollable list for all members sorted by `perfectScoresCount` descending then name.

#### Scenario: Podium for top three
- **WHEN** the group has three or more members
- **THEN** the UI shows 2nd, 1st (elevated with crown), and 3rd podium blocks with avatar, rank, name, and exact-score count

#### Scenario: Fewer than three members
- **WHEN** the group has one or two members
- **THEN** the podium renders available positions without layout breakage and the full list still shows all members

#### Scenario: Current user highlighted
- **WHEN** the current user's row appears in the ranking list
- **THEN** their row uses accent border/color styling equivalent to the HTML "(Geral)" highlight

#### Scenario: Empty group
- **WHEN** the group has no members
- **THEN** an info empty state "Nenhum membro no grupo" is shown

### Requirement: Regulamento tab shows group-specific rules
The Regulamento tab SHALL display rule cards for: per-match entry fee (using group currency and `entryFeeCents`), prediction lock minutes, exact-score winner rule with split, and snowball accumulation — with copy aligned to the HTML prototype.

#### Scenario: Dynamic entry fee in rules
- **WHEN** the user opens Regulamento with an active group
- **THEN** the aposta por partida card shows the group's formatted entry fee

#### Scenario: Dynamic lock minutes in rules
- **WHEN** the user opens Regulamento
- **THEN** the bloqueio card references `predictionLockMinutes` from the group document

#### Scenario: No group on rules tab
- **WHEN** no group is selected and the user somehow reaches Regulamento
- **THEN** the tab shows guidance to select a group (consistent with feed empty state)
