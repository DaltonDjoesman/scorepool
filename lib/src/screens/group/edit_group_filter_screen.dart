import 'package:flutter/material.dart';

import '../../app.dart';
import '../../routing/navigation_helpers.dart';
import '../../models/group.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/included_match_recount.dart';
import '../../widgets/alert_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_toast.dart';
import 'group_match_filter_section.dart';
import 'group_screen.dart';

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

    final result = await recountIncludedCatalogMatches(
      matches: repos.matches,
      tournamentId: _tournamentId,
      teamIds: _selectedTeamIds,
      stages: _selectedStages,
    );
    if (!mounted) return;
    setState(() {
      _countingMatches = false;
      if (result.isSuccess) {
        _includedMatchesCount = result.count;
      } else {
        _error = result.errorMessage;
      }
    });
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
      await repos.groups.updateGroupMatchFilter(
        groupId: groupId,
        matchFilter: GroupMatchFilter(
          teamIds: _selectedTeamIds.toList(growable: false),
          stages: _selectedStages.toList(growable: false),
        ),
      );
      if (!mounted) return;
      AppToast.success(context, 'Filtro atualizado');
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
      body: SafeArea(
        child: (uid == null || repos == null || groupId == null)
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔒', style: TextStyle(fontSize: 32)),
                      const SizedBox(height: 12),
                      Text(
                        'Selecione um grupo primeiro',
                        style: AppTextStyles.displayHeadline(context, size: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      AppButton(
                        label: 'Voltar para o Grupo',
                        onPressed: () =>
                            navigateBack(context, fallback: GroupScreen.routePath),
                      ),
                    ],
                  ),
                ),
              )
            : StreamBuilder<Group?>(
              stream: repos.groups.watchGroup(groupId),
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
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: AlertBox(
                        variant: AlertBoxVariant.warning,
                        child: const Text(
                          'Apenas admins podem editar o filtro deste bolão.',
                        ),
                      ),
                    ),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('GERENCIAR REGRAS', style: AppTextStyles.titleCaps(context)),
                              const SizedBox(height: 4),
                              Text(
                                'Filtro do Bolão',
                                style: AppTextStyles.displayHeadline(context, size: 24),
                              ),
                            ],
                          ),
                        ),
                        AppButtonOutline(
                          label: 'Voltar',
                          expand: false,
                          onPressed: _saving
                              ? null
                              : () => navigateBack(
                                    context,
                                    fallback: GroupScreen.routePath,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(group.name, style: AppTextStyles.body(context, weight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    GroupMatchFilterSection(
                      tournamentId: _tournamentId,
                      teamSearchController: _teamSearchController,
                      selectedTeamIds: _selectedTeamIds,
                      selectedStages: _selectedStages,
                      enabled: !_saving,
                      includedMatchesCount: _includedMatchesCount,
                      countingMatches: _countingMatches,
                      onSelectionChanged: () =>
                          setState(() => _includedMatchesCount = null),
                      onRecalculate: _recountIncludedMatches,
                      recalculateLabel: 'Recalcular',
                      matchCountLabel: 'Jogos incluídos',
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: _saving ? 'Sincronizando…' : 'Salvar Filtro no Firestore',
                      onPressed: _saving ? null : () => _save(groupId),
                      isLoading: _saving,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      AlertBox(
                        variant: AlertBoxVariant.danger,
                        child: Text(_error!),
                      ),
                    ],
                  ],
                );
              },
            ),
      ),
    );
  }
}

