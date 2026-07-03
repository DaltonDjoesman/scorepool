# worldcupbettracker_app

Flutter app for a simple World Cup 2026 “exact score” betting pool.

## Getting Started

### Run (prototype UI mode)

Firebase is **disabled by default** so you can run the UI skeleton without any external setup:

```bash
flutter pub get
flutter run
```

### Run (Firebase mode)

Follow `docs/firebase_setup.md`, then run:

```bash
flutter run --dart-define=FIREBASE_ENABLED=true --dart-define=APP_ENV=dev
```

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

