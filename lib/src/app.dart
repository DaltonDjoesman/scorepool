import 'dart:async';

import 'package:flutter/material.dart';

import 'auth/auth_controller.dart';
import 'app_state/app_state.dart';
import 'config/app_config.dart';
import 'notifications/push_notifications_controller.dart';
import 'repositories/repositories.dart';
import 'routing/app_router.dart';

class WorldCupBetTrackerApp extends StatefulWidget {
  const WorldCupBetTrackerApp({super.key, required this.config});

  final AppConfig config;

  @override
  State<WorldCupBetTrackerApp> createState() => _WorldCupBetTrackerAppState();
}

class _WorldCupBetTrackerAppState extends State<WorldCupBetTrackerApp> {
  late final AuthController? _auth = widget.config.firebaseEnabled
      ? AuthController()
      : null;
  late final Repositories? _repos = widget.config.firebaseEnabled
      ? Repositories()
      : null;
  late final AppState _state = AppState();
  PushNotificationsController? _push;
  late final router = createAppRouter(config: widget.config, auth: _auth);

  @override
  void initState() {
    super.initState();
    if (_repos != null) {
      _push = PushNotificationsController(repos: _repos);
      unawaited(_push!.initialize());
      _auth?.addListener(_syncPushToken);
      _state.addListener(_syncPushToken);
      _syncPushToken();
    }
  }

  void _syncPushToken() {
    final push = _push;
    final uid = _auth?.user?.uid;
    final groupId = _state.currentGroupId;
    if (push == null || uid == null || groupId == null) return;
    unawaited(push.syncForMember(groupId: groupId, uid: uid));
  }

  @override
  void dispose() {
    _auth?.removeListener(_syncPushToken);
    _state.removeListener(_syncPushToken);
    _push?.dispose();
    _auth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'World Cup Bet Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) => _AppScope(
        auth: _auth,
        repos: _repos,
        state: _state,
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }
}

class _AppScope extends InheritedWidget {
  const _AppScope({
    required this.auth,
    required this.repos,
    required this.state,
    required super.child,
  });

  final AuthController? auth;
  final Repositories? repos;
  final AppState state;

  static _AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_AppScope>();
    assert(scope != null, 'App scope not found in widget tree.');
    return scope!;
  }

  @override
  bool updateShouldNotify(_AppScope oldWidget) =>
      auth != oldWidget.auth ||
      repos != oldWidget.repos ||
      state != oldWidget.state;
}

AuthController? appAuth(BuildContext context) => _AppScope.of(context).auth;
Repositories? appRepos(BuildContext context) => _AppScope.of(context).repos;
AppState appState(BuildContext context) => _AppScope.of(context).state;
