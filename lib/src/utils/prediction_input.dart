import 'package:flutter/widgets.dart';

import '../models/prediction.dart';
import '../repositories/predictions_repository.dart';

enum PredictionParseError { partialFill, invalidScore }

class ParsedPredictionScores {
  const ParsedPredictionScores({this.home, this.away});

  final int? home;
  final int? away;
}

class PredictionParseResult {
  const PredictionParseResult.ok(this.scores) : error = null;
  const PredictionParseResult.error(this.error) : scores = null;

  final ParsedPredictionScores? scores;
  final PredictionParseError? error;

  bool get isOk => error == null;
}

/// Parse two score text fields: both empty → nulls; both filled → non-negative ints.
PredictionParseResult parsePredictionScores({
  required String homeText,
  required String awayText,
}) {
  final homeEmpty = homeText.trim().isEmpty;
  final awayEmpty = awayText.trim().isEmpty;

  if (homeEmpty && awayEmpty) {
    return const PredictionParseResult.ok(ParsedPredictionScores());
  }

  if (homeEmpty != awayEmpty) {
    return const PredictionParseResult.error(PredictionParseError.partialFill);
  }

  final home = int.tryParse(homeText.trim());
  final away = int.tryParse(awayText.trim());
  if (home == null || away == null || home < 0 || away < 0) {
    return const PredictionParseResult.error(PredictionParseError.invalidScore);
  }

  return PredictionParseResult.ok(
    ParsedPredictionScores(home: home, away: away),
  );
}

String predictionParseErrorMessage(PredictionParseError error) {
  return switch (error) {
    PredictionParseError.partialFill =>
      'Preencha os dois placares ou deixe ambos vazios.',
    PredictionParseError.invalidScore => 'Use números inteiros ≥ 0.',
  };
}

String predictionControllerText(int? score) => score?.toString() ?? '';

String predictionSyncKey(Prediction? prediction) =>
    '${prediction?.predictedHomeScore}_${prediction?.predictedAwayScore}';

/// Sync controllers from stream/back-end prediction; skip while saving.
void syncPredictionControllers({
  required Prediction? prediction,
  required TextEditingController homeController,
  required TextEditingController awayController,
  required bool isSaving,
}) {
  if (isSaving) return;
  final home = predictionControllerText(prediction?.predictedHomeScore);
  final away = predictionControllerText(prediction?.predictedAwayScore);
  if (homeController.text != home) homeController.text = home;
  if (awayController.text != away) awayController.text = away;
}

/// Sync with a loaded-key guard so identical stream emissions do not overwrite edits.
String? syncPredictionControllersDeduped({
  required Prediction? prediction,
  required TextEditingController homeController,
  required TextEditingController awayController,
  required bool isSaving,
  required String? lastSyncedKey,
}) {
  final key = predictionSyncKey(prediction);
  if (lastSyncedKey == key || isSaving) return lastSyncedKey;
  homeController.text = predictionControllerText(prediction?.predictedHomeScore);
  awayController.text = predictionControllerText(prediction?.predictedAwayScore);
  return key;
}

Future<void> persistPrediction({
  required PredictionsRepository predictions,
  required String groupId,
  required String uid,
  required String matchId,
  required int? predictedHomeScore,
  required int? predictedAwayScore,
}) {
  return predictions.upsertPrediction(
    groupId: groupId,
    uid: uid,
    matchId: matchId,
    predictedHomeScore: predictedHomeScore,
    predictedAwayScore: predictedAwayScore,
  );
}

String formatPredictionLabel(Prediction? prediction) {
  final home = prediction?.predictedHomeScore;
  final away = prediction?.predictedAwayScore;
  if (home == null || away == null) return 'Sem palpite';
  return '$home x $away';
}
