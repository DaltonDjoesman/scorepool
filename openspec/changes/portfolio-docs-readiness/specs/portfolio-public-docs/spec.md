## ADDED Requirements

### Requirement: README auth claims match implementation
The root README SHALL describe authentication as email/password only and SHALL NOT claim Google (or Apple) sign-in unless implemented.

#### Scenario: Stack table is accurate
- **WHEN** a recruiter reads the Auth row in the README tech stack
- **THEN** it states Firebase Auth email/password without listing unimplemented OAuth providers

### Requirement: README backend runtime is honest
The README architecture section SHALL describe the live Spark-tier path (GitHub Actions for catalog ingest and closeout) and clarify that Cloud Functions under `functions/` are present but not the currently deployed notification/closeout runtime unless stated otherwise.

#### Scenario: Actions vs Functions clarified
- **WHEN** a recruiter reads the Architecture section
- **THEN** they can tell what runs in production today versus what exists as undeployed Functions code

### Requirement: Screenshot placeholders are wired
The repository SHALL provide `docs/screenshots/` guidance and README image slots for key screens; binary images MAY be added later.

#### Scenario: Placeholder gallery listed
- **WHEN** a contributor opens `docs/screenshots/README.md`
- **THEN** it lists expected screenshot filenames and the main README references those paths with a note that images are pending

### Requirement: OpenSpec process is visible
The README SHALL include a short “How this was built” (or equivalent) subsection linking to OpenSpec specs and delivery docs.

#### Scenario: Process links present
- **WHEN** a recruiter skims the README
- **THEN** they find links to `openspec/specs/` and `openspec/delivery.md` (or equivalent paths)

### Requirement: Contribution and architecture docs exist
The repository SHALL include English `CONTRIBUTING.md` and `docs/architecture.md` describing local setup expectations and layered architecture after the code-cleanup change.

#### Scenario: Docs files present
- **WHEN** a recruiter browses the repo root and `docs/`
- **THEN** both `CONTRIBUTING.md` and `docs/architecture.md` exist and are written in English

### Requirement: Language and package description clarity
The README SHALL state that app UI copy is Portuguese and documentation is English, and `pubspec.yaml` description SHALL NOT remain the default Flutter template sentence.

#### Scenario: Non-template pubspec description
- **WHEN** a reviewer reads `pubspec.yaml` description
- **THEN** it summarizes CopaBolão / World Cup pool tracker in one clear sentence

### Requirement: Pre-public security pointer
The README or linked docs SHALL point authors to `docs/security.md` before making the repository public.

#### Scenario: Security checklist linked
- **WHEN** a maintainer prepares a public release
- **THEN** the docs explicitly reference the security checklist
