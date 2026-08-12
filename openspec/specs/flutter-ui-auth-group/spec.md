# flutter-ui-auth-group Specification

## Purpose
Specifies the login screen layout, flows, group selection, and navigation via the group hub.

## Requirements


### Requirement: Login screen matches prototype layout and flows
The login screen SHALL present the CopaBolão 2026 branding (logo, title), Firebase mode badge, email/password auth with register toggle, prototype continue without Firebase when Firebase is disabled, and active-session card when already signed in. The login screen SHALL NOT require Google or Apple OAuth buttons unless those providers are implemented.

#### Scenario: Prototype mode without Firebase
- **WHEN** Firebase is disabled and the user taps "Continuar (Sem Firebase)"
- **THEN** the app navigates to the group hub without authentication

#### Scenario: Active session card
- **WHEN** the user is already signed in on the login screen
- **THEN** the app shows email, uid, optional current group id, and buttons Continuar and Sair da Conta

#### Scenario: Register mode
- **WHEN** the user toggles to create account mode
- **THEN** a confirm-password field appears and submit label changes to register wording

#### Scenario: Email password only
- **WHEN** Firebase is enabled on the login screen
- **THEN** the primary auth controls are email/password sign-in and register (no OAuth provider buttons required)

### Requirement: Group hub consolidates group selection and navigation
The group hub screen SHALL replace the placeholder layout with: user session summary, active group card (name, id, entry fee badge), shortcuts to open feed and ranking, edit-filter entry for admins, join-by-code form, and create-new-group button.

#### Scenario: Active group shortcuts
- **WHEN** the user has a current group selected
- **THEN** "Abrir feed" navigates to `/feed` and "Ver ranking" navigates to feed shell with Ranking tab active

#### Scenario: No active group warning
- **WHEN** no group is selected
- **THEN** the active group card shows a warning that the user must join or create a group

#### Scenario: Join group by id
- **WHEN** the user submits a valid group id in the join form
- **THEN** the app upserts member profile, sets `currentGroupId`, and shows the group as active on the hub

#### Scenario: Logout from group hub
- **WHEN** the user taps Sair on the group hub
- **THEN** the app signs out (if Firebase) and returns to login
