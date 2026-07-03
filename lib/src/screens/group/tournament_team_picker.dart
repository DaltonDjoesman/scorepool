import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/tournament_team.dart';
import '../../widgets/team_flag.dart';

class TournamentTeamPicker extends StatefulWidget {
  const TournamentTeamPicker({
    super.key,
    required this.tournamentId,
    required this.searchController,
    required this.selectedTeamIds,
    required this.enabled,
    required this.onSelectionChanged,
  });

  final String tournamentId;
  final TextEditingController searchController;
  final Set<String> selectedTeamIds;
  final bool enabled;
  final VoidCallback onSelectionChanged;

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

        final teams = snapshot.data ?? const <TournamentTeam>[];
        if (teams.isEmpty) {
          return const Text(
            'Nenhum time no catálogo da Copa. Aguarde a sincronização dos jogos.',
          );
        }

        final query = widget.searchController.text.trim().toLowerCase();
        final filtered = teams.where((team) {
          if (query.isEmpty) return true;
          return team.name.toLowerCase().contains(query) ||
              team.id.toLowerCase().contains(query);
        });

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final team in filtered)
              FilterChip(
                avatar: TeamFlag(teamId: team.id, crestUrl: team.crest, size: 20),
                label: Text(team.name),
                selected: widget.selectedTeamIds.contains(team.id),
                onSelected: widget.enabled
                    ? (selected) {
                        setState(() {
                          if (selected) {
                            widget.selectedTeamIds.add(team.id);
                          } else {
                            widget.selectedTeamIds.remove(team.id);
                          }
                        });
                        widget.onSelectionChanged();
                      }
                    : null,
              ),
          ],
        );
      },
    );
  }
}
