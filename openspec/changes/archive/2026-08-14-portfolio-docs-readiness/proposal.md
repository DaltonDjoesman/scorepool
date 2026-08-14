## Why

The product and (after `portfolio-code-cleanup`) the code quality will be recruiter-ready, but the public packaging is not: README claims do not match runtime, there are no screenshot placeholders, OpenSpec delivery is invisible, and supporting docs for architecture/contribution are thin. This change makes the repository honest and demoable for internship/job applications without implementing new product features.

## What Changes

- Correct README tech claims: email/password auth only (no Google Sign-In); document Spark-tier reality (GitHub Actions for ingest/closeout; Cloud Functions code present but not the live dispatch path unless deployed).
- Add screenshot placeholders under `docs/screenshots/` and wire them into the README (images added later by the author).
- Surface OpenSpec / delivery process briefly in the README (“How this was built”).
- Add `CONTRIBUTING.md` and `docs/architecture.md` (English).
- Clarify UI language (Portuguese) vs docs language (English).
- Improve repo-facing metadata hints in README/`pubspec.yaml` description (away from template text).
- Align OpenSpec auth UI requirements with email/password-only reality (remove unimplemented OAuth SHALLs).
- Security checklist reminder before making the repo public (no secret commits; follow `docs/security.md`) — docs/process only.
- Out of scope: implementing Google Sign-In, deploying Cloud Functions, capturing screenshot binaries, making the GitHub repo public (manual step), Flutter CI (owned by `portfolio-code-cleanup`).

## Capabilities

### New Capabilities

- `portfolio-public-docs`: README accuracy, screenshot slots, OpenSpec visibility, CONTRIBUTING, architecture doc, pubspec description, language clarity.

### Modified Capabilities

- `flutter-ui-auth-group`: Login requirements must match implemented auth (email/password + Firebase-off prototype path); remove SHALLs for Google/Apple OAuth buttons that are not implemented.

## Impact

- `README.md`, `pubspec.yaml` description, new `CONTRIBUTING.md`, `docs/architecture.md`, `docs/screenshots/` placeholders
- Delta on `openspec/specs/flutter-ui-auth-group/spec.md`
- Possible light touch to `docs/firebase_setup.md` / `docs/security.md` cross-links only
- Depends on `portfolio-code-cleanup` landing first so docs can describe the cleaned architecture and CI badge truthfully
- No application runtime behavior changes except via the auth-group spec alignment (docs/spec truth; UI already lacks OAuth)
