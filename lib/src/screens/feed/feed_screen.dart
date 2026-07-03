import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/match.dart';
import '../match/match_details_screen.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  static const routePath = '/feed';

  @override
  Widget build(BuildContext context) {
    final groupId = appState(context).currentGroupId;
    final repos = appRepos(context);

    if (groupId == null || repos == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Jogos')),
        body: const Center(
          child: Text('Selecione um grupo para ver o feed de jogos.'),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Jogos'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Ativos'),
              Tab(text: 'Arquivados'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GroupMatchList(
              groupId: groupId,
              excludedByFilter: false,
              emptyMessage: 'Nenhum jogo ativo no grupo.',
            ),
            _GroupMatchList(
              groupId: groupId,
              excludedByFilter: true,
              descending: true,
              emptyMessage: 'Nenhum jogo arquivado.',
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupMatchList extends StatelessWidget {
  const _GroupMatchList({
    required this.groupId,
    required this.excludedByFilter,
    required this.emptyMessage,
    this.descending = false,
  });

  final String groupId;
  final bool excludedByFilter;
  final String emptyMessage;
  final bool descending;

  @override
  Widget build(BuildContext context) {
    final repos = appRepos(context);
    if (repos == null) {
      return const Center(child: Text('Firebase não configurado.'));
    }

    return StreamBuilder<List<GroupMatchOverlay>>(
      stream: repos.firestore.watchGroupMatches(
        groupId: groupId,
        excludedByFilter: excludedByFilter,
        descending: descending,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final matches = snapshot.data!;
        if (matches.isEmpty) {
          return Center(child: Text(emptyMessage));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final match = matches[index];
            return _MatchTile(match: match);
          },
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final GroupMatchOverlay match;

  @override
  Widget build(BuildContext context) {
    final local = match.matchTimeUtc.toLocal();
    final timeLabel =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    return Card(
      child: ListTile(
        title: Text('${match.homeTeamId} x ${match.awayTeamId}'),
        subtitle: Text('$timeLabel · ${match.stage} · ${match.status.name}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(
          MatchDetailsScreen.routePathFor(matchId: match.matchId),
        ),
      ),
    );
  }
}
