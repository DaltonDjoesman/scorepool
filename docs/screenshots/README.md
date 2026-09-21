# Screenshots

PNGs in this folder are linked from the root README gallery. Recapture with screenshot demo mode when UI changes.

## Expected filenames

| File | Screen |
|------|--------|
| `01-login.png` | Login (email/password) |
| `02-feed.png` | Match feed (Upcoming / Live / Finished) |
| `03-prediction.png` | Live match details with locked predictions + group list |
| `04-ledger.png` | Payment ledger ("Já paguei") — tall scroll capture; prefer native phone files over chat uploads |
| `05-ranking.png` | Ranking / podium |
| `06-group-hub.png` | Group hub (active group + join/create) |
| `07-create-group.png` | Create group — name/fee + all 48 WC2026 teams selectable |

### README layout tip

GitHub Markdown tables stretch every cell to the tallest image and look uneven. Prefer an HTML gallery with a **fixed `width`** (e.g. `width="180"`) so every phone shot shares the same column width; put taller scroll screenshots (ledger, full match details) on a separate row with a slightly larger width.

## Capture with screenshot demo mode

The World Cup catalog in production is finished, so live feeds would be empty. For portfolio shots, run an **in-memory** demo that does **not** write to Firebase:

```bash
flutter run --dart-define=SCREENSHOT_DEMO=true
# or: flutter run -d linux --dart-define=SCREENSHOT_DEMO=true
# or: flutter run -d chrome --dart-define=SCREENSHOT_DEMO=true
```

**Do not use `--release` or `--profile` with `SCREENSHOT_DEMO`.** The in-memory Firestore/Auth mocks crash in those modes (`MockPlatformInterfaceMixin is not intended for use in release builds`), so the app stays on a blank screen. Debug is fine for prints: the red DEBUG ribbon is turned off automatically in this flavor.

| Field | Value |
|-------|--------|
| Email | `ana@prints.demo` |
| Password | `demo123` (any password ≥ 6 characters also works) |

Suggested capture order:

1. **Login** — take `01-login.png` **before** submitting.
2. Sign in → feed opens on group `Friends Pool`.
3. **Feed** — `02-feed.png` on **Próximos** (final ESP–ARG); also check **Ao vivo** (ARG–ENG) and **Encerrados**.
4. Open the final card → **prediction** countdown → `03-prediction.png`.
5. Open finished SF ESP–FRA → ledger with pending + paid → `04-ledger.png`.
6. Bottom nav **Ranking** → podium + list → `05-ranking.png`.
7. Group hub (bolão ativo) → `06-group-hub.png`.
8. **+ Criar novo bolão** → scroll so the team grid shows several flags → `07-create-group.png` (all 48 WC2026 teams are in the picker).

The demo snapshot is **composed for screenshots**: real WC2026 knockout teams/scores where useful, with the timeline rewound so semis/final still look “in progress”. It is not a historical instant of the live bolão.

## Capture tips

- Prefer a consistent device frame (phone portrait).
- Use Portuguese UI as shipped.
- Avoid showing real friends’ emails or private group codes; the demo accounts above are throwaways.
