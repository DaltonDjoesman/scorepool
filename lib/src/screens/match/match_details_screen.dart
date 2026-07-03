import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../../models/match.dart';
import '../../models/prediction.dart';
import '../../models/round_participation.dart';
import '../../utils/match_lock.dart';
import 'lock_countdown_banner.dart';
import 'prediction_input_card.dart';

class MatchDetailsScreen extends StatefulWidget {
  const MatchDetailsScreen({super.key, required this.matchId});

  static const routePath = '/match/:matchId';

  static String routePathFor({required String matchId}) => '/match/$matchId';

  final String matchId;

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _savingParticipation = false;
  String? _participationError;

  Future<void> _setParticipation({
    required String groupId,
    required String uid,
    required bool isInPot,
  }) async {
    final repos = appRepos(context);
    if (repos == null) return;

    setState(() {
      _savingParticipation = true;
      _participationError = null;
    });

    try {
      await repos.firestore.updateRoundParticipation(
        groupId: groupId,
        matchId: widget.matchId,
        uid: uid,
        isInPot: isInPot,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _participationError = e.toString());
    } finally {
      if (mounted) setState(() => _savingParticipation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupId = appState(context).currentGroupId;
    final auth = appAuth(context);
    final repos = appRepos(context);
    final uid = auth?.user?.uid;

    if (groupId == null || repos == null || uid == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes')),
        body: const Center(
          child: Text('Entre em um grupo e faça login para ver este jogo.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: StreamBuilder<Group?>(
        stream: repos.firestore.watchGroup(groupId),
        builder: (context, groupSnap) {
          final group = groupSnap.data;
          if (groupSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (group == null) {
            return const Center(child: Text('Grupo não encontrado.'));
          }

          return StreamBuilder<GroupMatchOverlay?>(
            stream: repos.firestore.watchGroupMatch(
              groupId: groupId,
              matchId: widget.matchId,
            ),
            builder: (context, matchSnap) {
              final match = matchSnap.data;
              if (matchSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (match == null) {
                return const Center(child: Text('Jogo não encontrado no grupo.'));
              }

              return StreamBuilder<RoundParticipation?>(
                stream: repos.firestore.watchRoundParticipation(
                  groupId: groupId,
                  matchId: widget.matchId,
                  uid: uid,
                ),
                builder: (context, participationSnap) {
                  final participation = participationSnap.data;
                  final isInPot = participation?.isInPot ?? true;
                  final canChange = isBeforeLock(
                    match: match,
                    predictionLockMinutes: group.predictionLockMinutes,
                  );

                  return StreamBuilder<Prediction?>(
                    stream: repos.firestore.watchPrediction(
                      groupId: groupId,
                      uid: uid,
                      matchId: widget.matchId,
                    ),
                    builder: (context, predictionSnap) {
                      final prediction = predictionSnap.data;

                      return ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            '${match.homeTeamId} x ${match.awayTeamId}',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('${match.stage} · ${match.status.name}'),
                          const SizedBox(height: 16),
                          LockCountdownBanner(
                            match: match,
                            predictionLockMinutes: group.predictionLockMinutes,
                          ),
                          const SizedBox(height: 24),
                          PredictionInputCard(
                            repos: repos,
                            groupId: groupId,
                            uid: uid,
                            match: match,
                            canEdit: canChange,
                            prediction: prediction,
                          ),
                          const SizedBox(height: 24),
                          _ParticipationCard(
                            isInPot: isInPot,
                            optedOutAt: participation?.optedOutAt,
                            canChange: canChange && !_savingParticipation,
                            saving: _savingParticipation,
                            error: _participationError,
                            onChanged: (value) => _setParticipation(
                              groupId: groupId,
                              uid: uid,
                              isInPot: value,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Este opt-out vale só para este jogo.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _ParticipationCard extends StatelessWidget {
  const _ParticipationCard({
    required this.isInPot,
    required this.canChange,
    required this.saving,
    required this.onChanged,
    this.optedOutAt,
    this.error,
  });

  final bool isInPot;
  final bool canChange;
  final bool saving;
  final DateTime? optedOutAt;
  final String? error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final statusLabel = isInPot ? 'No pote' : 'Fora do pote (opt-out)';
    final statusColor = isInPot
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.outline;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  isInPot ? Icons.savings_outlined : Icons.money_off_outlined,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            if (optedOutAt != null && !isInPot) ...[
              const SizedBox(height: 8),
              Text(
                'Opt-out em ${optedOutAt!.toLocal()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Participar do pote'),
              subtitle: canChange
                  ? const Text('Desative para não pagar neste jogo.')
                  : const Text('Trancado — não é possível alterar.'),
              value: isInPot,
              onChanged: canChange && !saving ? onChanged : null,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
