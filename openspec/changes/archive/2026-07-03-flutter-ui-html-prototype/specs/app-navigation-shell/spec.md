## ADDED Requirements

### Requirement: Post-login main experience uses a bottom navigation shell
After the user has selected a group, the primary in-app experience SHALL use a shell scaffold with bottom navigation for three tabs: Feed, Ranking, and Regulamento (Rules), matching the HTML `app-nav` structure.

#### Scenario: Bottom nav visible on feed shell
- **WHEN** the user navigates to `/feed` with an active group
- **THEN** a bottom navigation bar with Feed, Ranking, and Regulamento items is visible and the active tab is highlighted

#### Scenario: Tab state preserved while switching
- **WHEN** the user switches from Feed to Ranking and back to Feed
- **THEN** the feed tab selection (Ativos/Arquivados, Próximos/Ao vivo/Encerrados) is preserved without full reload where possible

### Requirement: Group-less state redirects to group hub
The feed shell SHALL show an empty state with call-to-action when no group is selected, equivalent to the HTML "Selecione um grupo" block.

#### Scenario: No group selected on feed
- **WHEN** the user opens `/feed` without `currentGroupId`
- **THEN** the app shows an empty state message and a button to navigate to `/group`

### Requirement: Secondary routes remain stack-based
Login (`/login`), group hub (`/group`), create group (`/group/create`), edit filter (`/group/filter`), and match details (`/match/:matchId`) SHALL remain separate routes outside or above the bottom-nav shell, with back navigation returning to the prior context.

#### Scenario: Match details back navigation
- **WHEN** the user taps back on match details
- **THEN** they return to the feed shell on the Feed tab

#### Scenario: Legacy ranking route compatibility
- **WHEN** the user navigates to `/ranking`
- **THEN** the app redirects to `/feed` with the Ranking tab active (or equivalent) so bookmarks continue to work

### Requirement: Feed header shows active group context
The feed shell header SHALL display group code/id, group name, and a control to return to group management ("Sair do Grupo" / group hub), matching the HTML `feed-header`.

#### Scenario: Group header on feed
- **WHEN** a group is active on the feed shell
- **THEN** the header shows `CÓDIGO: {groupId}` and the group name
