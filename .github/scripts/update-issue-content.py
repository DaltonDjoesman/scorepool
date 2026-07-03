#!/usr/bin/env python3
"""Update GitHub issues with self-contained titles and bodies (no openspec refs)."""
import argparse
import subprocess
import tempfile
import os

REPO = "DaltonDjoesman/worldcup-pool-tracker-app"

# (issue_number, title, body)
ISSUES = [
    (2, "Create Flutter app scaffold with Android+iOS targets", """## Goal
Bootstrap the mobile app for Android and iOS using Flutter.

## What to do
- Create the Flutter project with Android and iOS targets enabled
- Establish a clear folder structure (`lib/`, screens, services, models)
- Ensure both platforms build successfully from a clean checkout

## Done when
- `flutter build apk` and `flutter build ios` (or simulator build) succeed
- App launches on both platforms with a minimal entry point"""),

    (3, "Add Firebase dependencies and configure Android/iOS", """## Goal
Wire Firebase into the Flutter app for Auth, Firestore, and Cloud Messaging.

## What to do
- Add Firebase packages to `pubspec.yaml` (core, auth, firestore, messaging)
- Place and configure `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
- Initialize Firebase before the app runs

## Done when
- Firebase initializes without errors on startup on both platforms
- Native build configs reference the correct Firebase project files"""),

    (4, "Define environment and config strategy", """## Goal
Decide how the app targets dev vs production Firebase (or a single project with safe separation).

## What to do
- Choose approach: separate Firebase projects, flavors, or build-time config
- Document how developers switch environments locally
- Avoid manual file swapping for routine development

## Done when
- Strategy is documented in the repo
- App can be built/run against the intended environment without ad-hoc edits"""),

    (5, "Add basic app navigation skeleton", """## Goal
Provide the main navigation flow the product needs before feature screens are built.

## What to do
- Implement routes for: login → group selection → match feed → match details → ranking
- Add placeholder screens for each route so navigation can be tested end-to-end

## Done when
- User can navigate through all main screens in order
- Navigation pattern is consistent (e.g. go_router or equivalent)"""),

    (6, "Define Firestore collections and document shapes", """## Goal
Model all bolão data in Firestore with a group-centric structure.

## What to do
Define documents and fields for:
- **Global catalog** (backend-only writes): `tournaments/wc2026/matches/{matchId}` — teams, stage, UTC kickoff, status, scores
- **Groups**: `groups/{groupId}` — name, currency, entryFee, lockMinutes, matchFilter, carryOverPot
- **Members**: `groups/{groupId}/members/{uid}` — role, displayName, photoUrl
- **Group match overlay**: `groups/{groupId}/matches/{matchId}` — pot state, winners, excludedByFilter, accumulatedFromPrevious
- **Round participation**: `groups/{groupId}/roundParticipants/{matchId}/users/{uid}` — isInPot, optedOutAt
- **Predictions**: `groups/{groupId}/predictions/{uid_matchId}` — predicted scores (nullable)
- **Debts**: `groups/{groupId}/debts/{matchId}/items/{fromUid_toUid}` — fromUid, toUid, amount, status, declaredPaidAt

## Done when
- Typed Dart models exist for each collection
- Field names and types are stable enough for repositories and security rules"""),

    (7, "Implement repository layer with typed models", """## Goal
Centralize Firestore access in repositories with serialization.

## What to do
- Create repositories for groups, members, matches, predictions, participation, and debts
- Map Firestore snapshots to typed models and back
- Handle null/missing fields safely

## Done when
- UI layer can read/write group data through repositories only
- Models round-trip correctly against real Firestore documents"""),

    (8, "Create Firestore composite indexes for feed queries", """## Goal
Support efficient match feed queries without runtime index errors.

## What to do
- Identify queries used by the feed (filter by group, matchTime, status, excludedByFilter)
- Add required composite indexes to `firestore.indexes.json`
- Deploy indexes to Firebase

## Done when
- Feed queries execute without "index required" errors in the console
- Index file is committed and deployable"""),

    (9, "Firestore rules for group membership access control", """## Goal
Only group members may access that group's data.

## What to do
- Write rules so `groups/{groupId}/**` reads/writes require membership in that group
- Deny anonymous and non-member access
- Allow admins vs members only where business rules require it

## Done when
- Non-members cannot read or write group subcollections
- Members can access permitted documents for their groups"""),

    (10, "Enforce prediction edit rules (own prediction, before lock)", """## Goal
Users may only edit their own predictions, and only before lock time.

## Context
Lock time = `matchTime - predictionLockMinutes` (e.g. 15 minutes before kickoff).

## What to do
- Reject writes to another user's prediction document
- Reject create/update when current server time is at or after lock time
- Enforce in Firestore rules and/or a callable Cloud Function gate

## Done when
- User A cannot change User B's prediction
- Prediction writes fail after lock, succeed before lock"""),

    (11, "Enforce opt-out only before lock", """## Goal
Users may leave the pot for a match only until lock time.

## Context
Default: every member is `isInPot=true`. Opt-out sets `isInPot=false` for that match only.

## What to do
- Allow `isInPot` toggle to false only before `matchTime - lockMinutes`
- Reject opt-out attempts at or after lock
- Enforce server-side (rules or function), not client-only

## Done when
- Opt-out works before lock and is rejected after lock"""),

    (12, "Enforce declare paid only before kickoff", """## Goal
Users may mark their own debts as paid only until match kickoff.

## Context
Payment is social/declarative — no real money in the app. Each debt is `fromUid → toUid` with an amount.

## What to do
- Only `fromUid` may set `status=paid` on their debt items
- Reject paid declarations at or after `matchTime`
- Enforce in rules or callable function

## Done when
- User can mark own debts paid before kickoff
- Same action fails at or after kickoff; users cannot mark others' debts"""),

    (13, "Firebase Auth email and password sign-in", """## Goal
Users can register and sign in with email/password with a persistent session.

## What to do
- Build sign-up and sign-in screens
- Handle auth errors (invalid email, weak password, wrong credentials)
- Persist session so returning users stay logged in

## Done when
- New user can register and land in the app
- Existing user can sign in and session survives app restart"""),

    (14, "Social sign-in and member profile on join", """## Goal
Support Google sign-in (all platforms) and Apple sign-in (iOS); sync profile into group membership.

## What to do
- Integrate Google Sign-In on Android and iOS
- Integrate Sign in with Apple on iOS
- On joining a group, create/update `groups/{groupId}/members/{uid}` with name and photo from the auth provider

## Done when
- Google login works on both platforms
- Apple login works on iOS
- Member document reflects provider display name and avatar"""),

    (15, "Display user profile fields in UI lists", """## Goal
Show member identity consistently across the app.

## What to do
- Read displayName and photoUrl from member documents
- Show avatar + name in participant lists, ranking, ledger, and prediction views
- Provide sensible fallback when photo is missing (initials or placeholder)

## Done when
- All list UIs show correct names and photos for group members"""),

    (16, "Build create group flow", """## Goal
Let a user create a new bolão group with core settings.

## What to do
- Form fields: group name, currency (e.g. BRL), entry fee per match, prediction lock minutes (default 15)
- On submit: create group document and assign creator as admin member
- Navigate to the new group after creation

## Done when
- Valid submission creates a group in Firestore
- Creator is admin; invalid input shows clear errors"""),

    (17, "Match filter selection UI (teams and stages)", """## Goal
Let admins choose which World Cup matches belong to the group's bolão.

## Filter logic
A match is included if **any** of:
- Home team is in selected teams, OR
- Away team is in selected teams, OR
- Match stage is in selected stages (e.g. Semi-final, Final — regardless of teams)

## What to do
- Searchable team picker with multi-select chips
- Stage multi-select (group stage, round of 16, quarters, semis, final, etc.)

## Done when
- Admin can select teams and/or stages intuitively
- Selection state is clear before saving"""),

    (18, "Persist match filter and show included match count", """## Goal
Save filter settings and give immediate feedback on how many matches match.

## What to do
- Persist `matchFilter` (teamIds, stages) on the group document
- After save (or live preview), show summary like "42 matches included"
- Count should reflect union logic (teams OR stages)

## Done when
- Filter is stored in Firestore
- UI shows accurate match count for current filter"""),

    (19, "Edit group filter screen (admin only)", """## Goal
Allow admins to change which matches the group tracks after creation.

## What to do
- Edit-filter screen reuses team/stage picker from create flow
- Restrict access to users with admin role
- Non-admins see denied state or no entry point

## Done when
- Only admins can open and save filter changes
- Changes trigger reconciliation (separate backend tasks)"""),

    (20, "Global match catalog Firestore structure", """## Goal
Store World Cup 2026 matches in a shared, backend-managed catalog.

## What to do
- Structure: `tournaments/wc2026/matches/{matchId}`
- Fields: matchId, homeTeamId, awayTeamId, stage, matchTime (UTC), status, homeScore, awayScore, team names/flags as needed
- Only server/ingestion jobs may write; clients read only

## Done when
- Schema is defined and documented in code
- Sample documents validate against the model"""),

    (21, "football-data.org ingestion job with caching and retry", """## Goal
Keep the global WC2026 match catalog up to date from football-data.org without burning API quota.

## What to do
- Scheduled job (GitHub Actions every 5 min + optional Cloud Function) fetches WC2026 fixtures via `GET /v4/competitions/WC/matches?season=2026`
- Use `FOOTBALL_DATA_TOKEN`; map fields to Firestore `tournaments/wc2026/matches/{matchId}`
- Retry on transient failures; fail loudly on auth/API errors

## Done when
- Job runs on a schedule and upserts ~104 matches reliably
- Failures are logged and retried; quota usage stays within free-tier limits"""),

    (22, "Idempotent catalog upserts on updates", """## Goal
Re-running ingestion must not duplicate or corrupt match data.

## What to do
- Upsert by stable football-data.org `matchId`
- Update status and scores in place when matches progress
- Preserve canonical team IDs (TLA codes) across updates

## Done when
- Multiple ingestion runs produce one document per match
- Finished matches show correct final scores and status"""),

    (23, "Reconciliation on filter update — add future matches", """## Goal
When a group's filter changes, newly matching future matches appear in the group.

## What to do
- Trigger reconciliation on filter save (Cloud Function or backend job)
- For each newly included scheduled match, create/activate `groups/{groupId}/matches/{matchId}` overlay
- Initialize participation defaults for new matches

## Done when
- Adding Brazil to team filter creates overlay docs for upcoming Brazil matches
- Only future/not-yet-locked matches are added automatically"""),

    (24, "Soft-exclude pre-lock matches; keep post-lock history", """## Goal
Filter removals must not break financial/social history for matches already in play.

## What to do
- Matches still before lock and not live: set `excludedByFilter=true` (soft hide)
- Matches past lock, live, or finished: **never** remove — keep in group history
- Set `lockedInGroup` when match passes lock or leaves scheduled status

## Done when
- Pre-lock excluded matches disappear from active feed but data remains
- Locked/finished matches stay regardless of filter changes"""),

    (25, "Archived view for excluded matches", """## Goal
Members can still see matches removed by filter change.

## What to do
- Primary feed hides `excludedByFilter=true` matches
- Add "Archived" tab or screen listing soft-excluded matches
- Read-only history view for auditability

## Done when
- Default feed shows only active included matches
- Archived view lists excluded matches with basic match info"""),

    (26, "Default round participation (isInPot=true)", """## Goal
Every group member participates in the pot by default for each included match.

## What to do
- When a match is added to a group, create participation docs for all members with `isInPot=true`
- Store at `groups/{groupId}/roundParticipants/{matchId}/users/{uid}`

## Business rule
Who doesn't submit a prediction still pays into the pot unless they opt out.

## Done when
- New included match has participation records for every member
- Default is always in the pot"""),

    (27, "Opt-out toggle UI (before lock only)", """## Goal
Let users skip paying into a specific match's pot if they won't participate.

## What to do
- Toggle on match screen: "Participate in pot" / opt-out
- Only enabled before lock time
- Updates `isInPot=false` and records `optedOutAt`

## Done when
- User can opt out before lock; toggle disabled after lock
- UI clearly shows current participation status"""),

    (28, "Opt-out scoped to single match in match details", """## Goal
Opt-out affects one match only and is visible where it matters.

## What to do
- Ensure opt-out on match A does not change participation on match B
- Show participation badge/state on match details screen

## Done when
- Opt-out is isolated per match
- Match details clearly shows in-pot vs opted-out for current user"""),

    (29, "Prediction input UI (including empty state)", """## Goal
Users can submit an exact-score prediction or deliberately leave it blank.

## What to do
- Score inputs for home and away on scheduled matches
- Allow empty/null prediction — user remains in pot if `isInPot=true`
- Validate non-negative integers when provided

## Done when
- User can save a score prediction or clear it
- Empty prediction does not remove them from the pot"""),

    (30, "Countdown and lock indicator with disabled inputs at lock", """## Goal
Make lock timing obvious and prevent edits after cutoff.

## What to do
- Show countdown until lock (e.g. "Locks in 12m 34s")
- Disable prediction inputs and opt-out when locked
- Visual state change at lock (greyed out, message)

## Done when
- Countdown is accurate to match kickoff minus lock minutes
- All edit controls disabled at and after lock"""),

    (31, "Persist predictions per user per match per group", """## Goal
One canonical prediction record per (groupId, uid, matchId).

## What to do
- Document ID or composite key ensures uniqueness
- Second save updates existing record (no duplicates)
- Store predictedHomeScore and predictedAwayScore (nullable)

## Done when
- Each user has at most one prediction per match in a group
- Updates overwrite prior values correctly"""),

    (32, "carryOverPot and deterministic cent rounding", """## Goal
Support pot accumulation across matches with exact money math.

## What to do
- Add `carryOverPot` (integer cents) on group document
- Define rounding: all amounts in minor currency units (cents)
- When splitting pot among winners, remainder goes to first winner by stable sort (e.g. uid ascending) so totals always balance

## Done when
- Group model includes carryOverPot
- Rounding helper is implemented and unit-tested for edge cases"""),

    (33, "Closeout: compute basePot from in-pot participants", """## Goal
Calculate how much money is in the pot when a match ends.

## Formula
`basePot = entryFee × count(participants where isInPot=true)`

## What to do
- Run as part of server-side closeout when global catalog marks match finished
- Include users with no prediction if they are still `isInPot=true`
- Add any `accumulatedFromPrevious` from prior carryover

## Done when
- basePot and totalPot are computed correctly for mixed participation"""),

    (34, "Closeout: determine winners by exact score", """## Goal
Only exact score predictions win — correct winner/outcome is not enough.

## What to do
- Compare each prediction to final homeScore/awayScore
- User must have submitted a prediction to win
- Build `winners[]` list of uids with exact match

## Examples
- Final 2–1, predicted 2–1 → winner
- Final 2–1, predicted 1–0 → not a winner

## Done when
- Winners list contains only exact-score matches with predictions"""),

    (35, "Closeout: set winners and generate debts", """## Goal
Distribute the pot via a clear who-pays-whom ledger when there are winners.

## What to do
- Store winners on group match document
- For each in-pot non-winner, create debts to each winner
- Debt amount: loser's share split equally across winners (in cents, deterministic remainder)
- Document path: `groups/{groupId}/debts/{matchId}/items/{fromUid_toUid}`

## Done when
- 2 winners + 3 losers → 6 debt items with correct amounts
- Sum of all debts equals total owed by losers"""),

    (36, "Closeout: no winners adds pot to carryOverPot", """## Goal
If nobody hits the exact score, the full pot rolls to the next match.

## What to do
- When `winners[]` is empty after closeout: `carryOverPot += totalPot`
- Mark match as closed with zero winners
- No debts generated for that round

## Done when
- Zero-winner match increases group carryOverPot by full totalPot
- Match state reflects no winners clearly in UI data"""),

    (37, "Apply carryover to next eligible group match", """## Goal
Accumulated pot attaches to the next included match by kickoff time.

## What to do
- When preparing the next group match (by matchTime ascending), if `carryOverPot > 0`:
  - Set `accumulatedFromPrevious = carryOverPot` on that match overlay
  - Reset `carryOverPot` to 0 on the group
- Must work even if filter changed which match is "next"

## Done when
- Carryover appears on the correct next match
- Group carryOverPot is zero after application"""),

    (38, "Match details ledger view (pending first)", """## Goal
Public transparency on who owes whom for a finished match.

## What to do
- Ledger screen on match details showing all debts for that match
- Group by status: **pending first**, then paid
- Visible to all group members

## Done when
- Pending debts always appear above paid ones
- Each row shows payer, payee, amount, status"""),

    (39, "Mark as paid action with real-time update", """## Goal
Losers declare they paid winners before kickoff; everyone sees updates live.

## What to do
- "Mark as paid" button on debts where current user is `fromUid`
- Only available before match kickoff (`matchTime`)
- Firestore listener updates UI for all viewers in realtime

## Done when
- User can mark own debt paid before kickoff
- Button hidden/disabled after kickoff; status syncs live for the group"""),

    (40, "Display multiple winner debts (from → to)", """## Goal
Multiple winners mean each loser may owe several people — show that clearly.

## What to do
- When 2+ winners exist, each loser gets one debt row per winner
- Display: "You → Alice: R$ X" / "You → Bob: R$ Y"
- Avoid ambiguous combined rows

## Done when
- UI scales cleanly for 1, 2, or more winners
- Amounts per payee are explicit"""),

    (41, "Feed tabs for upcoming, live, and finished matches", """## Goal
Main screen organizes group matches by status.

## What to do
- Tabs or segments: Upcoming | Live | Finished
- Query group match overlay (not raw global catalog)
- Respect `excludedByFilter` — hide from primary tabs

## Done when
- Each tab shows correct matches for the active group
- Status transitions move matches between tabs as catalog updates"""),

    (42, "Live match: view all group predictions (read-only)", """## Goal
After lock, members can see what everyone predicted during the live match.

## What to do
- Read-only list of predictions from group members
- Show only after prediction lock (not before — avoids copy-paste cheating)
- No edit from this view

## Done when
- Live tab match detail shows all submitted predictions
- Empty predictions shown as "no prediction" but user may still be in pot"""),

    (43, "Finished match card with winners and accumulated pot", """## Goal
Make results and money story obvious at a glance.

## What to do
- Finished cards highlight winner name(s) and winning score
- Banner when pot included carryover: "Includes R$ X accumulated from previous matches"
- Link to ledger for payment status

## Done when
- Winners stand out visually on finished cards
- Accumulated pot amount visible when applicable"""),

    (44, "Increment perfectScoresCount at closeout", """## Goal
Track how many exact-score wins each member has for ranking.

## What to do
- On closeout, for each uid in `winners[]`, increment `perfectScoresCount` on their member doc (or group stats subdoc)
- Increment by 1 per winning match (not per debt)

## Done when
- Winner's count increases automatically when match closes
- Non-winners unchanged"""),

    (45, "Ranking screen with deterministic tie-break", """## Goal
Leaderboard by number of perfect-score wins.

## What to do
- Sort members by `perfectScoresCount` descending
- Tie-break deterministically (e.g. displayName alphabetical, then uid)
- Show rank, name, avatar, count

## Done when
- Ranking updates after matches close
- Ties never flicker or reorder randomly"""),

    (46, "Configure FCM for Android and APNs for iOS", """## Goal
Enable push notifications on both mobile platforms.

## What to do
- Android: Firebase Cloud Messaging setup, notification channel, permission handling
- iOS: APNs key/cert in Firebase, request notification permission, handle token registration
- Store FCM tokens per user/device as needed for targeting

## Done when
- Test push reaches a device on Android and iOS
- App handles foreground/background notification display"""),

    (47, "Notifications for lock, kickoff, and accumulated pot", """## Goal
Proactively remind users of key moments.

## Notifications to send
- **Lock warning**: ~15 minutes before prediction lock
- **Kickoff**: match is starting
- **Accumulated pot**: next match has carryover from previous rounds (bola de neve effect)

## What to do
- Server-side scheduling (Cloud Functions + FCM) based on match times
- Respect user notification preferences if implemented

## Done when
- Each notification type fires in a test scenario
- Users receive relevant alerts at the right time"""),

    (48, "Unit tests for pot and debt computation", """## Goal
Verify money logic is correct and regression-safe.

## Test cases
- Single winner takes full pot
- Two winners split equally
- Rounding remainder assigned deterministically (no lost cents)
- Zero winners → full pot to carryOverPot
- Multiple losers × multiple winners → correct debt matrix and totals

## Done when
- Unit test suite covers above scenarios and passes in CI"""),

    (49, "Integration tests for time window enforcement", """## Goal
Verify server rules reject out-of-window actions.

## Test cases
- Prediction write after lock → rejected
- Opt-out after lock → rejected
- Mark paid at or after kickoff → rejected
- Valid actions before deadlines → accepted

## Done when
- Integration or rules tests run against emulator or test project
- All window violations fail as expected"""),

    (50, "Validate Android and iOS on devices or emulators", """## Goal
Smoke-test the full app on real targets before release.

## Checklist
- Email and social auth flows
- Create group, set filter, see feed
- Submit prediction, opt-out, view ledger
- Firestore realtime updates visible across two clients
- Push notifications on both platforms

## Done when
- Checklist passed on Android (device or emulator)
- Checklist passed on iOS (device or simulator)
- Blockers filed as separate issues if found"""),
]


