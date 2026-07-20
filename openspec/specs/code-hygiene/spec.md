# code-hygiene Specification

## Purpose
Dead-code removal, unused dependency cleanup, and shrinking legacy route wrappers.

## Requirements

### Requirement: Unused dependencies are removed
The project SHALL NOT declare runtime Flutter dependencies that have zero imports under `lib/` and `test/`.

#### Scenario: cupertino_icons removed when unused
- **WHEN** no Dart file imports `cupertino_icons` or uses `CupertinoIcons`
- **THEN** `cupertino_icons` is absent from `pubspec.yaml` dependencies

### Requirement: Unreachable ranking UI is eliminated
The ranking route compatibility path SHALL NOT retain a full unused ranking `Scaffold` body that never builds.

#### Scenario: Ranking route still redirects
- **WHEN** the app navigates to `/ranking`
- **THEN** the router redirects to the feed shell Ranking tab and does not render the legacy ranking list UI

### Requirement: Orphaned repository APIs are removed
Public repository methods with no call sites outside their definition SHALL be removed or made private if still needed only internally.

#### Scenario: Dead public methods gone
- **WHEN** a developer searches the codebase for `upsertMemberProfile` and `reconcileGroupMatches` as public API entry points
- **THEN** those unused public methods are not exposed for external callers (removed or internalized only if still used by the owning class)

### Requirement: Redundant feed alias is cleaned up
The router and exports SHALL avoid unnecessary back-compat aliases when the shell screen can be referenced directly without breaking routes.

#### Scenario: Feed route still works
- **WHEN** the user opens `/feed`
- **THEN** the feed shell loads successfully after alias cleanup
