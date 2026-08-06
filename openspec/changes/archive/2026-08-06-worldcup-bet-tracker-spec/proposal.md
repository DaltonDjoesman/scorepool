## Why

Criar um bolão gratuito e simples (amigos/família) para a Copa do Mundo 2026, com regras claras e auditabilidade social: cada jogo é uma rodada independente, só ganha quem acerta o placar exato, e o “pagamento” é declarado no app sem transação financeira interna.

O modelo reduz disputas (“quem ganhou?”, “quem pagou?”) e mantém o engajamento com efeito bola de neve (acúmulo) e transparência (lista pública de pendentes/pagos), funcionando de forma consistente em Android e iOS.

## What Changes

- Implementar bolões por **grupo** (multi-grupos) com configurações próprias (moeda, taxa, lock do palpite, etc.).
- Exibir apenas jogos relevantes ao grupo via filtro configurável na criação do grupo e editável depois:
  - por **times selecionados** (ex.: Brasil/Portugal), e/ou
  - por **fase** (ex.: Semi/Final aparecem independentemente dos times).
- Suportar participação financeira mesmo sem palpite:
  - quem não palpitou **ainda entra no pote** (a menos que faça opt-out da rodada).
- Definir janelas de tempo:
  - palpite editável até **15 min antes** do jogo;
  - opt-out permitido até **15 min antes** do jogo;
  - declaração “Já paguei” permitida até **início do jogo**.
- Calcular vencedores e pote por jogo:
  - vitória apenas por **placar exato**;
  - divisão do pote entre múltiplos vencedores;
  - acúmulo total para o próximo jogo do grupo quando não houver vencedores.
- Gerir “quem paga quem” quando houver múltiplos vencedores através de um ledger de débitos por rodada, com lista pública agrupada:
  - **pendentes primeiro**;
  - pagos depois.
- Garantir consistência e integridade via computações server-side (ex.: quando o jogo terminar).

## Capabilities

### New Capabilities

- `group-management`: criação/edição de grupos com configurações (moeda, taxa, lock) e gestão de membros.
- `match-catalog-ingestion`: ingestão server-side do calendário/placares (API-Football) e persistência como fonte global de partidas.
- `group-match-filtering`: filtro por times e fases para determinar quais partidas entram no bolão do grupo; suporta atualização do filtro após criação.
- `predictions-locking`: criação/edição de palpites com bloqueio temporal (15 min antes); permite “sem palpite”.
- `round-participation-optout`: participação padrão no pote e opt-out por rodada até o lock.
- `pot-and-accumulation`: cálculo de pote por rodada, vencedores por placar exato, divisão entre vencedores e acúmulo (carryover) quando não houver vencedores.
- `payment-ledger`: geração e exibição de débitos “quem paga quem” por rodada; declaração “Já paguei” até o kickoff; lista pública agrupada (pendentes primeiro).
- `ranking-stats`: ranking de “acertos em cheio” (contagem de perfect scores) por grupo.

### Modified Capabilities

<!-- none (no existing specs in this repo) -->

## Impact

- **Frontend**: Flutter (Android/iOS) com telas de login, feed de jogos filtrado, detalhes do jogo, ledger de pagamentos e ranking.
- **Backend**: funções/serviço para consumir API-Football e atualizar Firestore; funções para computar resultados de rodada, débitos e carryover.
- **Data**: Cloud Firestore com modelo por grupo (membros, matches do grupo, participantes por rodada, palpites, ledger de débitos).
- **Auth**: Firebase Auth (e-mail/senha e social).
- **Notificações**: Firebase Cloud Messaging (lembrar lock/kickoff e avisos de pote acumulado).
