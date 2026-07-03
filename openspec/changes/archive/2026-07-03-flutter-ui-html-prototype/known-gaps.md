# Known gaps vs HTML prototype

Updated after `html-prototype-parity` implementation.

## Resolved

- Post-match payment declaration ("Já paguei") after match finishes
- Estimated pot on scheduled/live hero and feed cards
- Navigation to match details from editable scheduled feed cards
- Participant list on scheduled/live match details
- Group predictions with opt-out labels and win/loss markers
- Payment ledger gated to finished matches with winners; Fora do Pote group

## Remaining visual / minor gaps

- **Phone frame**: HTML decorative mockup vs native full-screen Flutter
- **Team names**: Still showing team IDs (e.g. `BRA`) not full catalog names
- **Social payment audit**: HTML allows any member to toggle others' paid status; app keeps own-debtor only (by design)
- **Secar Palpites on match details**: Available on feed live cards only, not duplicated on details screen
- **Toast animations**: SnackBar vs HTML slide-in toast

## Intentionally unchanged

- Firestore schema for debts/participations (no backend migration)
- No in-app PIX or payment integration
- Ranking uses `perfectScoresCount` from closeout, not live recalculation from all ended games
