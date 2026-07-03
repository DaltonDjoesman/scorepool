## 1. Design system foundation

- [x] 1.1 Add `google_fonts` dependency and create `lib/src/theme/app_theme.dart` with dark ColorScheme, accent/gold/danger/success tokens from HTML prototype
- [x] 1.2 Create `lib/src/theme/app_text_styles.dart` (headline, title-caps, sub, body) using Outfit + Plus Jakarta Sans
- [x] 1.3 Create shared widgets: `AppCard`, `AppButton`, `AppButtonOutline`, `AppTextField`, `StatusBadge`, `MatchStatusBadge`, `AlertBox`
- [x] 1.4 Create `MoneyFormat` helper and `TeamFlag` widget with team-id → asset mapping (reuse/extend `tournament_team_picker.dart`)
- [x] 1.5 Wire `AppTheme` into `WorldCupBetTrackerApp` replacing default Material teal seed theme
- [x] 1.6 Add `AppToast` / scaffold messenger helper for success/error feedback matching prototype toast

## 2. Navigation shell

- [x] 2.1 Create `FeedShellScreen` with bottom navigation (Feed, Ranking, Regulamento) and `IndexedStack` or `StatefulShellRoute`
- [x] 2.2 Update `app_router.dart`: nest feed/ranking/rules under shell; redirect `/ranking` → feed shell tab Ranking
- [x] 2.3 Implement feed-shell empty state when `currentGroupId` is null with CTA to `/group`
- [x] 2.4 Implement feed header (group code, name, link to group hub) per prototype `feed-header`
- [x] 2.5 Preserve tab state (feed sub-tabs + shell tab) across navigation where possible

## 3. Login and group hub UI

- [x] 3.1 Redesign `login_screen.dart`: logo, CopaBolão title, Firebase badge, register toggle, OAuth grid, prototype continue, active session card
- [x] 3.2 Redesign `group_screen.dart`: session summary card, active group card with fee badge, feed/ranking shortcuts, join form, create group CTA, logout
- [x] 3.3 Remove "placeholder" labels from group hub navigation buttons
- [x] 3.4 Ensure auth redirect flow still works (signed out → login, signed in on login → group)

## 4. Group setup screens UI

- [x] 4.1 Redesign `create_group_screen.dart` with prototype layout: grid currency/fee, lock minutes, team search chips with flags, phase grid, recalculate card, submit CTA
- [x] 4.2 Redesign `edit_group_filter_screen.dart` with admin gate UI, loading states, same pickers as create, save snackbar
- [x] 4.3 Align phase ids and team list with `group_match_filter_stages.dart` and `tournament_team_picker.dart`

## 5. Feed and match cards

- [x] 5.1 Refactor `feed_screen.dart` into shell child: Ativos/Arquivados toggle + Próximos/Ao vivo/Encerrados sub-tabs
- [x] 5.2 Create `MatchFeedCard` widget: flags, teams row, status badge, time, accumulation banner, state-specific footers
- [x] 5.3 Implement inline prediction inputs on scheduled cards wired to `upsertPrediction`
- [x] 5.4 Implement live card footer: locked prediction + "Secar Palpites da Galera" button
- [x] 5.5 Implement `SecarPalpitesSheet` bottom drawer using group predictions stream
- [x] 5.6 Style finished cards with winner highlight and navigate to match details on tap
- [x] 5.7 Keep friendly Firestore index error message on feed

## 6. Match details UI

- [x] 6.1 Add `MatchHeroCard` (teams, score, pot, winner split) at top of `match_details_screen.dart`
- [x] 6.2 Restyle `LockCountdownBanner`, `PredictionInputCard`, participation card to prototype visuals
- [x] 6.3 Restyle `GroupPredictionsList` as "Palpites do Grupo" card with opt-out labels
- [x] 6.4 Extend `PaymentLedgerCard` into grouped transparency list: Pendentes, Pagamento Declarado, Vencedores
- [x] 6.5 Add participant search field filtering ledger rows
- [x] 6.6 Add personal loser "Já paguei" CTA block and winner gold banner per prototype
- [x] 6.7 Add back navigation to feed shell (chevron + "Detalhes do Jogo" header)

## 7. Ranking and Regulamento tabs

- [x] 7.1 Create `RankingTab` with podium widget (top 3) + full sorted member list from Firestore
- [x] 7.2 Highlight current user row in ranking list
- [x] 7.3 Create `RulesTab` with four rule cards using live group settings (fee, lock, exact score, snowball)
- [x] 7.4 Handle empty member state on ranking tab

## 8. Polish and verification

- [x] 8.1 Audit all screens for hard-coded `Theme.of` colors; migrate to design tokens
- [x] 8.2 Manual test matrix: login (firebase on/off), group join/create, feed tabs, inline predict, secar drawer, match details ledger, ranking, rules
- [x] 8.3 Widget tests for `MatchFeedCard`, `MatchStatusBadge`, `MoneyFormat`, podium layout
- [x] 8.4 Compare screenshots against `worldcup-bet-tracker.html` dark theme and document known gaps
