import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/tournament_team.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/team_flag.dart';

class TournamentTeamPicker extends StatefulWidget {
  const TournamentTeamPicker({
    super.key,
    required this.tournamentId,
    required this.searchController,
    required this.selectedTeamIds,
    required this.enabled,
    required this.onSelectionChanged,
    this.maxGridHeight = 240,
  });

  final String tournamentId;
  final TextEditingController searchController;
  final Set<String> selectedTeamIds;
  final bool enabled;
  final VoidCallback onSelectionChanged;
  final double maxGridHeight;

  @override
  State<TournamentTeamPicker> createState() => _TournamentTeamPickerState();
}

class _TournamentTeamPickerState extends State<TournamentTeamPicker> {
  Future<List<TournamentTeam>>? _teamsFuture;

  @override
  void initState() {
    super.initState();
    widget.searchController.addListener(_onSearchChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _teamsFuture ??= _fetchTeams();
  }

  Future<List<TournamentTeam>> _fetchTeams() {
    final repos = appRepos(context);
    if (repos == null) {
      return Future.value(const <TournamentTeam>[]);
    }
    return repos.firestore.listTournamentTeams(widget.tournamentId);
  }

  void _reloadTeams() {
    setState(() => _teamsFuture = _fetchTeams());
  }

  @override
  void dispose() {
    widget.searchController.removeListener(_onSearchChanged);
    super.dispose();
  }

  void _onSearchChanged() => setState(() {});

  List<TournamentTeam> _filteredTeams(List<TournamentTeam> teams) {
    final query = widget.searchController.text.trim().toLowerCase();
    if (query.isEmpty) return teams;
    return teams
        .where(
          (team) =>
              team.name.toLowerCase().contains(query) ||
              team.id.toLowerCase().contains(query),
        )
        .toList(growable: false);
  }

  void _toggleTeam(String teamId) {
    if (!widget.enabled) return;
    setState(() {
      if (widget.selectedTeamIds.contains(teamId)) {
        widget.selectedTeamIds.remove(teamId);
      } else {
        widget.selectedTeamIds.add(teamId);
      }
    });
    widget.onSelectionChanged();
  }

  void _selectAllVisible(List<TournamentTeam> visibleTeams) {
    if (!widget.enabled || visibleTeams.isEmpty) return;
    setState(() {
      for (final team in visibleTeams) {
        widget.selectedTeamIds.add(team.id);
      }
    });
    widget.onSelectionChanged();
  }

  void _clearSelection() {
    if (!widget.enabled || widget.selectedTeamIds.isEmpty) return;
    setState(() => widget.selectedTeamIds.clear());
    widget.onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TournamentTeam>>(
      future: _teamsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Não foi possível carregar os times.',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              TextButton(onPressed: _reloadTeams, child: const Text('Tentar novamente')),
            ],
          );
        }

        final allTeams = snapshot.data ?? const <TournamentTeam>[];
        if (allTeams.isEmpty) {
          return const Text(
            'Nenhum time no catálogo da Copa. Aguarde a sincronização dos jogos.',
          );
        }

        final visibleTeams = _filteredTeams(allTeams);
        final selectedCount = widget.selectedTeamIds.length;
        final colors = appColors(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, size: 20, color: colors.phoneFg),
                const SizedBox(width: 6),
                Text('Times', style: AppTextStyles.body(context, weight: FontWeight.w700)),
                if (selectedCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.accentLight,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
                    ),
                    child: Text(
                      '$selectedCount',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.accent,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: widget.enabled && visibleTeams.isNotEmpty
                      ? () => _selectAllVisible(visibleTeams)
                      : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Todos'),
                ),
                TextButton(
                  onPressed: widget.enabled && selectedCount > 0 ? _clearSelection : null,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Limpar'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: widget.searchController,
              enabled: widget.enabled,
              decoration: const InputDecoration(
                labelText: 'Pesquisar times',
                hintText: 'Ex.: Brasil, Portugal…',
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            if (visibleTeams.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Nenhum time encontrado.',
                  style: AppTextStyles.sub(context),
                  textAlign: TextAlign.center,
                ),
              )
            else
              SizedBox(
                height: widget.maxGridHeight,
                child: GridView.builder(
                  padding: EdgeInsets.zero,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                    mainAxisExtent: 44,
                  ),
                  itemCount: visibleTeams.length,
                  itemBuilder: (context, index) {
                    final team = visibleTeams[index];
                    final selected = widget.selectedTeamIds.contains(team.id);
                    return _TeamChipTile(
                      team: team,
                      selected: selected,
                      enabled: widget.enabled,
                      onTap: () => _toggleTeam(team.id),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _TeamChipTile extends StatelessWidget {
  const _TeamChipTile({
    required this.team,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final TournamentTeam team;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    final background = selected ? colors.accentLight : colors.phoneSurfaceHover;
    final borderColor = selected ? colors.accent : colors.phoneBorder;
    final textColor = selected ? colors.accent : colors.phoneFg;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              children: [
                TeamFlag(teamId: team.id, crestUrl: team.crest, size: 18),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    team.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
