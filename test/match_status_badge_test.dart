import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worldcupbettracker_app/src/models/match_status.dart';
import 'package:worldcupbettracker_app/src/theme/app_theme.dart';
import 'package:worldcupbettracker_app/src/widgets/match_status_badge.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: AppTheme.dark(), home: Scaffold(body: child));
  }

  testWidgets('MatchStatusBadge shows Agendado for scheduled', (tester) async {
    await tester.pumpWidget(
      wrap(const MatchStatusBadge(status: MatchStatus.scheduled)),
    );
    expect(find.text('Agendado'), findsOneWidget);
  });

  testWidgets('MatchStatusBadge shows Ao Vivo for live', (tester) async {
    await tester.pumpWidget(
      wrap(const MatchStatusBadge(status: MatchStatus.live)),
    );
    expect(find.text('Ao Vivo'), findsOneWidget);
  });

  testWidgets('MatchStatusBadge shows Arquivado when archived', (tester) async {
    await tester.pumpWidget(
      wrap(const MatchStatusBadge(status: MatchStatus.finished, archived: true)),
    );
    expect(find.text('Arquivado'), findsOneWidget);
  });
}
