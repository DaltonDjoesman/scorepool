## ADDED Requirements

### Requirement: Focused Firestore repositories
Data access SHALL be split into focused repository types (at minimum: groups, matches/catalog overlays, predictions/participation, debts, user/member profiles) instead of a single monolithic public repository class owning all domains.

#### Scenario: Facade exposes domain repos
- **WHEN** a screen needs Firestore group or prediction operations
- **THEN** it obtains them through the `Repositories` facade domain properties rather than calling one god-class for unrelated domains

### Requirement: Stable product operations after split
Existing product operations (create/join/leave group, watch feed matches, upsert prediction, watch/declare debts, update profile, save FCM token) SHALL remain available with equivalent behavior after the repository split.

#### Scenario: Core streams and writes still work
- **WHEN** the app performs group membership, prediction upsert, debt ledger watch, and profile update flows
- **THEN** behavior matches pre-split semantics (same collections/fields and error surfaces)

### Requirement: No Firestore schema change
The repository split SHALL NOT require new collections, renamed document fields, or security-rule changes.

#### Scenario: Rules and indexes unchanged
- **WHEN** the split is merged
- **THEN** `firestore.rules` and `firestore.indexes.json` need no mandatory edits for the refactor to function
