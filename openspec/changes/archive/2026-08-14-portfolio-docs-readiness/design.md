## Context

After code cleanup, the remaining portfolio gap is packaging: README inaccuracies (Google Sign-In; Functions presented as the live path), no screenshot slots, OpenSpec process hidden, thin contribution/architecture docs, and template `pubspec` description. Audience is internship/job recruiters; docs MUST be English. App UI stays Portuguese.

Depends on `portfolio-code-cleanup` merging first so architecture/CI descriptions match reality.

## Goals / Non-Goals

**Goals:**

- Honest English README (auth, backend runtime, languages, demo path via HTML prototype).
- Screenshot placeholders + README gallery slots (binaries added later by author).
- Short “How this was built” pointing at OpenSpec.
- `CONTRIBUTING.md` and `docs/architecture.md`.
- Align `flutter-ui-auth-group` requirements with email/password-only login.
- Point readers at `docs/security.md` before going public.

**Non-Goals:**

- Capturing real screenshot PNGs/Loom video.
- Making the GitHub repository public (manual).
- Implementing OAuth or deploying Functions.
- Flutter CI workflow (code change).
- Translating in-app UI strings to English.

## Decisions

1. **Correct claims, don’t implement OAuth**  
   README + auth-group spec drop Google/Apple as requirements.  
   *Alternative:* Implement Google Sign-In — deferred by product owner.

2. **Document Spark reality**  
   Architecture section: ingest/closeout via GitHub Actions Admin scripts; `functions/` is the designed Cloud Functions path (undeployed on Spark); FCM token client-side; push dispatch not live until Functions/Blaze.  
   *Alternative:* Hide Actions — rejected (honesty > marketing).

3. **Screenshot placeholders**  
   `docs/screenshots/README.md` lists expected filenames (`01-login.png`, …); main README uses markdown image links that 404 until files exist — acceptable with a note “add images before publishing”.  
   *Alternative:* Wait until images exist — rejected; structure unblocks parallel work.

4. **OpenSpec visibility**  
   Short README subsection + links to `openspec/specs/` and `openspec/delivery.md` — not a full process dump.

5. **Auth-group delta**  
   MODIFY login requirement to remove OAuth buttons SHALL; keep prototype-without-Firebase and session card scenarios.

6. **Order relative to code change**  
   Apply this change only after `portfolio-code-cleanup` CI and architecture split land (or update architecture doc to describe post-cleanup layout).

## Risks / Trade-offs

- [Broken image links until screenshots added] → Explicit placeholder note in README and `docs/screenshots/README.md`.
- [Spec archive conflicts with HTML prototype parity specs still mentioning OAuth] → Only change main `flutter-ui-auth-group`; archive changes untouched.
- [Over-promising “production”] → Keep honest “personal/portfolio; used by a real group” framing.

## Migration Plan

1. Merge after code-cleanup PRs.
2. Author adds screenshots later; then make repo public after security checklist.
3. Rollback: revert docs PR (no runtime impact).

## Open Questions

- Exact screenshot set left to author; placeholders define a recommended list of 5–6 screens.
