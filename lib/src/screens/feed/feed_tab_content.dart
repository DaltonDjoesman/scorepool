import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../utils/pot_calculator.dart';
import '../../utils/world_cup_standings.dart';
import 'match_feed_card.dart';
import 'world_cup_complete_banner.dart';

/// Feed tab body used inside [FeedShellScreen].
class FeedTabContent extends StatefulWidget {
  const FeedTabContent({super.key, required this.groupId});

  final String groupId;

  @override
  State<FeedTabContent> createState() => _FeedTabContentState();
}

class _FeedTabContentState extends State<FeedTabContent> {
  bool _showArchived = false;
  int _activeSubTab = 0;

  @override
  Widget build(BuildContext context) {
    final repos = appRepos(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (repos != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: _WorldCupFinaleSection(repos: repos),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(child: _FeedToggleButton(
                label: 'Jogos Ativos',
                selected: !_showArchived,
                onTap: () => setState(() => _showArchived = false),
              )),
              const SizedBox(width: 8),
              Expanded(child: _FeedToggleButton(
                label: 'Arquivados',
                selected: _showArchived,
                onTap: () => setState(() => _showArchived = true),
              )),
            ],
          ),
        ),
        if (!_showArchived)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
                      child: _SubTabButton(
                        label: const ['Próximos', 'Ao vivo', 'Encerrados'][i],
                        selected: _activeSubTab == i,
                        onTap: () => setState(() => _activeSubTab = i),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        Expanded(
          child: _GroupMatchList(
            groupId: widget.groupId,
            excludedByFilter: _showArchived,
            status: _showArchived
                ? MatchStatus.finished
                : switch (_activeSubTab) {
                    0 => MatchStatus.scheduled,
                    1 => MatchStatus.live,
                    2 => MatchStatus.finished,
                    _ => null,
                  },
            descending: _showArchived || _activeSubTab == 2,
            archived: _showArchived,
            emptyMessage: _showArchived
                ? 'Nenhum jogo encerrado fora do filtro.'
                : switch (_activeSubTab) {
                    0 => 'Nenhum jogo próximo.',
                    1 => 'Nenhum jogo ao vivo.',
                    2 => 'Nenhum jogo encerrado.',
                    _ => 'Nenhum jogo.',
                  },
          ),
        ),
      ],
    );
  }
}

class _WorldCupFinaleSection extends StatelessWidget {
  const _WorldCupFinaleSection({required this.repos});

