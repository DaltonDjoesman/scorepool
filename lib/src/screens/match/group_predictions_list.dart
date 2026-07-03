import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';
import '../../utils/match_lock.dart';

class GroupPredictionsList extends StatelessWidget {
  const GroupPredictionsList({
    super.key,
    required this.repos,
    required this.groupId,
    required this.matchId,
    required this.memberNames,
  });

  final Repositories repos;
  final String groupId;
  final String matchId;
  final Map<String, String> memberNames;

  String _nameFor(String uid) => memberNames[uid] ?? uid;

  String _formatPrediction(Prediction prediction) {
    final home = prediction.predictedHomeScore;
    final away = prediction.predictedAwayScore;
    if (home == null || away == null) return 'Sem palpite';
    return '$home x $away';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Prediction>>(
      stream: repos.firestore.watchMatchPredictions(
        groupId: groupId,
        matchId: matchId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(snapshot.error.toString());
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final predictions = [...snapshot.data!]
          ..sort((a, b) => _nameFor(a.uid).compareTo(_nameFor(b.uid)));

        if (predictions.isEmpty) {
          return const Text('Ninguém palpitou neste jogo ainda.');
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: predictions.map((prediction) {
            return ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_nameFor(prediction.uid)),
              trailing: Text(
                _formatPrediction(prediction),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }
}

bool shouldShowGroupPredictions({
  required GroupMatchOverlay match,
  required int predictionLockMinutes,
}) {
  if (match.status != MatchStatus.live) return false;
  return !isBeforeLock(
    match: match,
    predictionLockMinutes: predictionLockMinutes,
  );
}
