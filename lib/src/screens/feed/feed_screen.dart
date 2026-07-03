import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../../models/match.dart';
import '../../models/match_status.dart';
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
            _ActiveFeed(groupId: groupId),
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

class _ActiveFeed extends StatelessWidget {
  const _ActiveFeed({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const TabBar(
              tabs: [
                Tab(text: 'Próximos'),
                Tab(text: 'Ao vivo'),
                Tab(text: 'Encerrados'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _GroupMatchList(
                  groupId: groupId,
                  excludedByFilter: false,
                  status: MatchStatus.scheduled,
                  emptyMessage: 'Nenhum jogo próximo.',
                ),
                _GroupMatchList(
                  groupId: groupId,
                  excludedByFilter: false,
                  status: MatchStatus.live,
                  emptyMessage: 'Nenhum jogo ao vivo.',
                ),
                _GroupMatchList(
                  groupId: groupId,
                  excludedByFilter: false,
                  status: MatchStatus.finished,
                  descending: true,
                  emptyMessage: 'Nenhum jogo encerrado.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupMatchList extends StatelessWidget {
  const _GroupMatchList({
    required this.groupId,
    required this.excludedByFilter,
    required this.emptyMessage,
    this.status,
    this.descending = false,
  });

  final String groupId;
  final bool excludedByFilter;
  final String emptyMessage;
  final MatchStatus? status;
  final bool descending;

  @override
  Widget build(BuildContext context) {
    final repos = appRepos(context);
    if (repos == null) {
      return const Center(child: Text('Firebase não configurado.'));
    }

    return StreamBuilder(
      stream: repos.firestore.watchMembers(groupId),
      builder: (context, membersSnap) {
        final memberNames = <String, String>{
          for (final member in membersSnap.data ?? [])
            member.uid: member.displayName,
        };

        return StreamBuilder<Group?>(
          stream: repos.firestore.watchGroup(groupId),
          builder: (context, groupSnap) {
            final currency = groupSnap.data?.currency ?? 'BRL';

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

                final matches = status == null
                    ? snapshot.data!
                    : snapshot.data!
                          .where((match) => match.status == status)
                          .toList(growable: false);

                if (matches.isEmpty) {
                  return Center(child: Text(emptyMessage));
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: matches.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    return _MatchTile(
                      match: matches[index],
                      memberNames: memberNames,
                      currency: currency,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({
    required this.match,
    required this.memberNames,
    required this.currency,
  });

  final GroupMatchOverlay match;
  final Map<String, String> memberNames;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final local = match.matchTimeUtc.toLocal();
    final timeLabel =
        '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';

    final isFinished = match.status == MatchStatus.finished;
    final hasWinners = match.winnerUids.isNotEmpty;
    final hasAccumulation = match.accumulatedFromPreviousCents > 0;

    return Card(
      color: isFinished && hasWinners
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: InkWell(
        onTap: () => context.go(
          MatchDetailsScreen.routePathFor(matchId: match.matchId),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${match.homeTeamId} x ${match.awayTeamId}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 4),
              Text('$timeLabel · ${match.stage} · ${match.status.name}'),
              if (hasAccumulation) ...[
                const SizedBox(height: 8),
                Text(
                  'Inclui ${_formatMoney(match.accumulatedFromPreviousCents)} acumulados de jogos anteriores',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.tertiary,
                  ),
                ),
              ],
              if (isFinished) ...[
                const SizedBox(height: 8),
                if (hasWinners)
                  Text(
                    'Vencedores: ${match.winnerUids.map((uid) => memberNames[uid] ?? uid).join(', ')}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Sem vencedores — pote acumulado',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                if (match.totalPotCents != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pote total: ${_formatMoney(match.totalPotCents!)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatMoney(int cents) {
    return '$currency ${(cents / 100).toStringAsFixed(2)}';
  }
}
