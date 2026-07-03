## ADDED Requirements

### Requirement: Application theme matches HTML prototype tokens
The Flutter app SHALL expose a centralized theme derived from `worldcup-bet-tracker.html` with primary accent hue ~142 (teal/green), semantic colors for gold (winners/pot), danger (unpaid), and success (paid), plus light and dark `ColorScheme` variants.

#### Scenario: Dark theme is default
- **WHEN** the app launches
- **THEN** the default theme uses dark phone-surface backgrounds and light foreground text consistent with the HTML `phone-theme-dark` variables

#### Scenario: Semantic colors are available to widgets
- **WHEN** a widget needs to show winner, unpaid, or paid state
- **THEN** it SHALL use shared theme extension or design tokens rather than hard-coded one-off colors

### Requirement: Typography uses display and body font families
The app SHALL use Outfit (or equivalent) for headlines/display text and Plus Jakarta Sans (or equivalent) for body and labels, matching the HTML prototype hierarchy (`app-headline`, `app-title-caps`, `app-sub`).

#### Scenario: Screen titles use display font
- **WHEN** a primary screen title is rendered (e.g. "CopaBolão 2026", "Gerenciar Bolão")
- **THEN** it uses the display font family with weight and size comparable to the HTML prototype

### Requirement: Shared UI components mirror prototype patterns
The app SHALL provide reusable widgets equivalent to HTML classes: card (`app-card`), primary button (`app-button`), outline button (`app-button-outline`), text input (`app-input`), status badge (`match-status-badge`, `status-paid`, `status-unpaid`, `status-winner`), filter chip (`chip` / `chip-active`), alert boxes (`alert-info`, `alert-danger`, `alert-warning`), and toast/snackbar feedback.

#### Scenario: Match status badge styling
- **WHEN** a match is scheduled, live, or finished
- **THEN** the status badge uses distinct colors matching scheduled/live/ended styles from the prototype

#### Scenario: User action feedback
- **WHEN** the user saves a prediction or declares payment
- **THEN** the app shows a brief toast/snackbar with success styling similar to the HTML `toast-notif`

### Requirement: Money formatting is consistent
The app SHALL format currency amounts using the group's currency code and two decimal places, equivalent to the HTML `formatMoney` helper.

#### Scenario: Entry fee display on group card
- **WHEN** a group shows entry fee per game
- **THEN** the amount is formatted as `{currency} {major units}` (e.g. `BRL 10.00`)
