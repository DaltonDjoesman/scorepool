## Context

O app Flutter (`lib/`) já possui rotas GoRouter, integração Firebase Auth/Firestore, repositórios e telas funcionais com Material 3 genérico. O protótipo `worldcup-bet-tracker.html` (~3400 linhas) define a UI alvo com design system próprio, shell com bottom navigation, feed rico e ledger de transparência agrupado.

Este change é **apresentação e navegação** — não altera modelo de dados, security rules ou Cloud Functions. Reutiliza `Repositories`, `AppState`, `AuthController` e widgets de domínio existentes (`PredictionInputCard`, `PaymentLedgerCard`, etc.), refatorando-os para o visual do protótipo.

## Goals / Non-Goals

**Goals:**
- Paridade visual e de fluxo com `worldcup-bet-tracker.html` nas 7 áreas: login, grupo, criar/editar filtro, feed shell, detalhes, ranking, regulamento.
- Design system centralizado reutilizável em todas as telas.
- Shell com bottom nav preservando estado das abas.
- Palpite inline no feed e drawer "Secar Palpites" conectados ao Firestore existente.
- Ledger de detalhes com grupos pendentes/pagos/vencedores e busca.

**Non-Goals:**
- Replicar o painel lateral de "Tweaks" do HTML (demo only).
- Replicar frame de iPhone, status bar fake ou route-bar de debug no app de produção.
- Alterar regras de negócio (lock, opt-out, carryover, débitos) — apenas UI.
- Suporte a tema claro no v1 (dark first; light pode ser follow-up).
- Internacionalização além do pt-BR já usado.

## Decisions

### 1) Design system em `lib/src/theme/` + `lib/src/widgets/`
**Decisão:** extrair `AppTheme`, extensions (`AppColors`, `AppTextStyles`) e widgets (`AppCard`, `AppButton`, `StatusBadge`, `TeamFlag`, `MatchStatusBadge`, `AppToast`) do CSS/HTML.

**Alternativas:** ThemeData puro sem widgets — rejeitado por duplicação em cada tela.

### 2) Fontes via `google_fonts`
**Decisão:** usar pacote `google_fonts` para Outfit + Plus Jakarta Sans.

**Alternativas:** bundling manual — mais trabalho de assets; aceitável se offline for crítico depois.

### 3) Bandeiras via asset map ou `country_flags` / SVG local
**Decisão:** mapa `teamId → flag asset` alinhado ao picker existente (`tournament_team_picker.dart`); preferir assets locais para WC2026 teams já listados.

**Alternativas:** API externa de flags — rejeitado por rede e inconsistência.

### 4) Shell com `StatefulShellRoute` (go_router) ou `IndexedStack` manual
**Decisão:** usar `StatefulShellRoute` do go_router v14+ para Feed/Ranking/Regulamento com uma rota `/feed` e branches, OU um único `FeedShellScreen` com `IndexedStack` e tabs internas se a versão do go_router no projeto não suportar shell routes.

**Por quê:** preserva estado das abas e URL `/feed` como entrada principal pós-grupo.

**Fallback:** `FeedShellScreen` stateful com 3 child widgets — mais simples, menos URL granularity.

### 5) Ranking deixa de ser rota top-level
**Decisão:** `/ranking` redireciona para `/feed?tab=ranking` ou shell com tab index 1; remover botão placeholder do group hub que ia para `/ranking` isolado.

### 6) Refatorar widgets de domínio em vez de reescrever lógica
**Decisão:** manter `PredictionInputCard`, `LockCountdownBanner`, `PaymentLedgerCard`, `GroupPredictionsList` — alterar apenas `build()` e extrair sub-widgets de layout (hero, ledger groups).

**Por quê:** lógica Firestore já testada; reduz risco de regressão.

### 7) Secar Palpites = `showModalBottomSheet` com `GroupPredictionsList`
**Decisão:** reutilizar stream de palpites do jogo; drawer full-width no estilo HTML.

### 8) Feed inline prediction
**Decisão:** extrair `InlinePredictionInputs` compartilhado entre feed card e detalhes; chama `upsertPrediction` existente.

**Risco:** dupla edição feed vs detalhes — mitigar sincronizando via stream.

## Risks / Trade-offs

- **[Risk] go_router shell complexity** → Verificar versão em `pubspec.yaml`; usar IndexedStack se necessário.
- **[Risk] Performance com muitos StreamBuilders no feed** → Manter estrutura atual; otimizar com `StreamBuilder` no list level apenas.
- **[Risk] Paridade 100% com HTML impossível em Material** → Aceitar pequenas diferenças de spacing; validar com screenshots side-by-side.
- **[Risk] Inline prediction + navegação para detalhes** → `stopPropagation` equivalente: botões no card usam `InkWell` separados ou `GestureDetector` com behavior deferToChild.
- **[Trade-off] Dark-only v1** → Entrega mais rápida; light theme depois.

## Migration Plan

1. Introduzir theme + widgets sem alterar telas (PR 1).
2. Shell + feed redesign wired to existing data (PR 2).
3. Login + group hub + setup screens (PR 3).
4. Match details + ledger groups (PR 4).
5. Ranking/rules tabs + redirect `/ranking` (PR 5).
6. Remover estilos Material legados e placeholders.

Rollback: cada PR é independente; reverter PR específico restaura UI anterior sem migração de dados.

## Open Questions

- Versão exata do `go_router` no projeto — confirmar suporte a `StatefulShellRoute` na implementação.
- Ledger "escolher credor" com múltiplos vencedores: o modelo `DebtItem` já fixa `toUid` server-side? Se sim, UI só exibe; se não, pode precisar de change separado no backend.
- Bandeiras: quantos times no catálogo WC2026 vs lista hardcoded no create-group — alinhar com `tournament_team_picker.dart` existente.
