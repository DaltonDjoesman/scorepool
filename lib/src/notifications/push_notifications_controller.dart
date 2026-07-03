import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

import '../repositories/repositories.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Background delivery is handled by the OS; no extra work required yet.
}

class PushNotificationsController {
  PushNotificationsController({required Repositories repos}) : _repos = repos;

  final Repositories _repos;
  StreamSubscription<String>? _tokenRefreshSub;
  String? _lastSyncedGroupId;
  String? _lastSyncedUid;

  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await FirebaseMessaging.instance.requestPermission();

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
      (token) => _persistToken(token),
    );
  }

  Future<void> syncForMember({
    required String groupId,
    required String uid,
  }) async {
    _lastSyncedGroupId = groupId;
    _lastSyncedUid = uid;
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await _persistToken(token, groupId: groupId, uid: uid);
    }
  }

  Future<void> _persistToken(
    String token, {
    String? groupId,
    String? uid,
  }) async {
    final targetGroupId = groupId ?? _lastSyncedGroupId;
    final targetUid = uid ?? _lastSyncedUid;
    if (targetGroupId == null || targetUid == null) return;

    await _repos.firestore.saveFcmToken(
      groupId: targetGroupId,
      uid: targetUid,
      token: token,
    );
  }

  void dispose() {
    _tokenRefreshSub?.cancel();
  }
}
