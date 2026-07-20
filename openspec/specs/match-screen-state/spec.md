# match-screen-state Specification

## Purpose
Combined async/stream composition for match details instead of deep nested StreamBuilders.

## Requirements

### Requirement: Match details uses composed screen state
The match details screen SHALL obtain its primary Firestore-backed inputs through a dedicated composition layer (combined streams or view-model) rather than five-or-more nested `StreamBuilder` widgets in the build method.

#### Scenario: Single composition drives the screen
- **WHEN** match details opens for a group match
- **THEN** overlay, prediction, participation, members, and related streams are composed outside nested builder pyramids and the UI rebuilds from the composed state

### Requirement: Loading and error states remain explicit
The match details composition layer SHALL expose distinct loading and error states that the UI can render without silent empty screens.

#### Scenario: Error surfaces to the user
- **WHEN** one of the composed streams fails
- **THEN** the match details UI shows an error affordance instead of hanging on nested builders

### Requirement: Behavior parity for match details sections
Hero, countdown/lock, prediction input, group predictions, transparency, and payment ledger sections SHALL continue to appear with the same product rules after the state composition refactor.

#### Scenario: Sections still render with live data
- **WHEN** a finished or upcoming match is opened
- **THEN** the existing section widgets still receive the data they need and user actions (save prediction, declare paid) still persist
