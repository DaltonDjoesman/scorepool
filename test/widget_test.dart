import 'package:flutter_test/flutter_test.dart';

import 'package:worldcupbettracker_app/src/app.dart';
import 'package:worldcupbettracker_app/src/config/app_config.dart';

void main() {
  testWidgets('App boots and shows login', (WidgetTester tester) async {
    await tester.pumpWidget(
      WorldCupBetTrackerApp(
        config: AppConfig(
          environment: AppEnvironment.dev,
          firebaseEnabled: false,
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('CopaBolão 2026'), findsOneWidget);
  });
}
