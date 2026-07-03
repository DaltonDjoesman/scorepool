import 'package:firebase_core/firebase_core.dart';

import '../../firebase_options.dart';

enum AppEnvironment { dev, prod }

class AppConfig {
  AppConfig({required this.environment, required this.firebaseEnabled});

  final AppEnvironment environment;
  final bool firebaseEnabled;

  factory AppConfig.fromEnvironment() {
    final env = const String.fromEnvironment('APP_ENV', defaultValue: 'dev');
    final firebaseEnabled = const bool.fromEnvironment(
      'FIREBASE_ENABLED',
      defaultValue: false,
    );

    return AppConfig(
      environment: env == 'prod' ? AppEnvironment.prod : AppEnvironment.dev,
      firebaseEnabled: firebaseEnabled,
    );
  }

  Future<void> maybeInitializeFirebase() async {
    if (!firebaseEnabled) return;

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
