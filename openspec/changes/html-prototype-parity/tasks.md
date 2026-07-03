## 1. Payment rules and spec

- [x] 1.1 OpenSpec change `html-prototype-parity` with payment-ledger delta
- [x] 1.2 Update firestore.rules: declare paid when match.status == finished

## 2. Pot estimation

- [x] 2.1 Add PotCalculator helper
- [x] 2.2 Add watchMatchParticipations stream
- [x] 2.3 Integrate pot display in hero and feed cards

## 3. Feed and match details navigation

- [x] 3.1 Allow scheduled card navigation with input tap absorption
- [x] 3.2 ParticipantTransparencyList for scheduled/live
- [x] 3.3 Conditional sections in match_details_screen

## 4. Predictions and ledger enrichment

- [x] 4.1 GroupPredictionsList: all members, opt-out, win/loss
- [x] 4.2 PaymentLedgerCard: post-match gate, real amounts, Fora do Pote

## 5. Tests and docs

- [x] 5.1 Tests for PotCalculator and payment UI gate
- [x] 5.2 Update known-gaps.md
