import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

enum AppEnvironment { dev, prod }

class AppConfig {
  AppConfig({
    required this.environment,
    required this.firebaseEnabled,
    this.screenshotDemo = false,
  });

  final AppEnvironment environment;
  final bool firebaseEnabled;
  final bool screenshotDemo;

  factory AppConfig.fromEnvironment() {
    final env = const String.fromEnvironment('APP_ENV', defaultValue: 'prod');
    final screenshotDemo = const bool.fromEnvironment(
      'SCREENSHOT_DEMO',
      defaultValue: false,
    );
    final firebaseEnabled = const bool.fromEnvironment(
      'FIREBASE_ENABLED',
      defaultValue: true,
    );

    return AppConfig(
      environment: env == 'prod' ? AppEnvironment.prod : AppEnvironment.dev,
      // Demo flavor never talks to production Firebase.
      firebaseEnabled: screenshotDemo ? false : firebaseEnabled,
      screenshotDemo: screenshotDemo,
    );
  }

  Future<void> maybeInitializeFirebase() async {
    if (!firebaseEnabled || screenshotDemo) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
