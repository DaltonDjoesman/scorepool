import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/group.dart';

class EditGroupFilterScreen extends StatefulWidget {
  const EditGroupFilterScreen({super.key});

  static const routePath = '/group/filter';

  @override
  State<EditGroupFilterScreen> createState() => _EditGroupFilterScreenState();
}

class _EditGroupFilterScreenState extends State<EditGroupFilterScreen> {
  final _teamSearchController = TextEditingController();

  final Set<String> _selectedTeamIds = {};
  final Set<String> _selectedStages = {};

  bool _initialized = false;
  bool _saving = false;
  bool _countingMatches = false;
  int? _includedMatchesCount;
  String? _error;

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

  @override
  void dispose() {
    _teamSearchController.dispose();
    super.dispose();
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

  Future<void> _save(String groupId) async {
    final auth = appAuth(context);
    final repos = appRepos(context);
    final user = auth?.user;
    if (user == null || repos == null) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await repos.firestore.updateGroupMatchFilter(
        groupId: groupId,
        matchFilter: GroupMatchFilter(
          teamIds: _selectedTeamIds.toList(growable: false),
          stages: _selectedStages.toList(growable: false),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Filtro atualizado')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = appAuth(context);
    final repos = appRepos(context);
    final state = appState(context);

    final uid = auth?.user?.uid;
    final groupId = state.currentGroupId;

    return Scaffold(
      appBar: AppBar(title: const Text('Editar filtro')),
      body: (uid == null || repos == null || groupId == null)
          ? const Center(child: Text('Selecione um grupo primeiro.'))
          : StreamBuilder<Group?>(
              stream: repos.firestore.watchGroup(groupId),
              builder: (context, snapshot) {
                final group = snapshot.data;
                if (snapshot.connectionState == ConnectionState.waiting &&
                    group == null) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (group == null) {
                  return const Center(child: Text('Grupo não encontrado.'));
                }

                final isAdmin = group.adminUids.contains(uid);
                if (!isAdmin) {
                  return const Center(
                    child: Text('Apenas admins podem editar o filtro.'),
                  );
                }

                if (!_initialized) {
                  _selectedTeamIds
                    ..clear()
                    ..addAll(group.matchFilter.teamIds);
                  _selectedStages
                    ..clear()
                    ..addAll(group.matchFilter.stages);
                  _initialized = true;
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _teamSearchController,
                      enabled: !_saving,
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
                              final q = _teamSearchController.text
                                  .trim()
                                  .toLowerCase();
                              if (q.isEmpty) return true;
                              return t.name.toLowerCase().contains(q) ||
                                  t.id.toLowerCase().contains(q);
                            })
                            .take(24))
                          FilterChip(
                            label: Text(team.name),
                            selected: _selectedTeamIds.contains(team.id),
                            onSelected: _saving
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
                            onSelected: _saving
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
                          onPressed: (_saving || _countingMatches)
                              ? null
                              : _recountIncludedMatches,
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
                      onPressed: _saving ? null : () => _save(groupId),
                      child: const Text('Salvar filtro'),
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
                );
              },
            ),
    );
  }
}

