# shared-ui-domain Specification

## Purpose
Shared prediction input, team metadata, and group-filter recount helpers used by multiple screens.

## Requirements

### Requirement: Shared prediction input logic
Exact-score prediction enter/edit flows in the feed and match details SHALL share one implementation for controller sync, parsing non-negative integers, and persisting via the repository upsert API.

#### Scenario: Feed and details save the same way
- **WHEN** a user saves a prediction from the feed inline inputs or from the match details prediction card
- **THEN** both paths use the shared parse/persist logic and show success or error feedback consistently

### Requirement: Single FIFA team metadata source
Team FIFA codes SHALL map to display names and flag ISO2 codes from one shared metadata module (crest CDN overrides may remain adjacent).

#### Scenario: Same code resolves name and flag
- **WHEN** UI resolves a FIFA team code for label and flag emoji
- **THEN** both resolutions read from the shared metadata source without duplicated parallel maps

### Requirement: Shared group filter match recount
Create-group and edit-group-filter screens SHALL use one shared helper to count included catalog matches for the selected filter.

#### Scenario: Create and edit recount agree
- **WHEN** the same filter selection is applied on create or edit filter screens
- **THEN** the included-match count is computed by the same shared helper
