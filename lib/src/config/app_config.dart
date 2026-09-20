import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';
import '../../firebase_options_demo.dart';

enum AppEnvironment { demo, dev, prod }

class AppConfig {
  AppConfig({
    required this.environment,
    required this.firebaseEnabled,
    this.screenshotDemo = false,
  });

  final AppEnvironment environment;
  final bool firebaseEnabled;
  final bool screenshotDemo;

  bool get isDemoFirebase => environment == AppEnvironment.demo;

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

    final AppEnvironment environment = switch (env) {
      'demo' => AppEnvironment.demo,
      'prod' => AppEnvironment.prod,
      _ => AppEnvironment.dev,
    };

    return AppConfig(
      environment: environment,
      // Screenshot flavor never talks to any Firebase project.
      firebaseEnabled: screenshotDemo ? false : firebaseEnabled,
      screenshotDemo: screenshotDemo,
    );
  }

  Future<void> maybeInitializeFirebase() async {
    if (!firebaseEnabled || screenshotDemo) return;

    final options = isDemoFirebase
        ? DemoFirebaseOptions.currentPlatform
        : DefaultFirebaseOptions.currentPlatform;

    await Firebase.initializeApp(options: options);
  }
}
