import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'auth/auth_controller.dart';
import 'app_state/app_state.dart';
import 'app_state/group_selection_store.dart';
import 'config/app_config.dart';
import 'notifications/push_notifications_controller.dart';
import 'repositories/repositories.dart';
import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class WorldCupBetTrackerApp extends StatefulWidget {
  const WorldCupBetTrackerApp({
    super.key,
    required this.config,
    this.auth,
    this.repos,
  });

  final AppConfig config;

  /// Injected by [main] after demo bootstrap, or created internally when Firebase is on.
  final AuthController? auth;
  final Repositories? repos;

  @override
  State<WorldCupBetTrackerApp> createState() => _WorldCupBetTrackerAppState();
}

class _WorldCupBetTrackerAppState extends State<WorldCupBetTrackerApp> {
  late final AuthController? _auth =
      widget.auth ??
      (widget.config.firebaseEnabled && !widget.config.screenshotDemo
          ? AuthController()
          : null);
  late final Repositories? _repos =
      widget.repos ??
      (widget.config.firebaseEnabled && !widget.config.screenshotDemo
          ? Repositories()
          : null);
  late final AppState _state = AppState();
  final _groupSelectionStore = GroupSelectionStore();
  PushNotificationsController? _push;
  late final GoRouter router = createAppRouter(
    config: widget.config,
    auth: _auth,
    appState: _state,
  );

  @override
  void initState() {
    super.initState();
    if (_repos != null && !widget.config.screenshotDemo) {
      _push = PushNotificationsController(repos: _repos);
      unawaited(_push!.initialize());
    }
    if (_repos != null) {
      _auth?.addListener(_onAuthChanged);
      _state.addListener(_onGroupSelectionChanged);
      unawaited(_onAuthChanged());
    } else {
      _state.setSessionReady(true);
    }
  }

  Future<void> _onAuthChanged() async {
    final auth = _auth;
    final repos = _repos;
    if (auth == null || repos == null) return;

    final user = auth.user;
    if (user == null) {
      _state.clearCurrentGroupId();
      _state.setSessionReady(true);
      return;
    }

    _state.setSessionReady(false);

    final savedGroupId = await _groupSelectionStore.load(user.uid);
    if (savedGroupId != null &&
        await repos.groups.isMember(groupId: savedGroupId, uid: user.uid)) {
      _state.setCurrentGroupId(savedGroupId);
      _state.setSessionReady(true);
      return;
    }

    final groups = await repos.groups.fetchUserGroups(user.uid);
    if (groups.length == 1) {
      _state.setCurrentGroupId(groups.first.groupId);
      await _groupSelectionStore.save(user.uid, groups.first.groupId);
      _state.setSessionReady(true);
      return;
    }

    _state.clearCurrentGroupId();
    await _groupSelectionStore.save(user.uid, null);
    _state.setSessionReady(true);
  }

  void _onGroupSelectionChanged() {
    final uid = _auth?.user?.uid;
    if (uid == null) return;
    unawaited(_groupSelectionStore.save(uid, _state.currentGroupId));
    _syncPushToken();
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
    _auth?.removeListener(_onAuthChanged);
    _state.removeListener(_onGroupSelectionChanged);
    _push?.dispose();
    _auth?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'CopaBolão 2026',
      theme: AppTheme.dark(),
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
