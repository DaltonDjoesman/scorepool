import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await config.maybeInitializeFirebase();

  runApp(WorldCupBetTrackerApp(config: config));
}
