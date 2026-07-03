import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../models/member.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/match_lock.dart';
import '../../utils/match_score_display.dart';

class GroupPredictionsList extends StatelessWidget {
  const GroupPredictionsList({
    super.key,
    required this.repos,
    required this.groupId,
    required this.matchId,
    required this.match,
    required this.memberNames,
    this.currentUid,
  });

  final Repositories repos;
  final String groupId;
  final String matchId;
  final GroupMatchOverlay match;
  final Map<String, String> memberNames;
  final String? currentUid;

  String _nameFor(String uid) => memberNames[uid] ?? uid;

  String _formatPrediction(Prediction? prediction) {
    if (prediction == null) return 'Sem palpite';
    final home = prediction.predictedHomeScore;
    final away = prediction.predictedAwayScore;
    if (home == null || away == null) return 'Sem palpite';
    return '$home x $away';
  }

  bool? _isCorrect(Prediction? prediction) {
    if (match.status != MatchStatus.finished || !match.hasScoreline) return null;
    if (prediction == null) return null;
    return prediction.predictedHomeScore == match.homeScore &&
        prediction.predictedAwayScore == match.awayScore;
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return StreamBuilder<List<MemberProfile>>(
      stream: repos.firestore.watchMembers(groupId),
      builder: (context, membersSnap) {
        final members = membersSnap.data ?? [];
        if (membersSnap.connectionState == ConnectionState.waiting &&
            !membersSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        return StreamBuilder<Map<String, bool>>(
          stream: repos.firestore.watchMatchParticipations(
            groupId: groupId,
            matchId: matchId,
          ),
          builder: (context, partSnap) {
            final participations = partSnap.data ?? {};

            return StreamBuilder<List<Prediction>>(
              stream: repos.firestore.watchMatchPredictions(
                groupId: groupId,
                matchId: matchId,
              ),
              builder: (context, predSnap) {
                final predictionsByUid = {
                  for (final p in predSnap.data ?? []) p.uid: p,
                };

                final sorted = [...members]
                  ..sort((a, b) => _nameFor(a.uid).compareTo(_nameFor(b.uid)));

                if (sorted.isEmpty) {
                  return Text(
                    'Nenhum membro no grupo.',
                    style: AppTextStyles.sub(context),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sorted.map((member) {
                    final isMe = member.uid == currentUid;
                    final inPot = participations[member.uid] ?? true;
                    final prediction = predictionsByUid[member.uid];
                    final correct = _isCorrect(prediction);

                    final rightLabel = !inPot
                        ? '🚫 Fora do Pote'
                        : _formatPrediction(prediction);

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${_nameFor(member.uid)}${isMe ? ' (Você)' : ''}',
                              style: TextStyle(
                                fontWeight: isMe ? FontWeight.w700 : FontWeight.w400,
                                color: isMe ? colors.accent : colors.phoneFg,
                              ),
                            ),
                          ),
                          if (correct == true)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text('✅', style: TextStyle(color: colors.success)),
                            )
                          else if (correct == false && inPot)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Text('❌', style: TextStyle(color: colors.danger)),
                            ),
                          Text(
                            rightLabel,
                            style: AppTextStyles.body(
                              context,
                              weight: FontWeight.w600,
                            ).copyWith(
                              color: inPot ? colors.phoneFg : colors.phoneMuted,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            );
          },
        );
      },
    );
  }
}

bool shouldShowGroupPredictions({
  required GroupMatchOverlay match,
  required int predictionLockMinutes,
}) {
  if (match.status == MatchStatus.finished) return true;
  return !isBeforeLock(
    match: match,
    predictionLockMinutes: predictionLockMinutes,
  );
}
