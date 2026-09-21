# Contributing

Thanks for taking an interest in Scorepool. This is a personal / portfolio project; small PRs that improve clarity, tests, or docs are welcome.

## Prerequisites

- Flutter SDK matching CI (see `.github/workflows/flutter-ci.yml`, currently **3.41.9**)
- Node.js **20** for scripts under `functions/`
- Firebase project access only if you need live backend work (most UI/unit work can use `FIREBASE_ENABLED=false`)

## Setup

```bash
flutter pub get
flutter analyze
flutter test
```

Functions / ingest scripts:

```bash
cd functions
npm ci
npm run test:pot
```

Never commit secrets. Service-account JSON must live **outside** the repo; see [`docs/security.md`](docs/security.md).

## Branching

- Do not push product commits directly to `main`.
- Prefer one focused branch per change.

## Pull requests

- Keep the PR scoped; describe *why* in the summary.
- Ensure `flutter analyze` and `flutter test` pass.
- Update docs when behavior or public claims change.
- UI strings in the app are Portuguese; docs in this repo stay English.

## Code layout (short)

See [`docs/architecture.md`](docs/architecture.md): screens → repositories → Firestore; shared domain utils under `lib/src/utils/`; TypeScript domain logic under `functions/src/` with Admin scripts for the live Spark path.
