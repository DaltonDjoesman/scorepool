## 1. Project & Firebase Setup
> GitHub issues: #2, #3, #4, #5

- [x] 1.1 Create Flutter app scaffold with Android+iOS targets
- [x] 1.2 Add Firebase dependencies (Auth, Firestore, Messaging) and configure Android/iOS projects
- [x] 1.3 Define environment/config strategy (dev/prod Firebase projects or a single project with clear separation)
- [x] 1.4 Add basic app navigation skeleton (login → group → feed → match details → ranking)

## 2. Firestore Data Model (Group-Centric)
> GitHub issues: #6, #7, #8

- [x] 2.1 Define Firestore collections and document shapes for `groups`, `members`, `matches` (group overlay), `roundParticipants`, `predictions`, `debts`
- [x] 2.2 Implement repository layer in Flutter (read/write) with typed models and serialization
- [x] 2.3 Create Firestore composite indexes needed for feed queries (by groupId, matchTime, status, excludedByFilter)

## 3. Security Rules (Server Truth for Time Windows)
> GitHub issues: #9, #10, #11, #12

- [x] 3.1 Write Firestore security rules for group membership access control
- [x] 3.2 Enforce “only edit own prediction” and “prediction updates only before lock” in rules or via callable function gate
- [x] 3.3 Enforce “opt-out only before lock” in rules or via callable function gate
- [x] 3.4 Enforce “declare paid only for own debts and only before kickoff” in rules or via callable function gate

## 4. Auth & Profiles
> GitHub issues: #13, #14, #15

- [x] 4.1 Implement Firebase Auth sign-in (email/password) and persistent session
- [x] 4.2 Implement social sign-in (Google; Apple for iOS) and create/update member profile in `groups/{groupId}/members/{uid}`
- [x] 4.3 Implement user profile display fields (name/photo) consumption in UI lists

## 5. Group Creation & Match Filter UI
> GitHub issues: #16, #17, #18, #19

- [x] 5.1 Build “create group” flow (name, currency, entryFee, lock minutes)
- [x] 5.2 Build match filter selection UI: selectable teams (search + chips) and selectable stages
- [x] 5.3 Persist `matchFilter` to the group document and show a summary (“X jogos incluídos”)
- [x] 5.4 Implement “edit group filter” screen restricted to admins

## 6. Global Match Catalog Ingestion (Backend)
> GitHub issues: #20, #21, #22

- [x] 6.1 Create global Firestore structure for `tournaments/wc2026/matches/{matchId}` (teamIds, stage, matchTime UTC, status, scores, flags)
- [x] 6.2 Implement ingestion job for external football API (schedule + updates) with caching/retry and minimal quota usage _(provider migrated to football-data.org in change `football-data-org-ingestion`)_
- [x] 6.3 On catalog updates, publish match changes to Firestore (idempotent upserts)

## 7. Group Match Reconciliation (Filter → Group Matches)
> GitHub issues: #23, #24, #25

- [x] 7.1 Implement reconciliation function triggered by group filter updates to add newly included future matches
- [x] 7.2 Implement removal behavior: pre-lock matches can be soft-excluded; post-lock/live/finished cannot be removed
- [x] 7.3 Ensure excluded matches are hidden from primary feed but accessible in “archived” view

## 8. Round Participation (Default In-Pot + Opt-out)
> GitHub issues: #26, #27, #28

- [x] 8.1 Implement per-match participation docs defaulting all members to `isInPot=true` for included matches
- [x] 8.2 Implement opt-out toggle (allowed only before lock) and reflect in UI
- [x] 8.3 Ensure opt-out only affects one match and is visible in match details

## 9. Predictions (Optional + Locking)
> GitHub issues: #29, #30, #31

- [x] 9.1 Implement prediction input UI for scheduled matches (including empty prediction state)
- [x] 9.2 Implement countdown/lock indicator (“Tranca em…”) and disable inputs at lock
- [x] 9.3 Persist predictions as unique (groupId, uid, matchId) records

## 10. Pot, Winners, Accumulation (Backend Closeout)
> GitHub issues: #32, #33, #34, #35, #36, #37

- [x] 10.1 Add `carryOverPot` to group and define deterministic rounding in cents
- [x] 10.2 Implement closeout function triggered when a match becomes finished in catalog:
  - [x] 10.2.1 Compute basePot from `isInPot=true`
  - [x] 10.2.2 Determine winners by exact score
  - [x] 10.2.3 If winners exist: set group match winners and generate debts
  - [x] 10.2.4 If no winners: add totalPot to `carryOverPot`
- [x] 10.3 Implement carryover application to the next eligible included group match

## 11. Payment Ledger (“Já paguei”) UX
> GitHub issues: #38, #39, #40

- [x] 11.1 Build match details “ledger” view grouped by status (pending first, paid second)
- [x] 11.2 Implement “Já paguei” action per debt (allowed only before kickoff) and real-time update
- [x] 11.3 Ensure multiple winners are represented as multiple debts (from → to) and displayed clearly

## 12. Feed & Screens (Based on Prototype)
> GitHub issues: #41, #42, #43

- [ ] 12.1 Implement feed tabs (upcoming/live/finished) based on group matches overlay
- [ ] 12.2 Implement “ver palpites da galera” for live matches (read-only list of predictions)
- [ ] 12.3 Implement finished match card highlighting winners and accumulated pot banner

## 13. Ranking / Stats
> GitHub issues: #44, #45

- [ ] 13.1 Increment `perfectScoresCount` for winners at closeout
- [ ] 13.2 Build ranking screen sorted by perfectScoresCount with deterministic tie-break

## 14. Notifications
> GitHub issues: #46, #47

- [ ] 14.1 Configure FCM for Android and APNs/FCM for iOS
- [ ] 14.2 Implement notifications for “lock em 15 min”, “kickoff”, and “pote acumulado” (server-side scheduling strategy)

## 15. QA, Testability, and Release Readiness
> GitHub issues: #48, #49, #50

- [ ] 15.1 Add basic unit tests for pot/debt computation (rounding, multiple winners, no winners)
- [ ] 15.2 Add integration tests for time-window enforcement (prediction lock, opt-out, paid until kickoff)
- [ ] 15.3 Validate Android+iOS behavior (auth, Firestore realtime, notifications) on physical devices or emulators
