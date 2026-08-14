import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:worldcupbettracker_app/src/app.dart';
import 'package:worldcupbettracker_app/src/config/app_config.dart';
import 'package:worldcupbettracker_app/src/demo/screenshot_demo_bootstrap.dart';
import 'package:worldcupbettracker_app/src/demo/screenshot_demo_seed.dart';
import 'package:worldcupbettracker_app/src/screens/group/create_group_screen.dart';
import 'package:worldcupbettracker_app/src/screens/shell/feed_shell_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Screenshot demo login opens seeded feed and ranking', (
    WidgetTester tester,
  ) async {
    final demo = await ScreenshotDemoBootstrap.create();
    await tester.pumpWidget(
      WorldCupBetTrackerApp(
        config: AppConfig(
          environment: AppEnvironment.dev,
          firebaseEnabled: false,
          screenshotDemo: true,
        ),
        auth: demo.auth,
        repos: demo.repos,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('CopaBolão 2026'), findsWidgets);

    await tester.enterText(
      find.byType(TextField).first,
      ScreenshotDemoBootstrap.demoEmail,
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      ScreenshotDemoBootstrap.demoPassword,
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedShellScreen), findsOneWidget);
    expect(find.text('A Copa acabou! 🏆'), findsNothing);
    // Final is scheduled in Próximos with real knockout sides.
    expect(find.textContaining('Espanha'), findsWidgets);
    expect(find.textContaining('Argentina'), findsWidgets);

    await tester.tap(find.text('Ranking'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Ana'), findsWidgets);
    expect(find.textContaining('Bruno'), findsWidgets);
    expect(find.textContaining('Carla'), findsWidgets);
  });

  test('Screenshot demo seeds all 48 WC2026 teams for create-group picker', () async {
    final demo = await ScreenshotDemoBootstrap.create();
    final teams = await demo.repos.matches.listTournamentTeams(
      ScreenshotDemoIds.tournamentId,
    );
    expect(teams, hasLength(ScreenshotDemoIds.wc2026TeamIds.length));
    expect(
      teams.map((t) => t.id),
      containsAll(['BRA', 'ARG', 'ESP', 'USA', 'UZB']),
    );
    expect(teams.any((t) => t.name == 'Brasil'), isTrue);
  });

  testWidgets('Screenshot demo create-group screen lists WC teams', (
    WidgetTester tester,
  ) async {
    final demo = await ScreenshotDemoBootstrap.create();
    await tester.pumpWidget(
      WorldCupBetTrackerApp(
        config: AppConfig(
          environment: AppEnvironment.dev,
          firebaseEnabled: false,
          screenshotDemo: true,
        ),
        auth: demo.auth,
        repos: demo.repos,
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField).first,
      ScreenshotDemoBootstrap.demoEmail,
    );
    await tester.enterText(
      find.byType(TextField).at(1),
      ScreenshotDemoBootstrap.demoPassword,
    );
    await tester.tap(find.text('Entrar'));
    await tester.pumpAndSettle();

    // Leave group hub path: Sair do Grupo → Meus bolões → Criar.
    await tester.tap(find.text('Sair do Grupo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar novo bolão'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateGroupScreen), findsOneWidget);
    expect(find.text('Novo Grupo'), findsOneWidget);
    // Grid shows alphabetically sorted names; several should be visible.
    expect(find.textContaining('Alemanha'), findsWidgets);
    expect(find.textContaining('Argentina'), findsWidgets);
  });
}
