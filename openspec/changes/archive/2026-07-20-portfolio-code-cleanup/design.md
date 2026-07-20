## Context

CopaBolão is a Flutter + Firebase portfolio app. Recruiters will skim structure, tests, and CI. Current pain points from the project audit: unused deps and legacy ranking UI, duplicated prediction/team/filter helpers, a ~700-line `FirestoreRepository`, deeply nested `StreamBuilder` trees on match details, and no Flutter analyze/test workflow (only WC2026 ingest Actions).

Constraints: keep `ChangeNotifier` + `InheritedWidget` DI (`app.dart`); do not introduce Riverpod/Bloc; preserve product behavior; delivery is one PR per `tasks.md` section.

## Goals / Non-Goals

**Goals:**

- Remove confirmed dead code and unused dependencies.
- Deduplicate shared UI/domain helpers without changing UX copy or flows.
- Split data access into focused repositories while keeping a thin `Repositories` facade for screens.
- Flatten match-details stream composition into a testable combiner/view-model.
- Add green Flutter CI on PRs/pushes.

**Non-Goals:**

- Google/Apple OAuth implementation.
- Deploying Cloud Functions or changing Spark/Actions runtime.
- Rewriting state management to Riverpod/Bloc.
- Documentation/README packaging (owned by `portfolio-docs-readiness`).
- Changing Firestore schema or security rules.

## Decisions

1. **Incremental A → B → C order**  
   Cleanup first (low risk), then shared helpers, then repository split and stream composition, then CI (validates the refactors).  
   *Alternative:* Big-bang rewrite — rejected (harder to review, higher regression risk).

2. **Keep `Repositories` facade; split internals**  
   Screens keep `appRepos(context).groups` / `.matches` / etc. (or temporary `firestore` alias during migration). Prefer explicit named repos over one god class.  
   *Alternative:* Package-by-feature with GetIt — rejected as out of scope for portfolio polish.

3. **No new state-management framework**  
   Match details gets a small Dart class that merges Firestore streams (e.g. `rxdart` only if already present; otherwise `StreamZip` / manual combine / `async*` without new deps if possible). Prefer zero new runtime dependencies.  
   *Alternative:* Riverpod — deferred; document “why ChangeNotifier” in the docs change.

4. **Prediction consolidation**  
   Extract shared controller/parse/save logic; keep two thin widgets if feed vs details layout must differ.  
   *Alternative:* One widget for both — may fight layout; shared logic is enough.

5. **Team metadata**  
   Single source of FIFA code → display name + ISO2 (and crest overrides stay in crest resolver).  
   *Alternative:* Codegen from JSON asset — nice later, overkill now.

6. **Legacy routes**  
   Keep `/ranking` redirect and route constants for compatibility; shrink `RankingScreen` to redirect-only / constant holder. Collapse `FeedScreen` alias if router can import shell directly.

7. **Flutter CI**  
   Workflow: checkout → Flutter stable → `pub get` → `analyze` → `test`. Badge consumed by docs change.  
   *Alternative:* Only analyze — rejected; tests already exist and are portfolio signal.

## Risks / Trade-offs

- [Regression during repo split] → Migrate call sites behind facade; run full `flutter test` in CI section; keep method names stable where possible.
- [Nested streams still elsewhere] → Prioritize match details; feed may get a lighter pass only if time-boxed in the same section.
- [Removing “unused” repo methods that specs mention conceptually] → Verify no dynamic/call-site usage; `joinGroup` already covers member upsert path.
- [CI flake / Flutter version drift] → Pin Flutter channel/version in workflow.

## Migration Plan

1. Merge section PRs in order (hygiene → shared UI → data layer → match state → CI).
2. After each PR: `flutter analyze` + `flutter test` locally.
3. Rollback: revert individual section PR; facade keeps old `firestore` property until last callers migrate if needed.

## Open Questions

- None blocking; prefer zero new packages for stream combine unless analyze forces a clean helper.
