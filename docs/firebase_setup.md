# Firebase setup (dev/prod)

This app is designed to run in two modes:

- **Prototype UI mode (default)**: Firebase is disabled (no auth/firestore calls).
- **Firebase mode**: Firebase is enabled and the app expects native Firebase config.

## 1) Create Firebase projects

Create either:

- **One Firebase project** with separate apps per platform, using an `APP_ENV` convention, or
- **Two Firebase projects**: one for `dev`, one for `prod`.

## 2) Configure FlutterFire

Install and run FlutterFire CLI:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This will generate `lib/firebase_options.dart` and place:

- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist`

## 4) Ingest World Cup 2026 matches (Spark-friendly)

This repo is designed to keep Firebase on the **Spark** plan. Since Spark doesn't support Secret Manager-based workflows,
we ingest WC2026 fixtures into Firestore using **GitHub Actions**.

### GitHub secrets needed

In your GitHub repo settings, add:

- `FOOTBALL_DATA_TOKEN`: your [football-data.org](https://www.football-data.org/) API token
- `FIREBASE_SERVICE_ACCOUNT_JSON`: a service account JSON (as a single-line JSON string) with permissions to write Firestore

> **Note:** `API_FOOTBALL_KEY` is deprecated; ingestion now uses football-data.org (free tier includes WC 2026).

See also `functions/README.md` for local ingest commands.

### What it does

The workflow runs every 5 minutes and upserts fixtures into:

`tournaments/wc2026/matches/{matchId}`

You can also run it manually using the "Run workflow" button in GitHub Actions.

## 3) Run with Firebase enabled

Enable Firebase at runtime with a compile-time flag:

```bash
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=APP_ENV=dev
```

