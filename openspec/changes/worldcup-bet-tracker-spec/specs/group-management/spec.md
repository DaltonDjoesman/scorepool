## ADDED Requirements

### Requirement: User can create a group with configuration
The system SHALL allow an authenticated user to create a group with configuration including currency, entry fee, and prediction lock minutes.

#### Scenario: Create group successfully
- **WHEN** an authenticated user submits a valid group name, currency, entry fee, and prediction lock minutes
- **THEN** the system creates a group and assigns the creator as an admin member

### Requirement: Group members are managed per group
The system MUST maintain a membership list per group, including role (admin/member) and basic profile fields used for display (name, photoUrl).

#### Scenario: Member list shown to participants
- **WHEN** a group member opens the group participants screen
- **THEN** the system displays the current member list and roles as permitted

### Requirement: Group configuration is editable by admins
The system SHALL allow only group admins to update group configuration.

#### Scenario: Non-admin cannot edit group
- **WHEN** a non-admin member attempts to update group configuration
- **THEN** the write is rejected

### Requirement: Group has match filter configuration
The system SHALL store match filter settings per group, including selected team IDs and selected stages.

#### Scenario: Group filter is persisted
- **WHEN** an admin updates selected teams and/or stages for the group
- **THEN** the updated filter is persisted and becomes the source of truth for group match inclusion

