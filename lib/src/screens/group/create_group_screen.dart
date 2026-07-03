import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../feed/feed_screen.dart';

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

  static const _teams = <({String id, String name})>[
    (id: 'BRA', name: 'Brasil'),
    (id: 'ARG', name: 'Argentina'),
    (id: 'URU', name: 'Uruguai'),
    (id: 'USA', name: 'Estados Unidos'),
    (id: 'MEX', name: 'México'),
    (id: 'FRA', name: 'França'),
    (id: 'ESP', name: 'Espanha'),
    (id: 'POR', name: 'Portugal'),
    (id: 'ENG', name: 'Inglaterra'),
    (id: 'GER', name: 'Alemanha'),
    (id: 'ITA', name: 'Itália'),
    (id: 'NED', name: 'Holanda'),
  ];

  static const _stages = <({String id, String label})>[
    (id: 'group', label: 'Grupos'),
    (id: 'round_of_32', label: '32 avos'),
    (id: 'round_of_16', label: 'Oitavas'),
    (id: 'quarterfinal', label: 'Quartas'),
    (id: 'semifinal', label: 'Semi'),
    (id: 'third_place', label: '3º lugar'),
    (id: 'final', label: 'Final'),
  ];

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
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Criar grupo')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Configuração do bolão',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _nameController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Nome do grupo',
                      hintText: 'Ex.: Família 2026',
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
                  DropdownButtonFormField<String>(
                    initialValue: _currency,
                    decoration: const InputDecoration(labelText: 'Moeda'),
                    items: const [
                      DropdownMenuItem(
                        value: 'BRL',
                        child: Text('BRL (R\$)'),
                      ),
                      DropdownMenuItem(
                        value: 'EUR',
                        child: Text('EUR (€)'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('USD (\$)'),
                      ),
                    ],
                    onChanged: _submitting
                        ? null
                        : (v) => setState(() => _currency = v ?? 'BRL'),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _entryFeeController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Taxa de entrada',
                      helperText: 'Valor por jogo (ex.: 10.00)',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: false,
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      final cents = _parseEntryFeeToCents(value ?? '');
                      if (cents == null) return 'Informe um valor válido.';
                      if (cents <= 0) return 'A taxa precisa ser maior que 0.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _lockMinutesController,
                    enabled: !_submitting,
                    decoration: const InputDecoration(
                      labelText: 'Tranca do palpite (minutos)',
                      helperText: 'Ex.: 15 (tranca 15 min antes do jogo)',
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
                  Text(
                    'Filtro de jogos',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final team in _teams
                          .where((t) {
                            final q = _teamSearchController.text.trim().toLowerCase();
                            if (q.isEmpty) return true;
                            return t.name.toLowerCase().contains(q) ||
                                t.id.toLowerCase().contains(q);
                          })
                          .take(24))
                        FilterChip(
                          label: Text(team.name),
                          selected: _selectedTeamIds.contains(team.id),
                          onSelected: _submitting
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedTeamIds.add(team.id);
                                    } else {
                                      _selectedTeamIds.remove(team.id);
                                    }
                                    _includedMatchesCount = null;
                                  });
                                },
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Fases',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final stage in _stages)
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _includedMatchesCount == null
                              ? 'Jogos incluídos: —'
                              : 'Jogos incluídos: $_includedMatchesCount',
                        ),
                      ),
                      TextButton(
                        onPressed:
                            (_submitting || _countingMatches) ? null : _recountIncludedMatches,
                        child: _countingMatches
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Recalcular'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _submitting ? null : _createGroup,
                    child: const Text('Criar grupo'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
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