LABELS = {
    2: "P0,frontend",
    3: "P0,frontend,firebase",
    4: "P0,firebase,devops",
    5: "P0,frontend",
    6: "P0,firebase,backend",
    7: "P0,frontend,firebase",
    8: "P0,firebase",
    9: "P0,security,firebase",
    10: "P0,security,firebase",
    11: "P0,security,firebase",
    12: "P0,security,firebase",
    13: "P0,frontend,firebase",
    14: "P0,frontend,firebase",
    15: "P0,frontend",
    16: "P0,frontend",
    17: "P0,frontend",
    18: "P0,frontend,firebase",
    19: "P0,frontend",
    20: "P1,backend,firebase",
    21: "P1,backend,devops",
    22: "P1,backend,firebase",
    23: "P1,backend",
    24: "P1,backend,firebase",
    25: "P1,frontend",
    26: "P1,backend,firebase",
    27: "P1,frontend",
    28: "P1,frontend",
    29: "P1,frontend",
    30: "P1,frontend",
    31: "P1,frontend,firebase",
    32: "P1,backend",
    33: "P1,backend",
    34: "P1,backend",
    35: "P1,backend",
    36: "P1,backend",
    37: "P1,backend",
    38: "P2,frontend",
    39: "P2,frontend,firebase",
    40: "P2,frontend",
    41: "P2,frontend",
    42: "P2,frontend",
    43: "P2,frontend",
    44: "P2,backend",
    45: "P2,frontend",
    46: "P2,frontend,devops",
    47: "P2,backend,firebase",
    48: "P2,backend",
    49: "P2,backend,security",
    50: "P2,frontend,devops",
}


