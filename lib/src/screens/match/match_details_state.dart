import 'dart:async';

import '../../models/group.dart';
import '../../models/match.dart';
import '../../models/member.dart';
import '../../models/prediction.dart';
import '../../models/round_participation.dart';
import '../../repositories/groups_repository.dart';
import '../../repositories/matches_repository.dart';
import '../../repositories/predictions_repository.dart';
import '../../repositories/profiles_repository.dart';

/// Composed Firestore inputs for the match details screen.
class MatchDetailsData {
  const MatchDetailsData({
    required this.group,
    required this.match,
    required this.participation,
    required this.prediction,
    required this.members,
    required this.participations,
  });

  final Group group;
  final GroupMatchOverlay match;
  final RoundParticipation? participation;
  final Prediction? prediction;
  final List<MemberProfile> members;
  final Map<String, bool> participations;

  Map<String, String> get memberNames => {
        for (final member in members) member.uid: member.displayName,
      };
}

sealed class MatchDetailsSnapshot {
  const MatchDetailsSnapshot();
}

class MatchDetailsLoading extends MatchDetailsSnapshot {
  const MatchDetailsLoading();
}

class MatchDetailsError extends MatchDetailsSnapshot {
  const MatchDetailsError(this.error);

  final Object error;
}

class MatchDetailsReady extends MatchDetailsSnapshot {
  const MatchDetailsReady(this.data);

  final MatchDetailsData data;
}

class MatchDetailsMissing extends MatchDetailsSnapshot {
  const MatchDetailsMissing({required this.message});

  final String message;
}

/// Combines match-details input streams (testable without Firestore).
Stream<MatchDetailsSnapshot> combineMatchDetailsStreams({
  required Stream<Group?> groupStream,
  required Stream<GroupMatchOverlay?> matchStream,
  required Stream<RoundParticipation?> participationStream,
  required Stream<Prediction?> predictionStream,
  required Stream<List<MemberProfile>> membersStream,
  required Stream<Map<String, bool>> participationsStream,
}) {
  late StreamController<MatchDetailsSnapshot> controller;
  final subscriptions = <StreamSubscription<dynamic>>[];

  Group? group;
  var groupResolved = false;
  GroupMatchOverlay? match;
  var matchResolved = false;
  RoundParticipation? participation;
  Prediction? prediction;
  List<MemberProfile> members = const [];
  Map<String, bool> participations = const {};
  Object? lastError;
  String? missingMessage;

  void emit() {
    if (controller.isClosed) return;
    if (lastError != null) {
      controller.add(MatchDetailsError(lastError!));
      return;
    }
    if (missingMessage != null) {
      controller.add(MatchDetailsMissing(message: missingMessage!));
      return;
    }
    if (!groupResolved || !matchResolved) {
      controller.add(const MatchDetailsLoading());
      return;
    }
    if (group == null) {
      controller.add(const MatchDetailsMissing(message: 'Grupo não encontrado.'));
      return;
    }
    if (match == null) {
      controller.add(
        const MatchDetailsMissing(message: 'Jogo não encontrado no grupo.'),
      );
      return;
    }

    controller.add(
      MatchDetailsReady(
        MatchDetailsData(
          group: group!,
          match: match!,
          participation: participation,
          prediction: prediction,
          members: members,
          participations: participations,
        ),
      ),
    );
  }

  void onError(Object error, StackTrace stackTrace) {
    lastError = error;
    emit();
  }

  controller = StreamController<MatchDetailsSnapshot>(
    onListen: () {
      controller.add(const MatchDetailsLoading());

      subscriptions.add(
        groupStream.listen((value) {
          group = value;
          groupResolved = true;
          if (value == null) {
            missingMessage = 'Grupo não encontrado.';
          } else if (missingMessage == 'Grupo não encontrado.') {
            missingMessage = null;
          }
          emit();
        }, onError: onError),
      );

      subscriptions.add(
        matchStream.listen((value) {
          match = value;
          matchResolved = true;
          if (value == null) {
            missingMessage = 'Jogo não encontrado no grupo.';
          } else if (missingMessage == 'Jogo não encontrado no grupo.') {
            missingMessage = null;
          }
          emit();
        }, onError: onError),
      );

      subscriptions.add(
        participationStream.listen((value) {
          participation = value;
          emit();
        }, onError: onError),
      );

      subscriptions.add(
        predictionStream.listen((value) {
          prediction = value;
          emit();
        }, onError: onError),
      );

      subscriptions.add(
        membersStream.listen((value) {
          members = value;
          emit();
        }, onError: onError),
      );

      subscriptions.add(
        participationsStream.listen((value) {
          participations = value;
          emit();
        }, onError: onError),
      );
    },
    onCancel: () async {
      for (final sub in subscriptions) {
        await sub.cancel();
      }
      subscriptions.clear();
    },
  );

  return controller.stream;
}

/// Wires repository streams into [combineMatchDetailsStreams].
Stream<MatchDetailsSnapshot> watchMatchDetails({
  required GroupsRepository groups,
  required MatchesRepository matches,
  required PredictionsRepository predictions,
  required ProfilesRepository profiles,
  required String groupId,
  required String matchId,
  required String uid,
}) {
  return combineMatchDetailsStreams(
    groupStream: groups.watchGroup(groupId),
    matchStream: matches.watchGroupMatch(groupId: groupId, matchId: matchId),
    participationStream: predictions.watchRoundParticipation(
      groupId: groupId,
      matchId: matchId,
      uid: uid,
    ),
    predictionStream: predictions.watchPrediction(
      groupId: groupId,
      uid: uid,
      matchId: matchId,
    ),
    membersStream: profiles.watchMembers(groupId),
    participationsStream: predictions.watchMatchParticipations(
      groupId: groupId,
      matchId: matchId,
    ),
  );
}
