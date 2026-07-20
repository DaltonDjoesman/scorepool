import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/prediction.dart';
import 'package:worldcupbettracker_app/src/utils/prediction_input.dart';
import 'package:worldcupbettracker_app/src/utils/team_metadata.dart';

void main() {
  group('parsePredictionScores', () {
    test('both empty yields null scores', () {
      final result = parsePredictionScores(homeText: '', awayText: '  ');
      expect(result.isOk, isTrue);
      expect(result.scores!.home, isNull);
      expect(result.scores!.away, isNull);
    });

    test('partial fill is an error', () {
      final result = parsePredictionScores(homeText: '1', awayText: '');
      expect(result.error, PredictionParseError.partialFill);
    });

    test('negative or non-integer is invalid', () {
      expect(
        parsePredictionScores(homeText: '-1', awayText: '0').error,
        PredictionParseError.invalidScore,
      );
      expect(
        parsePredictionScores(homeText: 'a', awayText: '1').error,
        PredictionParseError.invalidScore,
      );
    });

    test('valid pair parses non-negative ints', () {
      final result = parsePredictionScores(homeText: '2', awayText: '0');
      expect(result.isOk, isTrue);
      expect(result.scores!.home, 2);
      expect(result.scores!.away, 0);
    });
  });

  group('formatPredictionLabel', () {
    test('formats scores or Sem palpite', () {
      expect(formatPredictionLabel(null), 'Sem palpite');
      expect(
        formatPredictionLabel(
          Prediction(
            id: 'p',
            groupId: 'g',
            uid: 'u',
            matchId: 'm',
            predictedHomeScore: 1,
            predictedAwayScore: 2,
          ),
        ),
        '1 x 2',
      );
    });
  });

  group('syncPredictionControllers', () {
    testWidgets('updates text unless saving', (tester) async {
      final home = TextEditingController(text: '9');
      final away = TextEditingController(text: '9');
      final prediction = Prediction(
        id: 'p',
        groupId: 'g',
        uid: 'u',
        matchId: 'm',
        predictedHomeScore: 1,
        predictedAwayScore: 0,
      );

      syncPredictionControllers(
        prediction: prediction,
        homeController: home,
        awayController: away,
        isSaving: true,
      );
      expect(home.text, '9');

      syncPredictionControllers(
        prediction: prediction,
        homeController: home,
        awayController: away,
        isSaving: false,
      );
      expect(home.text, '1');
      expect(away.text, '0');

      home.dispose();
      away.dispose();
    });
  });

  group('TeamMetadata', () {
    test('label and iso2 share one entry source', () {
      expect(TeamMetadata.label('BRA'), 'Brasil');
      expect(TeamMetadata.iso2ForTeamId('BRA'), 'BR');
      expect(TeamMetadata.label('TBD_1_H'), 'A definir');
      expect(TeamMetadata.iso2ForTeamId('TBD_1_H'), isNull);
    });
  });
}
