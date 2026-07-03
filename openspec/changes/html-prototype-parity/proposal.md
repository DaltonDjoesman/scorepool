## Why

A passagem de UI (`flutter-ui-html-prototype`) alinhou layout e navegação ao HTML, mas lacunas funcionais permanecem: pote estimado em jogos futuros, detalhes acessíveis antes do jogo, lista de participantes, palpites com opt-out, e ledger de pagamentos efetivamente utilizável após o encerramento.

## What Changes

- Alterar regra de **declaração de pagamento**: permitir "Já paguei" após o jogo terminar (apenas o próprio devedor).
- Implementar **cálculo de pote estimado** (`entryFee × inPot + carryover`) em hero, feed e detalhes.
- Permitir **navegação para detalhes** em cards agendados (inputs absorvem tap).
- Adicionar **lista de participantes** em detalhes (scheduled/live).
- Enriquecer **palpites do grupo** (todos membros, opt-out, acerto/erro).
- Completar **ledger pós-jogo** (gate por status, valores reais, grupo Fora do Pote).

## Capabilities

### Modified Capabilities

- `payment-ledger`: declare paid após match finished
- `flutter-ui-match-details`: participantes, palpites enriquecidos, ledger condicional
- `flutter-ui-feed`: pote estimado, navegação scheduled

## Impact

- `firestore.rules`, `lib/src/utils/pot_calculator.dart`, repositório, telas match/feed, testes.
