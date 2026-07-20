## MODIFIED Requirements

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
