import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

import '../auth/auth_controller.dart';
import '../repositories/repositories.dart';
import 'screenshot_demo_seed.dart';

/// In-memory auth + Firestore for portfolio screenshot captures.
class ScreenshotDemoBootstrap {
  ScreenshotDemoBootstrap._({required this.auth, required this.repos});

  final AuthController auth;
  final Repositories repos;

  /// Documented login for [docs/screenshots/README.md] (any password ≥ 6 chars works).
  static const demoEmail = 'ana@prints.demo';
  static const demoPassword = 'demo123';

  static Future<ScreenshotDemoBootstrap> create() async {
    final fakeDb = FakeFirebaseFirestore();
    await seedScreenshotDemo(fakeDb);

    final mockUser = MockUser(
      uid: ScreenshotDemoIds.ana,
      email: demoEmail,
      displayName: 'Ana',
    );
    final mockAuth = MockFirebaseAuth(signedIn: false, mockUser: mockUser);

    return ScreenshotDemoBootstrap._(
      auth: AuthController(auth: mockAuth),
      repos: Repositories(db: fakeDb, skipAuth: true),
    );
  }
}
