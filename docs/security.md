# Security checklist (public repo)

## Secrets — never commit

| Secret | Where it lives |
|--------|----------------|
| Firebase service account JSON | GitHub `FIREBASE_SERVICE_ACCOUNT_JSON`, local `GOOGLE_APPLICATION_CREDENTIALS` |
| football-data.org token | GitHub `FOOTBALL_DATA_TOKEN`, Cloud Functions secret |
| Android signing keystore | Local `key.properties` + `*.jks` (gitignored) |

Verify before push:

```bash
git ls-files docs/worldcup-pool-tracker-app.json   # must be empty
git log -S "BEGIN PRIVATE KEY" --oneline            # must be empty
```

## Firebase client API keys

`lib/firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist`
contain **client** API keys. They are expected in mobile repos but must be paired with:

### 1. API key restrictions (Google Cloud Console)

1. Open [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
2. Select project `worldcup-pool-tracker-app`
3. For each Android/iOS API key:
   - **Application restrictions**: Android apps → package `com.example.worldcupbettrackerApp` + SHA-1; iOS → bundle ID
   - **API restrictions**: limit to Firebase-related APIs (Identity Toolkit, FCM, etc.)

### 2. Firebase App Check

1. [Firebase Console → App Check](https://console.firebase.google.com/project/worldcup-pool-tracker-app/appcheck)
2. Register **Play Integrity** (Android) and **App Attest / DeviceCheck** (iOS)
3. Enforce App Check on **Cloud Firestore** once apps send tokens

Until App Check is enforced in the app, API key restrictions are the main line of defense.

## Firestore rules

Settlement fields (`winnerUids`, `basePotCents`, `totalPotCents`, `closeoutAt`,
`perfectScoresCount`, `carryOverPotCents`) are **server-only** — clients cannot forge results.

Deploy after changes:

```bash
firebase deploy --only firestore:rules --project worldcup-pool-tracker-app
```

## GitHub Actions secrets

Required in repo settings → Secrets and variables → Actions:

| Secret | Purpose |
|--------|---------|
| `FOOTBALL_DATA_TOKEN` | WC2026 fixture ingestion |
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Write catalog to Firestore |

Verify:

```bash
gh secret list
```
