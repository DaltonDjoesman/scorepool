# flutter-ui-group-setup Specification

## Purpose
Specifies group setup forms, admin options, phase/team filtering, and edit views.

## Requirements


### Requirement: Create group form matches prototype structure
The create-group screen SHALL collect name, currency, entry fee (with cent preview), prediction lock minutes, team filter with search and flag chips, phase filter grid, included-match count with recalculate action, and submit that creates the group and navigates to feed.

#### Scenario: Team chip selection with search
- **WHEN** the user searches teams and toggles chips
- **THEN** only matching teams are shown and selected team ids are tracked for the filter

#### Scenario: Recalculate included matches
- **WHEN** the user taps Recalcular Jogos
- **THEN** the app queries the catalog and displays the count of matches matching the current filter

#### Scenario: Successful creation
- **WHEN** the user submits a valid form
- **THEN** the group is created in Firestore, set as current group, and the user is navigated to `/feed`

### Requirement: Edit filter screen enforces admin and prerequisite states
The edit-filter screen SHALL load current group filter, show the same team/phase pickers as create-group, support recalculate and save, and display dedicated empty/error states for: not logged in, no group, not admin, and loading.

#### Scenario: Non-admin blocked
- **WHEN** a non-admin member opens edit filter
- **THEN** the app shows a message that only admins can edit the filter

#### Scenario: Save filter success
- **WHEN** an admin saves an updated filter
- **THEN** Firestore is updated and a success snackbar/toast is shown

#### Scenario: Cancel navigation
- **WHEN** the user taps Voltar/Cancelar on create or edit filter
- **THEN** they return to the group hub without losing auth state
