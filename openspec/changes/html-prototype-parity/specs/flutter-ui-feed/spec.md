## ADDED Requirements

### Requirement: Scheduled feed cards navigate to details
Tapping a scheduled match card SHALL navigate to match details; inline prediction inputs SHALL not trigger navigation.

#### Scenario: Navigation on tap
- **WHEN** the user taps a scheduled match card
- **THEN** the app SHALL navigate to the match details view

#### Scenario: Prediction inputs inline
- **WHEN** the user interacts with prediction inputs inline on the card
- **THEN** the app SHALL NOT navigate to the match details view

### Requirement: Feed shows estimated pot when applicable
Scheduled and live feed cards SHALL display pot value using the same estimation formula as match details when carryover or entry-fee pot applies.

#### Scenario: Feed card displays estimated pot
- **WHEN** a match card is displayed in the feed and the match has entry fees
- **THEN** the feed card SHALL display the estimated pot calculated using the entry-fee formula
