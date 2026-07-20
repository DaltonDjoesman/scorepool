## Why

The app is feature-complete enough for a public portfolio, but dead code, duplicated UI/domain helpers, a monolithic Firestore repository, nested stream UI, and missing Flutter CI weaken the signal recruiters look for. Cleaning and restructuring the codebase first makes the follow-up documentation change honest and reviewable.

## What Changes

- Remove unused dependencies, unreachable ranking UI body, orphaned repository methods, and redundant feed/ranking compatibility wrappers where safe.
- Consolidate duplicated prediction inputs, FIFA team metadata maps, and group-filter match recount logic.
- Split the monolithic `FirestoreRepository` into focused repository classes behind the existing `Repositories` facade.
- Reduce deeply nested `StreamBuilder` usage on match details (and related feed composition where practical) via a combined stream / small view-model layer — without introducing Riverpod/Bloc.
- Add a GitHub Actions workflow that runs `flutter analyze` and `flutter test` on pull requests and pushes.
- Keep product behavior unchanged unless required by safe deletion of dead paths; no Google Sign-In implementation (docs change corrects README only).

## Capabilities

### New Capabilities

- `code-hygiene`: Dead-code removal, unused dependency cleanup, and shrinking legacy route wrappers.
- `shared-ui-domain`: Shared prediction input, team metadata, and group-filter recount helpers used by multiple screens.
- `data-access-layer`: Focused Firestore repositories (groups, matches, predictions, debts, profiles) replacing the single god-repo surface.
- `match-screen-state`: Combined async/stream composition for match details (and related heavy stream screens) instead of deep nested builders.
- `flutter-ci`: Continuous integration for Flutter analyze and tests.

### Modified Capabilities

- *(none — behavior requirements stay the same; this change is structural/quality)*

## Impact

- Flutter `lib/src/repositories/`, screens under `feed/`, `match/`, `group/`, `ranking/`, team utils, `pubspec.yaml`
- Possibly `lib/src/routing/app_router.dart` (legacy ranking/feed aliases)
- New workflow under `.github/workflows/`
- Tests under `test/` may need path/import updates after repository splits
- No Firebase project / security-rules changes required
- Documentation accuracy for Google Sign-In and Functions vs Actions is deferred to `portfolio-docs-readiness`
