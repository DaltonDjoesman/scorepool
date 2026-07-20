import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/group.dart';
import 'package:worldcupbettracker_app/src/models/match.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/models/member.dart';
import 'package:worldcupbettracker_app/src/models/prediction.dart';
import 'package:worldcupbettracker_app/src/models/round_participation.dart';
import 'package:worldcupbettracker_app/src/screens/match/match_details_state.dart';

Group _group() => Group(
      id: 'g1',
      name: 'Bolão',
      currency: 'BRL',
      entryFeeCents: 1000,
      predictionLockMinutes: 15,
      adminUids: const ['u1'],
      matchFilter: GroupMatchFilter(teamIds: const [], stages: const []),
      carryOverPotCents: 0,
    );

GroupMatchOverlay _match() => GroupMatchOverlay(
      matchId: 'm1',
      groupId: 'g1',
      excludedByFilter: false,
      lockedInGroup: false,
      winnerUids: const [],
      accumulatedFromPreviousCents: 0,
      status: MatchStatus.scheduled,
      matchTimeUtc: DateTime.utc(2026, 6, 15, 18),
      homeTeamId: 'BRA',
      awayTeamId: 'ARG',
      stage: 'Grupo A',
    );

void main() {
  test('combineMatchDetailsStreams emits ready once group and match arrive', () async {
    final groupCtrl = StreamController<Group?>();
    final matchCtrl = StreamController<GroupMatchOverlay?>();
    final participationCtrl = StreamController<RoundParticipation?>();
    final predictionCtrl = StreamController<Prediction?>();
    final membersCtrl = StreamController<List<MemberProfile>>();
    final participationsCtrl = StreamController<Map<String, bool>>();

    final events = <MatchDetailsSnapshot>[];
    final sub = combineMatchDetailsStreams(
      groupStream: groupCtrl.stream,
      matchStream: matchCtrl.stream,
      participationStream: participationCtrl.stream,
      predictionStream: predictionCtrl.stream,
      membersStream: membersCtrl.stream,
      participationsStream: participationsCtrl.stream,
    ).listen(events.add);

    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<MatchDetailsLoading>(), isNotEmpty);

    groupCtrl.add(_group());
    await Future<void>.delayed(Duration.zero);
    expect(events.last, isA<MatchDetailsLoading>());

    matchCtrl.add(_match());
    await Future<void>.delayed(Duration.zero);
    expect(events.last, isA<MatchDetailsReady>());

    final ready = events.last as MatchDetailsReady;
    expect(ready.data.group.id, 'g1');
    expect(ready.data.match.matchId, 'm1');

    await sub.cancel();
    await groupCtrl.close();
    await matchCtrl.close();
    await participationCtrl.close();
    await predictionCtrl.close();
    await membersCtrl.close();
    await participationsCtrl.close();
  });

  test('combineMatchDetailsStreams surfaces stream errors', () async {
    final groupCtrl = StreamController<Group?>();
    final matchCtrl = StreamController<GroupMatchOverlay?>();
    final participationCtrl = StreamController<RoundParticipation?>();
    final predictionCtrl = StreamController<Prediction?>();
    final membersCtrl = StreamController<List<MemberProfile>>();
    final participationsCtrl = StreamController<Map<String, bool>>();

    final events = <MatchDetailsSnapshot>[];
    final sub = combineMatchDetailsStreams(
      groupStream: groupCtrl.stream,
      matchStream: matchCtrl.stream,
      participationStream: participationCtrl.stream,
      predictionStream: predictionCtrl.stream,
      membersStream: membersCtrl.stream,
      participationsStream: participationsCtrl.stream,
    ).listen(events.add);

    groupCtrl.addError(StateError('boom'));
    await Future<void>.delayed(Duration.zero);

    expect(events.last, isA<MatchDetailsError>());
    expect((events.last as MatchDetailsError).error.toString(), contains('boom'));

    await sub.cancel();
    await groupCtrl.close();
    await matchCtrl.close();
    await participationCtrl.close();
    await predictionCtrl.close();
    await membersCtrl.close();
    await participationsCtrl.close();
  });
}
