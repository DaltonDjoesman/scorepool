# CopaBolão 2026

[![Flutter CI](https://github.com/DaltonDjoesman/worldcup-pool-tracker-app/actions/workflows/flutter-ci.yml/badge.svg)](https://github.com/DaltonDjoesman/worldcup-pool-tracker-app/actions/workflows/flutter-ci.yml)

> A full-stack mobile app for running an exact-score betting pool with friends and family during the 2026 FIFA World Cup.

Built as a personal / portfolio project to learn end-to-end Flutter, Firebase, TypeScript backend logic, and real-time NoSQL modelling — and used by a real group of friends.

**Languages:** in-app UI copy is **Portuguese**; documentation in this repository is **English**.

---

## What it does

Friends join a group and bet on the **exact final score** of selected World Cup matches. Only a perfect guess wins the pot. If nobody guesses right, the pot rolls over to the next match (snowball effect). No money moves inside the app — winners are auto-calculated by the backend and losers self-declare payment on a public ledger that every group member can see in real time.

Key rules:
- **Exact score only** — guessing the correct winner is not enough.
- **Multiple winners** split the pot equally; each loser pays their individual share to each winner.
- **Zero winners** → full pot carries over to the next group match.
- **Participation is independent of prediction** — you can be in the pot without guessing a score (opt-out by the lock deadline to skip a round).
- **Prediction lock** — 15 minutes before kickoff; opt-out deadline is the same.
- **"I've paid" ledger** — public, live, grouped: pending first, declared-paid second.

---

## Why I built this

I'm a Computer Engineering student and I wanted a real-world project to put theory into practice — not a todo-list tutorial, but something with actual domain complexity, external integrations, and real usage pressure (people actually used it).

Specific things I wanted to learn:
- Designing a production-grade Flutter app with a clean layered architecture
- Modelling a relational-ish domain (groups, rounds, debts, carryover) on top of a NoSQL database
- Writing server-side business rules in TypeScript that the client cannot bypass
- Consuming an external API server-side to stay within free-tier quotas
- Thinking about security: Firestore rules that enforce time windows and ownership

---

## Tech stack

| Layer | Technology | Role |
|---|---|---|
| Mobile app | Flutter / Dart | Android & iOS |
| Navigation | go_router | Declarative routing |
| Auth | Firebase Auth | Email/password |
| Database | Cloud Firestore | Real-time NoSQL; live payment ledger |
| Live ops (Spark) | GitHub Actions + Admin SDK scripts | Match catalog ingest, closeout / carry-over backfill |
| Backend code | TypeScript under `functions/` | Same domain logic; deployable as Cloud Functions on Blaze |
| Push | Firebase Cloud Messaging | Client stores FCM tokens; push *dispatch* needs deployed Functions |
| Match data | football-data.org API *(server-side only)* | Schedule, scores, team crests |
| Security | Firestore Security Rules | Server-enforced ownership and time-window rules |
| UI prototype | React (inline Babel) + CSS | Interactive HTML mockup used before Flutter |

---

## Architecture

```
┌──────────────────────────────────────────┐
│  Flutter app  (Android / iOS)            │
│  · firebase_auth · cloud_firestore       │
│  · firebase_messaging (token persist)    │
│  · go_router · repositories · screens    │
└───────────────────┬──────────────────────┘
                    │  real-time listeners + writes
┌───────────────────▼──────────────────────┐
│  Cloud Firestore                         │
│  · tournaments/{id}/matches (global)     │
│  · groups / members                      │
│  · groups/{id}/matches (group overlay)   │
│  · predictions / roundParticipants       │
│  · debts (payment ledger per match)      │
└───────────────────┬──────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────────┐   ┌───────────────────┐
│  GitHub Actions   │   │  functions/ (TS)  │
│  (live on Spark)  │   │  deployable path  │
│  · ingest catalog │   │  · same modules   │
│  · closeout       │   │  · optional CF    │
│    backfill       │   │    on Blaze       │
└─────────┬─────────┘   └─────────┬─────────┘
          └───────────┬───────────┘
                      ▼
┌──────────────────────────────────────────┐
│  football-data.org API                   │
│  (server-side only; results cached in    │
│   Firestore to stay within free tier)    │
└──────────────────────────────────────────┘
```

More detail: [`docs/architecture.md`](docs/architecture.md).

---

## Screenshots

Captured with `flutter run --dart-define=SCREENSHOT_DEMO=true` (see [`docs/screenshots/README.md`](docs/screenshots/README.md)). Gallery uses a **fixed width** so phone-framed shots stay aligned; taller scroll captures (match details / ledger) sit on their own rows.

<p align="center">
  <img src="docs/screenshots/01-login.png" width="180" alt="Login"/>
  <img src="docs/screenshots/02-feed.png" width="180" alt="Match feed"/>
  <img src="docs/screenshots/05-ranking.png" width="180" alt="Ranking"/>
</p>
<p align="center"><em>Login · Feed (Próximos) · Ranking</em></p>

<p align="center">
  <img src="docs/screenshots/06-group-hub.png" width="180" alt="Group hub"/>
  <img src="docs/screenshots/07-create-group.png" width="180" alt="Create group"/>
</p>
<p align="center"><em>Group hub · Create group (48 WC2026 teams)</em></p>

<p align="center">
  <img src="docs/screenshots/03-prediction.png" width="220" alt="Live match details"/>
  <img src="docs/screenshots/04-ledger.png" width="220" alt="Payment ledger"/>
</p>
<p align="center"><em>Live match (locked predictions) · Finished match + payment ledger</em></p>

---

## Engineering highlights

**Pot math in integer cents** — all monetary amounts are stored and computed as integer cents (e.g. `200` for €2.00) to avoid floating-point drift. When the pot doesn't divide evenly across winners, the remainder is assigned deterministically to the first winner by stable sort so totals always balance exactly.

**Carry-over resilient to filter changes** — instead of chaining "nextMatchId" references (which break when a filter change removes a match), the group document holds a single `carryOverPot` field. It accumulates when a round ends with no winners and is applied to the next eligible group match when that match is activated. Filter changes can't corrupt the carry-over balance.

**Match filter as a set union** — a match enters a group if:
`homeTeamId ∈ selectedTeams OR awayTeamId ∈ selectedTeams OR stage ∈ selectedStages`
This lets groups follow specific national teams and also always include knockout rounds regardless of teams.

**Updating the filter without breaking history** — when an admin edits the filter, future unstarted matches can be added or soft-removed (`excludedByFilter: true`). Matches that are live, finished, or past prediction lock are never removed — their financial history is immutable.

**Server-enforced time windows** — prediction lock, opt-out deadline, and "paid" declaration deadline are enforced by Firestore Security Rules (and server scripts for settlement). The client never has authority over these timestamps.

---

## App screens

| Screen | Description |
|---|---|
| Login | Email/password sign-in and register |
| Groups | Create a group (currency, entry fee, match filter); join via code |
| Match feed | Tabs: Upcoming · Live · Finished; accumulated pot banner on rollover matches |
| Prediction input | Score input with live countdown to lock; opt-out toggle |
| Live match | Read-only view of all locked predictions ("secar palpites") |
| Match details | Final score, pot breakdown, winners |
| Payment ledger | Public debt list — pending first; "Já paguei" action per debt |
| Ranking | Perfect-score leaderboard; podium for top 3 |

> **Interactive prototype** — before building in Flutter, I designed all screens as a single-file React prototype. Open [`worldcup-bet-tracker.html`](worldcup-bet-tracker.html) in a browser to explore it.

---

## How this was built

Work was specified and delivered with [OpenSpec](openspec/): capability specs under [`openspec/specs/`](openspec/specs/), change proposals under `openspec/changes/` (completed ones archived), and a section → branch → PR workflow described in [`openspec/delivery.md`](openspec/delivery.md).

---

## Running locally

### Prerequisites

- Flutter SDK `>=3.11`
- Node.js 20 (for ingest / Functions scripts)
- A Firebase project with Firestore and Auth enabled

See [`docs/firebase_setup.md`](docs/firebase_setup.md) for Firebase configuration. Before making this repository **public**, complete [`docs/security.md`](docs/security.md).

### Flutter app

```bash
flutter pub get
flutter run                                     # production Firebase
flutter run --dart-define=APP_ENV=dev           # same project today; reserved for a future dual-env setup
flutter run --dart-define=FIREBASE_ENABLED=false # widget tests, no Firebase
```

### Backend scripts (`functions/`)

```bash
cd functions
npm install
npm run build

# Ingest the WC 2026 match catalog into Firestore
npm run ingest:wc2026

# Run local scripts
npm run test:pot            # pot math unit tests
npm run test:reconciliation # group filter reconciliation tests
```

---

## Contributing

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for setup, analyze/test, and PR expectations.

---

## Project status

Portfolio project with real-group usage during the 2026 World Cup cycle. Not a commercial product — documented honestly for recruiters and collaborators.

---

## AI assistance

This project was built with the help of AI tools — specifically [Cursor](https://cursor.com) (AI-powered IDE) and [Gemini](https://gemini.google.com). They were used for code generation, architecture discussion, debugging, and documentation.

All decisions about what to build, how to structure it, and what trade-offs to make were mine. The AI acted as a pair-programmer and sounding board, not as the author. I reviewed, understood, and took responsibility for every piece of code that ended up in the project.

I'm including this note because I think honesty about tooling matters — the same way you'd cite a library or a Stack Overflow answer.

## License

[MIT](LICENSE)
