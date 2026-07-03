import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../routing/navigation_helpers.dart';
import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/alert_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../feed/feed_screen.dart';
import 'group_match_filter_stages.dart';
import 'group_screen.dart';
import 'tournament_team_picker.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  static const routePath = '/group/create';

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _entryFeeController = TextEditingController(text: '10.00');
  final _lockMinutesController = TextEditingController(text: '15');
  final _teamSearchController = TextEditingController();

  String _currency = 'BRL';
  final Set<String> _selectedTeamIds = {};
  final Set<String> _selectedStages = {};
  int? _includedMatchesCount;
  bool _countingMatches = false;

  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _entryFeeController.dispose();
    _lockMinutesController.dispose();
    _teamSearchController.dispose();
    super.dispose();
  }

  static const _tournamentId = 'wc2026';

  String _friendlyFirestoreError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      return 'Sem permissão no Firestore. Confirme que você está logado e que as '
          'regras foram publicadas (firebase deploy --only firestore:rules).';
    }
    return error.message ?? error.toString();
  }

  int? _parseEntryFeeToCents(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) return null;
    if (value.isNaN || value.isInfinite) return null;
    if (value < 0) return null;
    return (value * 100).round();
  }

  int? _parsePositiveInt(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null) return null;
    if (value <= 0) return null;
    return value;
  }

  Future<void> _recountIncludedMatches() async {
    final repos = appRepos(context);
    if (repos == null) return;

    setState(() {
      _countingMatches = true;
      _error = null;
    });

    try {
      final count = await repos.firestore.countIncludedCatalogMatches(
        tournamentId: _tournamentId,
        teamIds: _selectedTeamIds.toList(growable: false),
        stages: _selectedStages.toList(growable: false),
      );
      if (!mounted) return;
      setState(() => _includedMatchesCount = count);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      setState(() => _error = _friendlyFirestoreError(e));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _countingMatches = false);
    }
  }

  Future<void> _createGroup() async {
    final auth = appAuth(context);
    final repos = appRepos(context);
    final state = appState(context);
    final user = auth?.user;
    if (user == null || repos == null) return;

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await user.getIdToken(true);
      final entryFeeCents = _parseEntryFeeToCents(_entryFeeController.text)!;
      final lockMinutes = _parsePositiveInt(_lockMinutesController.text)!;
      final matchFilter = GroupMatchFilter(
        teamIds: _selectedTeamIds.toList(growable: false),
        stages: _selectedStages.toList(growable: false),
      );

      final groupId = await repos.firestore.createGroup(
        name: _nameController.text.trim(),
        currency: _currency,
        entryFeeCents: entryFeeCents,
        predictionLockMinutes: lockMinutes,
        creatorUid: user.uid,
        creatorDisplayName: user.displayName ?? '',
        creatorPhotoUrl: user.photoURL,
        matchFilter: matchFilter,
      );

      state.setCurrentGroupId(groupId);
      if (!mounted) return;
      context.go(FeedScreen.routePath);
    } on FirebaseException catch (e) {
      setState(() => _error = _friendlyFirestoreError(e));
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final feePreview = _parseEntryFeeToCents(_entryFeeController.text);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CONFIGURAR BOLÃO', style: AppTextStyles.titleCaps(context)),
                      const SizedBox(height: 4),
                      Text('Novo Grupo', style: AppTextStyles.displayHeadline(context, size: 24)),
                    ],
                  ),
                ),
                AppButtonOutline(
                  label: 'Cancelar',
                  expand: false,
                  onPressed: _submitting
                      ? null
                      : () => navigateBack(context, fallback: GroupScreen.routePath),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Nome do Grupo',
                      hintText: 'Ex: Bolão do Trabalho ou Família Silva',
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final v = value?.trim() ?? '';
                      if (v.isEmpty) return 'Informe um nome.';
                      if (v.length < 3) return 'Use pelo menos 3 caracteres.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _currency,
                          decoration: const InputDecoration(labelText: 'Moeda'),
                          items: const [
                            DropdownMenuItem(value: 'BRL', child: Text('Real (BRL)')),
                            DropdownMenuItem(value: 'EUR', child: Text('Euro (EUR)')),
                            DropdownMenuItem(value: 'USD', child: Text('Dólar (USD)')),
                          ],
                          onChanged: _submitting
                              ? null
                              : (v) => setState(() => _currency = v ?? 'BRL'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _entryFeeController,
                          enabled: !_submitting,
                          decoration: const InputDecoration(
                            labelText: 'Taxa por Partida',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: false,
                          ),
                          validator: (value) {
                            final cents = _parseEntryFeeToCents(value ?? '');
                            if (cents == null) return 'Valor inválido.';
                            if (cents <= 0) return 'Maior que 0.';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  if (feePreview != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Armazenado: $feePreview centavos',
                        style: AppTextStyles.sub(context),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lockMinutesController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Tranca de Palpites (Minutos)',
                      helperText: 'Tempo limite antes de cada início de partida.',
                    ),
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      final minutes = _parsePositiveInt(value ?? '');
                      if (minutes == null) return 'Informe um número inteiro > 0.';
                      if (minutes > 180) return 'Use um valor até 180.';
                      return null;
                    },
                    onFieldSubmitted: (_) => _submitting ? null : _createGroup(),
                  ),
                  const SizedBox(height: 20),
                  Text('Filtro de Seleções', style: AppTextStyles.body(context, weight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _teamSearchController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Times (pesquisar)',
                      hintText: 'Ex.: Brasil, Portugal…',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 8),
                  TournamentTeamPicker(
                    tournamentId: _tournamentId,
                    searchController: _teamSearchController,
                    selectedTeamIds: _selectedTeamIds,
                    enabled: !_submitting,
                    onSelectionChanged: () =>
                        setState(() => _includedMatchesCount = null),
                  ),
                  const SizedBox(height: 12),
                  Text('Fases do Torneio', style: AppTextStyles.body(context, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final stage in groupMatchFilterStages)
                        FilterChip(
                          label: Text(stage.label),
                          selected: _selectedStages.contains(stage.id),
                          onSelected: _submitting
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedStages.add(stage.id);
                                    } else {
                                      _selectedStages.remove(stage.id);
                                    }
                                    _includedMatchesCount = null;
                                  });
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    backgroundColor: colors.accentLight.withValues(alpha: 0.25),
                    borderColor: colors.accent.withValues(alpha: 0.2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total de Jogos no Filtro:',
                              style: AppTextStyles.body(context, weight: FontWeight.w700),
                            ),
                            Text(
                              '${_includedMatchesCount ?? '—'}',
                              style: TextStyle(
                                color: colors.accent,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppButtonOutline(
                          label: 'Recalcular Jogos',
                          onPressed: (_submitting || _countingMatches)
                              ? null
                              : _recountIncludedMatches,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Criar Grupo & Ir para o Feed',
                    onPressed: _submitting ? null : _createGroup,
                    isLoading: _submitting,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    AlertBox(
                      variant: AlertBoxVariant.danger,
                      child: Text(_error!),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

