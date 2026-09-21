# Firebase setup

Two Firebase projects, both Spark:

| Project | Flavor | Who uses it |
|---------|--------|-------------|
| `worldcup-pool-tracker-app` | `--flavor prod` | The real friends pool |
| `copabolaao-demo` | `--flavor demo` | Portfolio sandbox / public APK |

`APP_ENV=dev` still uses the production client config today (reserved for a future split).

Before making this repository public, complete [`security.md`](security.md).

## 1) Console: enable Auth and Firestore

In the [Firebase console](https://console.firebase.google.com/project/worldcup-pool-tracker-app):

1. **Authentication** → enable the **Email/Password** provider (no Google/Apple sign-in).
2. **Firestore** → create a database if one does not exist (production mode is fine; rules in this repo are the source of truth).

## 2) Client config (already in the repo)

FlutterFire files are committed on purpose. They hold **client** API keys, not service-account private keys:

| File | Platform |
|------|----------|
| `lib/firebase_options.dart` | Dart |
| `android/app/google-services.json` | Android |
| `ios/Runner/GoogleService-Info.plist` | iOS |

Restrict those keys in Google Cloud Console (package name / bundle ID + API allowlist). Details: [`security.md`](security.md).

If you **fork** and point at your own Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

That regenerates the three files above. Do not commit a service-account JSON.

## 3) Deploy rules and indexes

From the repo root (Firebase CLI logged in, project selected):

```bash
firebase deploy --only firestore:rules,firestore:indexes --project worldcup-pool-tracker-app
```

Rules live in `firestore.rules`; indexes in `firestore.indexes.json`.

## 4) Match catalog ingest (Spark)

Spark does not run scheduled Cloud Functions with Secret Manager. Live ingest and closeout use **GitHub Actions** + the Admin SDK scripts under `functions/`.

Workflow: [`.github/workflows/ingest-wc2026.yml`](../.github/workflows/ingest-wc2026.yml)

| Trigger | When |
|---------|------|
| Cron | **Once daily at 06:00 UTC** — the 2026 tournament is over; this keeps catalog/closeouts in sync without burning Actions or Firestore quota |
| Manual | Actions → “Ingest WC2026 fixtures” → Run workflow |

What it does:

1. Upserts fixtures into `tournaments/wc2026/matches/{matchId}` from [football-data.org](https://www.football-data.org/) (server-side token only).
2. Runs closeout backfill so finished group matches settle pots / carry-over.

### GitHub secrets

Repo **Settings → Secrets and variables → Actions**:

| Secret | Purpose |
|--------|---------|
| `FOOTBALL_DATA_TOKEN` | football-data.org API token (`X-Auth-Token`) |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Service-account JSON (single-line string) with Firestore write access |

> `API_FOOTBALL_KEY` is deprecated; ingestion uses football-data.org (free tier includes WC 2026).

### Local ingest

Put the service-account JSON **outside** this clone (see [`security.md`](security.md)):

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/secrets/worldcup-pool-tracker-app.json"
export FOOTBALL_DATA_TOKEN="…"

cd functions
npm ci
npm run ingest:wc2026
npm run backfill:closeouts
```

More scripts: [`functions/README.md`](../functions/README.md).

## 5) Run the app

```bash
flutter pub get
flutter run --flavor prod                             # production Firebase
flutter run --flavor prod --dart-define=APP_ENV=dev   # same project today
flutter run --flavor demo --dart-define=APP_ENV=demo  # public demo Firebase
flutter run --dart-define=FIREBASE_ENABLED=false
flutter run --dart-define=SCREENSHOT_DEMO=true  # in-memory gallery; see docs/screenshots/README.md
```

Installable Android demo APK: [`docs/demo_apk.md`](demo_apk.md).
