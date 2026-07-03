import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/member.dart';
import 'package:worldcupbettracker_app/src/screens/ranking/podium_widget.dart';
import 'package:worldcupbettracker_app/src/theme/app_theme.dart';

MemberProfile _member(String uid, String name, int scores) => MemberProfile(
      uid: uid,
      displayName: name,
      photoUrl: null,
      role: GroupRole.member,
      perfectScoresCount: scores,
    );

void main() {
  testWidgets('PodiumWidget renders top 3 names and ranks', (tester) async {
    final members = [
      _member('1', 'Alice', 5),
      _member('2', 'Bob', 3),
      _member('3', 'Carol', 2),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PodiumWidget(members: members),
        ),
      ),
    );

    expect(find.text('Alice'), findsOneWidget);
    expect(find.text('Bob'), findsOneWidget);
    expect(find.text('Carol'), findsOneWidget);
    expect(find.text('1º'), findsOneWidget);
    expect(find.text('2º'), findsOneWidget);
    expect(find.text('3º'), findsOneWidget);
    expect(find.text('5 acertos'), findsOneWidget);
  });

  testWidgets('PodiumWidget hides when fewer than 3 members', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Scaffold(
          body: PodiumWidget(members: [_member('1', 'Solo', 1)]),
        ),
      ),
    );

    expect(find.text('Solo'), findsNothing);
  });
}