  final Repositories repos;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: repos.matches.watchWorldCupFinished(),
      builder: (context, finishedSnap) {
        if (finishedSnap.data != true) return const SizedBox.shrink();

        return StreamBuilder<List<TournamentMatch>>(
          stream: repos.matches.watchCatalogMatchesByStage('final'),
          builder: (context, finalSnap) {
            return StreamBuilder<List<TournamentMatch>>(
              stream: repos.matches.watchCatalogMatchesByStage('third_place'),
              builder: (context, thirdSnap) {
                final standing = worldCupFinaleStanding(
                  finalMatch: finalSnap.data?.isNotEmpty == true
                      ? finalSnap.data!.first
                      : null,
                  thirdPlaceMatch: thirdSnap.data?.isNotEmpty == true
                      ? thirdSnap.data!.first
                      : null,
                );
                if (standing == null) return const SizedBox.shrink();
                return WorldCupCompleteBanner(standing: standing);
              },
            );
          },
        );
      },
    );
  }
}
class _FeedToggleButton extends StatelessWidget {
  const _FeedToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Material(
      color: selected
          ? colors.accentLight.withValues(alpha: 0.5)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.phoneBorder),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? colors.accent : colors.phoneMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _SubTabButton extends StatelessWidget {
  const _SubTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Material(
      color: selected ? colors.phoneSurfaceHover : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? colors.phoneFg : colors.phoneMuted,
            ),
          ),
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
    required this.archived,
    this.status,
    this.descending = false,
  });

  final String groupId;
  final bool excludedByFilter;
  final bool archived;
  final String emptyMessage;
  final MatchStatus? status;
  final bool descending;

  String _friendlyFeedError(Object? error) {
    if (error is FirebaseException && error.code == 'failed-precondition') {
      return 'O índice do Firestore ainda está sendo criado. '
          'Aguarde alguns minutos e abra o feed de novo.\n\n'
          'Se o erro persistir, rode: firebase deploy --only firestore:indexes';
    }
    if (error is FirebaseException) {
      final code = error.code.toLowerCase();
      if (code == 'unavailable' ||
          code == 'network-request-failed' ||
          code == 'unknown') {
        return 'Sem conexão com o Firebase/Firestore no momento.\n\n'
            'Confira a internet do aparelho/emulador (DNS/rede) e abra o feed de novo.';
      }
    }
    return error.toString();
  }

  @override
  Widget build(BuildContext context) {
    final repos = appRepos(context);
    final uid = appAuth(context)?.user?.uid;
    if (repos == null) {
      return const Center(child: Text('Firebase não configurado.'));
    }

    return StreamBuilder(
      stream: repos.profiles.watchMembers(groupId),
      builder: (context, membersSnap) {
        final memberNames = <String, String>{
          for (final member in membersSnap.data ?? [])
            member.uid: member.displayName,
        };

        return StreamBuilder<Group?>(
          stream: repos.groups.watchGroup(groupId),
          builder: (context, groupSnap) {
            final group = groupSnap.data;
            final currency = group?.currency ?? 'BRL';
            final lockMinutes = group?.predictionLockMinutes ?? 15;
            final entryFeeCents = group?.entryFeeCents ?? 0;
            final memberCount = (membersSnap.data ?? []).length;

            return StreamBuilder<List<GroupMatchOverlay>>(
              stream: repos.matches.watchGroupMatches(
                groupId: groupId,
                excludedByFilter: excludedByFilter,
                descending: descending,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        _friendlyFeedError(snapshot.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
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
                    final match = matches[index];
                    return _MatchFeedCardLoader(
                      groupId: groupId,
                      match: match,
                      memberNames: memberNames,
                      currency: currency,
                      predictionLockMinutes: lockMinutes,
                      entryFeeCents: entryFeeCents,
                      memberCount: memberCount,
                      repos: repos,
                      currentUid: uid,
                      archived: archived,
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

class _MatchFeedCardLoader extends StatelessWidget {
  const _MatchFeedCardLoader({
    required this.groupId,
    required this.match,
    required this.memberNames,
    required this.currency,
    required this.predictionLockMinutes,
    required this.entryFeeCents,
    required this.memberCount,
    required this.repos,
    required this.currentUid,
    required this.archived,
  });

  final String groupId;
  final GroupMatchOverlay match;
  final Map<String, String> memberNames;
  final String currency;
  final int predictionLockMinutes;
  final int entryFeeCents;
  final int memberCount;
  final Repositories repos;
  final String? currentUid;
  final bool archived;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, bool>>(
      stream: repos.predictions.watchMatchParticipations(
        groupId: groupId,
        matchId: match.matchId,
      ),
      builder: (context, partSnap) {
        final participations = partSnap.data ?? {};
        final inPotCount = PotCalculator.countInPotParticipants(
          memberCount: memberCount,
          participationByUid: participations,
        );

        if (currentUid == null) {
          return MatchFeedCard(
            groupId: groupId,
            match: match,
            memberNames: memberNames,
            currency: currency,
            predictionLockMinutes: predictionLockMinutes,
            entryFeeCents: entryFeeCents,
            inPotParticipantCount: inPotCount,
            repos: repos,
            currentUid: null,
            archived: archived,
          );
        }

        return StreamBuilder<Prediction?>(
          stream: repos.predictions.watchPrediction(
            groupId: groupId,
            uid: currentUid!,
            matchId: match.matchId,
          ),
          builder: (context, snap) {
            final prediction = snap.data;
            final canEdit = feedCardCanEditPrediction(
              match: match,
              predictionLockMinutes: predictionLockMinutes,
            );
            final locked = feedCardLockedForPredictions(
              match: match,
              predictionLockMinutes: predictionLockMinutes,
            );

            return MatchFeedCard(
              groupId: groupId,
              match: match,
              memberNames: memberNames,
              currency: currency,
              predictionLockMinutes: predictionLockMinutes,
              entryFeeCents: entryFeeCents,
              inPotParticipantCount: inPotCount,
              repos: repos,
              currentUid: currentUid,
              archived: archived,
              prediction: prediction,
              canEditPrediction: canEdit,
              lockedForPredictions: locked,
            );
          },
        );
      },
    );
  }
}
