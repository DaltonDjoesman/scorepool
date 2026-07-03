## Why

O app Flutter atual implementa a lógica de negócio (auth, grupos, feed, palpites, ledger) com UI Material genérica e navegação fragmentada (telas soltas, sem shell, botões “placeholder”). O protótipo `worldcup-bet-tracker.html` já consolida a experiência desejada — visual CopaBolão 2026, bottom navigation, feed rico com bandeiras e palpites inline, drawer “Secar Palpites”, ranking com pódio e aba Regulamento — e serve como fonte de verdade visual para Android/iOS.

Refazer a UI agora alinha produto e protótipo antes de completar as seções restantes do `worldcup-bet-tracker-spec` (feed, ranking, ledger), evitando retrabalho em telas que ainda serão evoluídas.

## What Changes

- Introduzir **design system Flutter** espelhando tokens do HTML (cores OKLCH/teal, tipografia Outfit + Plus Jakarta Sans, cards, chips, badges, botões, inputs, toast/snackbar).
- Reestruturar **navegação** com shell pós-login: bottom nav (Feed · Ranking · Regulamento) no `/feed`, mantendo rotas existentes para login, grupo, criar/editar filtro e detalhes do jogo.
- Redesenhar **Login** conforme protótipo (logo CopaBolão, badge Firebase/protótipo, sessão ativa, OAuth grid, modo sem Firebase).
- Redesenhar **Hub de Grupo** (cartão do bolão ativo, join por código, atalhos feed/ranking, editar filtro).
- Redesenhar **Criar Grupo** e **Editar Filtro** (chips com bandeira, grid de fases, recalcular jogos, estados admin/pré-requisito).
- Redesenhar **Feed** com header do grupo, toggle Ativos/Arquivados, abas Próximos/Ao vivo/Encerrados, cards com bandeiras, palpite inline em jogos agendados, banner de pote acumulado, ação “Secar Palpites” em jogos ao vivo.
- Redesenhar **Detalhes do Jogo** com hero pós-jogo, countdown, palpite, opt-out, palpites do grupo, ledger agrupado (pendentes/pagos/vencedores), busca de participantes e CTAs “Já paguei”/banner de vencedor.
- Implementar **Ranking** com pódio top 3 + lista completa e destaque do usuário atual.
- Implementar nova aba **Regulamento** com regras dinâmicas do grupo (taxa, lock, placar exato, acumulação).
- **BREAKING (visual/navegação):** remover AppBar Material padrão nas telas principais; feed deixa de ser lista simples e passa a ser shell com bottom nav; ranking deixa de ser rota isolada `/ranking` e passa a ser aba dentro do shell (rota `/ranking` pode redirecionar ou ser removida).

## Capabilities

### New Capabilities

- `app-design-system`: tokens de tema, tipografia, cores semânticas (accent, gold, danger, success) e widgets reutilizáveis (AppCard, AppButton, StatusBadge, FilterChip, MatchPotBanner, Toast).
- `app-navigation-shell`: estrutura de rotas, `ShellScaffold` com bottom navigation e preservação de estado entre abas Feed/Ranking/Regulamento.
- `flutter-ui-auth-group`: telas de login e hub de grupo (join/criar/atalhos) conforme protótipo HTML.
- `flutter-ui-group-setup`: telas criar grupo e editar filtro com picker de times/fases e contagem de jogos.
- `flutter-ui-feed`: feed de jogos, cards, palpite inline, drawer “Secar Palpites”, abas ativos/arquivados e estados vazios.
- `flutter-ui-match-details`: tela de detalhes do jogo com ledger de transparência agrupado e interações de pagamento/participação.
- `flutter-ui-ranking-rules`: aba ranking (pódio + lista) e aba regulamento com valores do grupo ativo.

### Modified Capabilities

<!-- UI-only change: backend requirements unchanged. Presentation requirements live in new capability specs above. -->

## Impact

- **Frontend Flutter:** `lib/src/app.dart` (tema), `lib/src/routing/app_router.dart` (shell routes), todas as telas em `lib/src/screens/**`, novos widgets em `lib/src/widgets/**` ou `lib/src/theme/**`.
- **Assets:** bandeiras de seleções (SVG/PNG ou pacote), possivelmente `google_fonts` para Outfit e Plus Jakarta Sans.
- **Sem mudança de backend:** Firestore, Auth, repositórios e regras de negócio permanecem; apenas camada de apresentação e navegação.
- **Protótipo HTML:** permanece referência; não é removido. Paridade funcional buscada no Flutter com dados reais do Firestore.
- **Testes:** widget tests para componentes críticos (match card, countdown, ledger groups); smoke manual nas 7 rotas.
