# Security checklist (public repo)

Complete this checklist before making the repository public.

## Secrets — never commit

| Secret | Where it lives |
|--------|----------------|
| Firebase service account JSON | GitHub `FIREBASE_SERVICE_ACCOUNT_JSON`; local path via `GOOGLE_APPLICATION_CREDENTIALS` **outside** this repo |
| football-data.org token | GitHub `FOOTBALL_DATA_TOKEN`, Cloud Functions secret |
| Android signing keystore | Local `key.properties` + `*.jks` (gitignored) |

**Do not store service-account JSON inside the clone**, even when gitignored. A forgotten `git add -f` or IDE “share folder” can leak a private key. Prefer a path such as `~/secrets/…` and export:

```bash
export GOOGLE_APPLICATION_CREDENTIALS="$HOME/secrets/worldcup-pool-tracker-app.json"
```

`.gitignore` also blocks Google’s default download name (`*firebase-adminsdk*.json`) and `docs/worldcup-pool-tracker-app.json` as a safety net only.

Verify before push:

```bash
git ls-files '*firebase-adminsdk*' docs/worldcup-pool-tracker-app.json   # must be empty
git log -S "BEGIN PRIVATE KEY" --oneline            # must be empty of real keys
```

## Firebase client API keys

`lib/firebase_options.dart`, `google-services.json` and `GoogleService-Info.plist`
contain **client** API keys. They are expected in mobile repos but must be paired with:

### 1. API key restrictions (Google Cloud Console)

1. Open [Google Cloud Console → APIs & Services → Credentials](https://console.cloud.google.com/apis/credentials)
2. Select project `worldcup-pool-tracker-app`
3. For each Android/iOS API key:
   - **Application restrictions**: Android apps → package `com.example.worldcupbettracker_app` + SHA-1; iOS → bundle ID `com.example.worldcupbettrackerApp`
   - **API restrictions**: limit to Firebase-related APIs (Identity Toolkit, FCM, etc.)

### 2. Firebase App Check

1. [Firebase Console → App Check](https://console.firebase.google.com/project/worldcup-pool-tracker-app/appcheck)
2. Register **Play Integrity** (Android) and **App Attest / DeviceCheck** (iOS)
3. Enforce App Check on **Cloud Firestore** once apps send tokens

Until App Check is enforced in the app, API key restrictions are the main line of defense.

## Firestore rules

Settlement fields (`winnerUids`, `basePotCents`, `totalPotCents`, `closeoutAt`,
`perfectScoresCount`, `carryOverPotCents`) are **server-only** — clients cannot forge results.

`groups/{groupId}` is **get-by-id, not listable**:

| Operation | Who |
|-----------|-----|
| `get` | any signed-in user (needed to validate an invite code before join) |
| `list` | denied — a clone of this repo cannot dump every bolão |

Predictions, debts, and members stay `isGroupMember`. Cloud Functions use the Admin SDK and are unaffected.

Deploy after changing `firestore.rules` (production **and** demo):

```bash
firebase deploy --only firestore:rules --project worldcup-pool-tracker-app
firebase deploy --only firestore:rules --project copabolaao-demo
```

## Public clone vs production data

Committed FlutterFire files (`lib/firebase_options.dart`, `google-services.json`,
`GoogleService-Info.plist`) are the **production** client config. That is expected
for a mobile repo, but a public clone can register on production Auth.

Before flipping the GitHub repo to public:

- [ ] Restrict production API keys (section above) **or** turn off new Email/Password
      registrations on `worldcup-pool-tracker-app` if you only need existing friends
- [ ] Default portfolio installables to `--flavor demo` / `copabolaao-demo` (see [`demo_apk.md`](demo_apk.md))
- [ ] Do **not** attach a production APK to GitHub Releases
- [ ] App Check remains optional until the Dart app sends tokens; key restrictions first

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
