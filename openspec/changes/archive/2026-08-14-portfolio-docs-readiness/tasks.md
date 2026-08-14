## 0. Repo hygiene (portfolio cleanup)

- [x] 0.1 Move local service-account JSON outside the clone; reinforce `docs/security.md` (never store SA JSON inside the repo even if gitignored)
- [x] 0.2 Remove unused Flutter platform scaffolds (`web/`, `linux/`, `macos/`, `windows/`); target Android & iOS only
- [x] 0.3 Align `functions` tooling: Node 20 engines, remove dead `eslint` lint script; trim Flutter template fluff in `pubspec.yaml` / `test/widget_test.dart`
- [x] 0.4 Mark delivered sections `done: true` in `openspec/github-delivery.yaml`

## 1. README accuracy and metadata

- [x] 1.1 Correct README Auth/tech claims to email/password only (remove unimplemented Google Sign-In)
- [x] 1.2 Rewrite README Architecture to describe live Actions ingest/closeout vs undeployed `functions/` path and FCM token-only reality
- [x] 1.3 Clarify UI language (Portuguese) vs docs language (English); reframe “not production” as portfolio / real-group usage
- [x] 1.4 Update `pubspec.yaml` description away from the default Flutter template sentence
- [x] 1.5 Link `docs/security.md` as a pre-public checklist from the README

## 2. Screenshots, OpenSpec, and supporting docs

- [x] 2.1 Create `docs/screenshots/README.md` listing expected filenames (login, feed, prediction, ledger, ranking, group hub)
- [x] 2.2 Add README screenshot gallery slots pointing at those paths with a note that binaries are added later
- [x] 2.3 Add a short “How this was built” README subsection linking `openspec/specs/` and `openspec/delivery.md`
- [x] 2.4 Add English `CONTRIBUTING.md` (setup, analyze/test, PR expectations)
- [x] 2.5 Add English `docs/architecture.md` reflecting post-cleanup layers (UI → facade repos → Firestore; Actions/Functions)
- [x] 2.6 Optionally add CI badge markdown to README once `portfolio-code-cleanup` Flutter CI is on the default branch

## 3. Auth-group spec alignment

- [x] 3.1 Apply the `flutter-ui-auth-group` delta: login requirement without OAuth SHALLs; email/password-only scenario
- [x] 3.2 Archive/apply path: ensure main `openspec/specs/flutter-ui-auth-group/spec.md` will match after change archive (no conflicting OAuth MUST)
- [x] 3.3 Spot-check login UI still matches the updated requirement (no OAuth buttons required)
