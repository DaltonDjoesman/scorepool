import 'package:flutter/material.dart';

import '../../app.dart';
import '../../routing/navigation_helpers.dart';
import '../../models/group.dart';
import '../../models/match.dart';
import '../../models/prediction.dart';
import '../../models/round_participation.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/match_lock.dart';
import '../../widgets/app_card.dart';
import '../../models/match_status.dart';
import '../../utils/pot_calculator.dart';
import 'group_predictions_list.dart';
import 'lock_countdown_banner.dart';
import 'match_hero_card.dart';
import 'participant_transparency_list.dart';
import 'payment_ledger_card.dart';
import 'prediction_input_card.dart';
import '../shell/feed_shell_screen.dart';

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
      body: SafeArea(
        child: StreamBuilder<Group?>(
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

                      return StreamBuilder(
                        stream: repos.firestore.watchMembers(groupId),
                        builder: (context, membersSnap) {
                          final memberNames = <String, String>{
                            for (final member in membersSnap.data ?? [])
                              member.uid: member.displayName,
                          };

                      return StreamBuilder<Map<String, bool>>(
                        stream: repos.firestore.watchMatchParticipations(
                          groupId: groupId,
                          matchId: widget.matchId,
                        ),
                        builder: (context, participationsSnap) {
                          final participations = participationsSnap.data ?? {};
                          final members = membersSnap.data ?? [];
                          final inPotCount = PotCalculator.countInPotParticipants(
                            memberCount: members.length,
                            participationByUid: participations,
                          );
                          final isFinished =
                              match.status == MatchStatus.finished;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _DetailsHeader(
                                onBack: () => navigateBack(
                                  context,
                                  fallback: FeedShellScreen.routePath,
                                ),
                              ),
                              Expanded(
                                child: ListView(
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    MatchHeroCard(
                                      match: match,
                                      currency: group.currency,
                                      memberNames: memberNames,
                                      entryFeeCents: group.entryFeeCents,
                                      inPotParticipantCount: inPotCount,
                                    ),
                                    if (match.status.name == 'scheduled') ...[
                                      const SizedBox(height: 16),
                                      LockCountdownBanner(
                                        match: match,
                                        predictionLockMinutes: group.predictionLockMinutes,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    AppCard(
                                      child: PredictionInputCard(
                                        repos: repos,
                                        groupId: groupId,
                                        uid: uid,
                                        match: match,
                                        canEdit: canChange,
                                        prediction: prediction,
                                        embedded: true,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _ParticipationCard(
                                      isInPot: isInPot,
                                      optedOutAt: participation?.optedOutAt,
                                      canChange: canChange && !_savingParticipation,
                                      saving: _savingParticipation,
                                      error: _participationError,
                                      entryFeeCents: group.entryFeeCents,
                                      currency: group.currency,
                                      onChanged: (value) => _setParticipation(
                                        groupId: groupId,
                                        uid: uid,
                                        isInPot: value,
                                      ),
                                    ),
                                    if (shouldShowGroupPredictions(
                                      match: match,
                                      predictionLockMinutes: group.predictionLockMinutes,
                                    )) ...[
                                      const SizedBox(height: 16),
                                      AppCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                          children: [
                                            Text(
                                              'Palpites do Grupo',
                                              style: AppTextStyles.body(
                                                context,
                                                weight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            GroupPredictionsList(
                                              repos: repos,
                                              groupId: groupId,
                                              matchId: widget.matchId,
                                              match: match,
                                              memberNames: memberNames,
                                              currentUid: uid,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    if (!isFinished) ...[
                                      const SizedBox(height: 16),
                                      ParticipantTransparencyList(
                                        repos: repos,
                                        groupId: groupId,
                                        matchId: widget.matchId,
                                        memberNames: memberNames,
                                        currentUid: uid,
                                      ),
                                    ],
                                    if (isFinished) ...[
                                      const SizedBox(height: 16),
                                      PaymentLedgerCard(
                                        repos: repos,
                                        groupId: groupId,
                                        matchId: widget.matchId,
                                        match: match,
                                        currentUid: uid,
                                        currency: group.currency,
                                        memberNames: memberNames,
                                        entryFeeCents: group.entryFeeCents,
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    Text(
                                      'Este opt-out vale só para este jogo.',
                                      style: AppTextStyles.sub(context),
                                    ),
                                  ],
                                ),
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
              );
            },
          );
        },
      ),
    ),
    );
  }
}

class _DetailsHeader extends StatelessWidget {
  const _DetailsHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(Icons.chevron_left, color: colors.accent),
          ),
          Text('DETALHES DO JOGO', style: AppTextStyles.titleCaps(context)),
        ],
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
    required this.entryFeeCents,
    required this.currency,
    this.optedOutAt,
    this.error,
  });

  final bool isInPot;
  final bool canChange;
  final bool saving;
  final int entryFeeCents;
  final String currency;
  final DateTime? optedOutAt;
  final String? error;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Participar do pote',
                      style: AppTextStyles.body(context, weight: FontWeight.w700),
                    ),
                    Text(
                      'Custo de $currency ${(entryFeeCents / 100).toStringAsFixed(2)} se participar.',
                      style: AppTextStyles.sub(context),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isInPot,
                onChanged: canChange && !saving ? onChanged : null,
              ),
            ],
          ),
          if (!isInPot) ...[
            const SizedBox(height: 8),
            Text(
              'Fora do pote${optedOutAt != null ? ' (opt-out em ${optedOutAt!.toLocal()})' : ''}',
              style: TextStyle(
                fontSize: 12,
                color: colors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: TextStyle(color: colors.danger)),
          ],
        ],
      ),
    );
  }
}
