## 1. Code hygiene

- [x] 1.1 Remove unused `cupertino_icons` from `pubspec.yaml` and run `flutter pub get`
- [x] 1.2 Shrink legacy `ranking_screen.dart` to redirect/route-constant only (keep `/ranking` redirect behavior)
- [x] 1.3 Remove orphaned public repo methods (`upsertMemberProfile`, unused `reconcileGroupMatches`) after confirming no callers
- [x] 1.4 Clean `FeedScreen` alias / router imports so `/feed` uses the shell directly without redundant wrappers
- [x] 1.5 Run `flutter analyze` and `flutter test`; fix any fallout from hygiene

## 2. Shared UI and domain helpers

- [x] 2.1 Extract shared prediction parse/sync/persist helper; wire feed inline inputs and match details prediction card to it
- [x] 2.2 Consolidate FIFA team display name + flag ISO2 maps into one shared metadata module; update call sites
- [x] 2.3 Extract shared included-match recount helper; use it from create-group and edit-group-filter screens
- [x] 2.4 Add/adjust unit tests for shared helpers where practical; run `flutter test`

## 3. Data access layer split

- [x] 3.1 Split `FirestoreRepository` into focused repos (groups, matches/overlays, predictions/participation, debts, profiles) preserving method behavior
- [x] 3.2 Update `Repositories` facade to expose domain repos; migrate screen/call-site imports
- [x] 3.3 Delete or reduce the old monolith file once callers are migrated
- [x] 3.4 Run `flutter analyze` and `flutter test`; fix import/type fallout

## 4. Match screen state composition

- [x] 4.1 Introduce a match-details composition layer (combined streams / view-model) without adding Riverpod/Bloc
- [x] 4.2 Refactor `match_details_screen.dart` to consume composed state with explicit loading/error UI
- [x] 4.3 Verify section widgets (prediction, transparency, ledger, hero) still receive required data and actions persist
- [x] 4.4 Run `flutter analyze` and `flutter test`; add a focused test for the composition helper if feasible

## 5. Flutter CI

- [x] 5.1 Add `.github/workflows/flutter-ci.yml` with pinned Flutter setup, `flutter pub get`, `flutter analyze`, `flutter test`
- [x] 5.2 Trigger the workflow on pull_request and pushes to the default branch
- [x] 5.3 Confirm the workflow file is valid YAML and documents the Flutter version pin in-repo
