# Architecture

CopaBolão is a Flutter mobile client (Android / iOS) backed by Firebase Auth, Cloud Firestore, and server-side TypeScript for match catalog sync and pot settlement.

## Layers (Flutter)

```
lib/
  main.dart                 # bootstrap, AppConfig
  firebase_options.dart     # production client Firebase config
  firebase_options_demo.dart # public demo APK Firebase (copabolaao-demo)
  src/
    auth/                   # AuthController (email/password)
    app_state/              # session / selected group
    routing/                # go_router
    repositories/           # FirestoreClient + domain facades
    models/                 # typed domain objects
    screens/                # feature UI
    services/               # client helpers (e.g. reconciliation assist)
    notifications/          # FCM token persistence
    utils/                  # pot math, locks, crests, standings
    theme/, widgets/, config/, firestore/
```

**Flow:** UI widgets call repositories (and occasionally pure utils). Repositories talk to Firestore through a thin client. Settlement fields on matches/groups are server-only; clients cannot forge winners or pots (see `firestore.rules`).

State management is intentional and lightweight: `ChangeNotifier` for auth/session rather than a global DI framework.

## Backend runtime

Two paths share the same TypeScript modules under `functions/`:

| Path | When | Role |
|------|------|------|
| **GitHub Actions** (`.github/workflows/ingest-wc2026.yml`) | **Live on Firebase Spark** | Daily catalog ingest (06:00 UTC) + closeout backfill via Admin SDK scripts |
| **Cloud Functions** (`functions/src`) | Deployable on Blaze | Same logic as callable/scheduled Functions |

The client persists FCM tokens to the user profile. Push *dispatch* (kickoff reminders, etc.) requires deployed Functions (or another dispatcher) — not the Spark Actions path today.

External match data comes from **football-data.org**, called only from server scripts so API tokens never ship in the app.

## Data model (sketch)

- `tournaments/{tournamentId}/matches/{matchId}` — global catalog
- `groups/{groupId}` — settings, filter, `carryOverPot`
- `groups/{groupId}/matches/{matchId}` — per-group overlay (inclusion, settlement, pots)
- `predictions`, `roundParticipants`, `debts` — round gameplay and payment ledger

## Security

Time windows (prediction lock, opt-out, declare-paid) and ownership are enforced in Firestore Security Rules. Settlement writes are Admin/server only. Checklist: [`security.md`](security.md).

## Design archaeology

[`worldcup-bet-tracker.html`](../worldcup-bet-tracker.html) is the single-file React prototype used to lock UX before Flutter implementation.
