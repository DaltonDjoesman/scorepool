# Demo APK (portfolio installable)

The portfolio **demo** Android build talks to a separate Firebase project (`copabolaao-demo`), not production (`worldcup-pool-tracker-app`). A Release artefact is optional and must never be a production APK.

| Item | Value |
|------|--------|
| Package | `com.example.worldcupbettracker_app.demo` |
| App label | CopaBolão Demo |
| Firebase | `copabolaao-demo` |
| Auth | Email/password (register in-app) |

## Install

A GitHub Release APK is **not published yet**. Build the demo flavor locally (below), or wait for a Release that explicitly says **demo** — never a production APK.

1. Install the demo `.apk` (sideload; allow unknown sources).
2. Open the app → **register** with any email/password (≥ 6 chars).
3. Create a bolão (select knockout stages) or join with a friend’s code.

The demo catalog is a small seeded knockout set (not live football-data.org). Data may be wiped; treat it as a sandbox.

## Build locally

```bash
# Requires Android SDK. Flavor + dart-define must both be demo.
flutter build apk --release \
  --flavor demo \
  --dart-define=APP_ENV=demo

# Output:
# build/app/outputs/flutter-apk/app-demo-release.apk
```

Production flavor (default package, production Firebase options):

```bash
flutter run --flavor prod
# or
flutter build apk --release --flavor prod --dart-define=APP_ENV=prod
```

## Maintainers — demo Firebase

```bash
# Deploy the same rules/indexes as production to the demo project
npx -y firebase-tools@latest deploy \
  --only firestore:rules,firestore:indexes \
  --project copabolaao-demo

# Seed teams + a few matches (uses Firebase CLI login token)
cd functions && npm run seed:demo
```

Enable **Email/Password** in the [demo Authentication console](https://console.firebase.google.com/project/copabolaao-demo/authentication/providers) once per project (Spark-friendly Firebase Auth — not Identity Platform billing).