def create_issue(title: str, body: str, labels: str) -> None:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(body)
        body_path = f.name
    try:
        subprocess.run(
            [
                "gh", "issue", "create",
                "--repo", REPO,
                "--title", title,
                "--body-file", body_path,
                "--assignee", "DaltonDjoesman",
                "--label", labels,
            ],
            check=True,
        )
        print(f"✓ created: {title}")
    finally:
        os.unlink(body_path)


def edit_issue(number: int, title: str, body: str) -> None:
    with tempfile.NamedTemporaryFile(mode="w", suffix=".md", delete=False) as f:
        f.write(body)
        body_path = f.name
    try:
        subprocess.run(
            [
                "gh", "issue", "edit", str(number),
                "--repo", REPO,
                "--title", title,
                "--body-file", body_path,
            ],
            check=True,
            capture_output=True,
            text=True,
        )
        print(f"✓ #{number} {title}")
    except subprocess.CalledProcessError as e:
        print(f"✗ #{number} failed: {e.stderr}")
        raise
    finally:
        os.unlink(body_path)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--create", action="store_true", help="Create new issues")
    args = parser.parse_args()

    if args.create:
        for number, title, body in ISSUES:
            create_issue(title, body, LABELS[number])
        print(f"\nCreated {len(ISSUES)} issues.")
    else:
        for number, title, body in ISSUES:
            edit_issue(number, title, body)
        print(f"\nUpdated {len(ISSUES)} issues.")


if __name__ == "__main__":
    main()
