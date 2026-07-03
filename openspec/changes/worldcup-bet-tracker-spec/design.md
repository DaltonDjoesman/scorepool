## Context

O protótipo atual (`worldcup-bet-tracker.html`) demonstra o fluxo principal do app (login → feed de jogos → detalhes pós-jogo com auditoria/pagamento → ranking), com UI mobile-first e lista pública de transparência.

O produto alvo é um app Flutter (Android/iOS) com Firebase:
- **Firebase Auth** para login.
- **Cloud Firestore** como base em tempo real para feed, palpites e ledger de pagamentos.
- **Backend server-side** (ex.: Cloud Functions) para:
  - ingerir calendário/placares da API-Football;
  - “fechar” rodadas (calcular winners/potes/debitos/acúmulo) de forma consistente e auditável;
  - aplicar regras de tempo (lock de palpite, opt-out e janela “já paguei”) com confiança (cliente não é fonte de verdade).

Regras chave:
- Cada partida é uma rodada independente.
- Só ganha quem acertar o placar exato.
- Se ninguém ganhar, o pote acumula para o próximo jogo “do grupo”.
- Não há dinheiro no app; apenas declaração “Já paguei”, com auditoria social via lista pública.
- Participação financeira é independente de palpite: quem não palpita entra no pote, a menos que faça opt-out antes do lock.
- Feed de jogos é filtrado por **times selecionados** e/ou **fases selecionadas**, editável após criação do grupo.

## Goals / Non-Goals

**Goals:**
- Definir um modelo de dados por grupo que suporte:
  - participação padrão por rodada + opt-out;
  - palpite opcional com lock temporal;
  - cálculo de winners/pote/acúmulo;
  - ledger “quem paga quem” com múltiplos vencedores;
  - filtro de jogos por times/fases com atualização posterior sem quebrar histórico.
- Garantir consistência (server-side) e UX reativa (Firestore realtime).
- Manter compatibilidade e estabilidade para Android e iOS via Flutter + Firebase.

**Non-Goals:**
- Processamento de pagamentos no app (PIX/cartão/crypto), split payments ou integração bancária.
- “Recebi”/dupla confirmação de pagamento (fica apenas “Já paguei”).
- Anti-fraude forte além de regras de segurança do Firestore e auditoria social.
- Sistema complexo de pontos corridos (é jogo a jogo).

## Decisions

### 1) Fonte global de partidas + “match overlay” por grupo
**Decisão:** manter um catálogo global de matches (tournament-level) e, por grupo, um documento espelho/overlay com dados financeiros e estado do bolão.

- Global (somente backend escreve): `tournaments/wc2026/matches/{matchId}`
- Por grupo (backend e membros escrevem apenas no que for permitido): `groups/{groupId}/matches/{matchId}`

**Por quê:** reuso do calendário entre grupos, menor acoplamento e permite que cada grupo tenha seu próprio pote/acúmulo/ledger por match.

**Alternativas consideradas:**
- Duplicar todos os matches dentro de cada grupo. Rejeitado por custo/duplicação e manutenção difícil ao atualizar placares.

### 2) Filtro do grupo: união (times OU fases)
**Decisão:** um match entra no grupo se satisfizer:

\[
(homeTeamId \in teamIds) \lor (awayTeamId \in teamIds) \lor (stage \in stages)
\]

**Por quê:** atende exatamente o caso “Brasil/Portugal + Semi/Final (independente dos times)”.

### 3) Atualização do filtro (opção B) sem apagar histórico
**Decisão:** alterações do filtro só afetam matches “futuros e não trancados” para remoção; matches já trancados/ao vivo/encerrados permanecem no histórico do grupo (apenas podem ser ocultados do feed futuro).

Estados sugeridos no `groups/{groupId}/matches/{matchId}`:
- `excludedByFilter` (soft-hide)
- `lockedInGroup` (true se passou do lock ou status != scheduled)

**Por quê:** evita inconsistência social/financeira e preserva auditoria.

### 4) Carryover (acúmulo) modelado como saldo do grupo
**Decisão:** manter no grupo um saldo acumulado a ser aplicado no próximo match válido do grupo:
- `groups/{groupId}.carryOverPot`

No fechamento de um match sem winners:
- `carryOverPot += totalPot`

No primeiro match “seguinte” (por tempo) do grupo:
- set `accumulatedFromPrevious = carryOverPot` e depois `carryOverPot = 0`

**Por quê:** permite remover/adicionar jogos via filtro sem “perder” o acúmulo.

**Alternativas consideradas:**
- Referenciar “próximo match” no match anterior. Rejeitado porque fica frágil quando o filtro muda e o “próximo” deixa de existir.

### 5) Participação padrão no pote + opt-out por rodada
**Decisão:** todo membro do grupo entra como `isInPot=true` por padrão em cada rodada; pode fazer opt-out até `matchTime - lockMinutes`.

Modelo:
- `groups/{groupId}/roundParticipants/{matchId}/users/{uid}` com `isInPot`, `optedOutAt`

**Por quê:** “quem não palpita entra no pote” vira comportamento padrão; opt-out resolve casos de ausência.

### 6) Palpite opcional com lock (server-side)
**Decisão:** permitir `predictedHomeScore/awayScore` nulos (sem palpite). Alterações só são aceitas até `matchTime - lockMinutes`, validado server-side.

Modelo:
- `groups/{groupId}/predictions/{uid_matchId}`

**Por quê:** separa “participar financeiramente” de “tentar ganhar”.

### 7) Ledger de pagamentos como débitos atômicos (from → to)
**Decisão:** gerar débitos por match quando houver winners:
- `groups/{groupId}/debts/{matchId}/items/{fromUid_toUid}`

Campos: `fromUid`, `toUid`, `amount`, `status: pending|paid`, `declaredPaidAt`.

**Por quê:** resolve múltiplos vencedores sem ambiguidade e facilita agrupamento “pendentes primeiro”.

**Nota de arredondamento:** valores devem ser gerados em centavos (inteiro) para evitar drift; regra de resto: distribuir o “resto” para o primeiro winner por ordem estável (ex.: uid asc) para fechar o total.

### 8) Computação de rodada no backend
**Decisão:** Cloud Functions/serviço executa o fechamento ao detectar `status=finished` no catálogo global:
- calcula winners comparando predictions (somente `isInPot=true` e predictions existentes para isWinner);
- gera `winners[]` no match do grupo;
- gera `debts` para não-winners que estavam `isInPot=true`;
- aplica carryover se zero winners.

**Por quê:** consistência, auditabilidade e proteção contra manipulação do cliente.

## Risks / Trade-offs

- **[Cliente tentar burlar lock/opt-out/pagamento]** → validar janelas em regras/Functions; armazenar timestamps server-side; negar writes fora da janela.
- **[Mudança de filtro causar confusão “sumiu jogo”]** → soft-hide (`excludedByFilter`) e manter histórico acessível (aba “Arquivados”).
- **[Acúmulo aplicado ao “match errado” após mudança de filtro]** → aplicar carryover sempre ao próximo match do grupo por `matchTime` e apenas quando esse match for ativado/criado para o grupo.
- **[API-Football limites/instabilidade]** → ingestão server-side com cache; retries; persistência do catálogo global; app lê do Firestore.
- **[Arredondamento em múltiplos vencedores]** → armazenar em centavos e definir regra determinística do “resto”.

