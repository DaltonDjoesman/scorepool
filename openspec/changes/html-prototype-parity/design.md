## Decisions

1. **Pagamento pós-jogo**: `declare paid` quando `groupMatch.status == 'finished'`; apenas `fromUid == auth.uid`.
2. **Pote estimado**: `entryFeeCents × count(isInPot)` + `accumulatedFromPreviousCents`; membros sem doc contam como in-pot.
3. **Palpites do grupo**: visíveis após lock (scheduled locked, live, finished).
4. **Ledger**: só em finished com vencedores; participantes simples em scheduled/live.

## Data flow

```
watchMembers + watchMatchParticipations → inPotCount → PotCalculator.estimatePotCents
watchDebtItems (finished) → PaymentLedgerCard → declareDebtPaid (rules: finished)
```
