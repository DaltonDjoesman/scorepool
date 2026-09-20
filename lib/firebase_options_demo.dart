// Firebase options for the public demo APK (project: copabolaao-demo).
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Client options for [copabolaao-demo] — never point production builds here.
class DemoFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DemoFirebaseOptions have not been configured for web.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DemoFirebaseOptions are Android-only for the portfolio APK.',
        );
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DemoFirebaseOptions are Android-only for the portfolio APK.',
        );
      default:
        throw UnsupportedError(
          'DemoFirebaseOptions are not supported on this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJlRgIo115tXnaqhaMCw3eFkgQLJVUi3s',
    appId: '1:1068211940687:android:65790f0207c5d7ddb4293a',
    messagingSenderId: '1068211940687',
    projectId: 'copabolaao-demo',
    storageBucket: 'copabolaao-demo.firebasestorage.app',
  );
}
