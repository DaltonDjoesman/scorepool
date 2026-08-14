import 'package:flutter/material.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/demo/screenshot_demo_bootstrap.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment();
  await config.maybeInitializeFirebase();

  if (config.screenshotDemo) {
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
