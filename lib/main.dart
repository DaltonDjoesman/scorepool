import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/demo/screenshot_demo_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await config.maybeInitializeFirebase();

  if (config.screenshotDemo) {
    // fake_cloud_firestore / firebase_auth_mocks refuse MockPlatformInterface
    // in release/profile — the app would hang on a blank screen.
    if (kReleaseMode) {
      throw StateError(
        'SCREENSHOT_DEMO cannot run with --release/--profile.\n'
        'Use: flutter run --dart-define=SCREENSHOT_DEMO=true\n'
        '(debug mode; the DEBUG banner is hidden automatically).',
      );
    }
    final demo = await ScreenshotDemoBootstrap.create();
    runApp(
      WorldCupBetTrackerApp(
        config: config,
        auth: demo.auth,
        repos: demo.repos,
      ),
    );
    return;
  }

  runApp(WorldCupBetTrackerApp(config: config));
}
