import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../firestore/firestore_paths.dart';

/// Shared Firestore plumbing for focused domain repositories.
class FirestoreClient {
  FirestoreClient(this.db, {this.skipAuth = false});

  final FirebaseFirestore db;

  /// When true (screenshot demo / fake Firestore), skip Firebase Auth token checks.
  final bool skipAuth;

  Future<void> ensureFirebaseAuth() async {
    if (skipAuth) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('Faça login antes de usar o Firestore.');
    }
    await user.getIdToken();
  }

  CollectionReference<Map<String, Object?>> groups() =>
      db.collection(FirestorePaths.groups);

  DocumentReference<Map<String, Object?>> groupRef(String groupId) =>
      db.doc(FirestorePaths.group(groupId));

  CollectionReference<Map<String, Object?>> members(String groupId) =>
      db.collection(FirestorePaths.groupMembers(groupId));

  CollectionReference<Map<String, Object?>> predictions(String groupId) =>
      db.collection(FirestorePaths.groupPredictions(groupId));

  CollectionReference<Map<String, Object?>> debtItems({
    required String groupId,
    required String matchId,
  }) => db.collection(FirestorePaths.groupDebtItems(groupId, matchId));

  CollectionReference<Map<String, Object?>> groupMatches(String groupId) =>
      db.collection(FirestorePaths.groupMatches(groupId));

  DocumentReference<Map<String, Object?>> userRef(String uid) =>
      db.doc(FirestorePaths.user(uid));

  Future<void> addUserGroup(String uid, String groupId) async {
    await userRef(uid).set({
      'groupIds': FieldValue.arrayUnion([groupId]),
    }, SetOptions(merge: true));
  }

  Future<void> removeUserGroup(String uid, String groupId) async {
    await userRef(uid).set({
      'groupIds': FieldValue.arrayRemove([groupId]),
    }, SetOptions(merge: true));
  }

  List<String> groupIdsFromUserData(Map<String, Object?>? data) {
    return ((data?['groupIds'] as List?) ?? const [])
        .whereType<String>()
        .toList(growable: false);
  }

  Future<List<String>> discoverGroupIdsFromMembership(String uid) async {
    try {
      final snap = await db
          .collectionGroup('members')
          .where('uid', isEqualTo: uid)
          .get();
      return snap.docs
          .map((doc) => doc.reference.parent.parent?.id)
          .whereType<String>()
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<List<String>> userGroupIds(String uid) async {
    final userSnap = await userRef(uid).get();
    var groupIds = groupIdsFromUserData(userSnap.data());
    if (groupIds.isNotEmpty) return groupIds;

    groupIds = await discoverGroupIdsFromMembership(uid);
    if (groupIds.isNotEmpty) {
      await userRef(uid).set({'groupIds': groupIds}, SetOptions(merge: true));
    }
    return groupIds;
  }

  Future<({String displayName, String? photoUrl})> resolveMemberDisplay({
    required String uid,
    String fallbackName = '',
    String? fallbackPhoto,
  }) async {
    final snap = await userRef(uid).get();
    final data = snap.data();
    final savedName = (data?['displayName'] as String?)?.trim() ?? '';
    final savedPhoto = data?['photoUrl'] as String?;
    final name = savedName.isNotEmpty ? savedName : fallbackName.trim();
    return (displayName: name, photoUrl: savedPhoto ?? fallbackPhoto);
  }

  static Iterable<List<T>> chunks<T>(List<T> items, int size) sync* {
    if (items.isEmpty) return;
    for (var i = 0; i < items.length; i += size) {
      final end = (i + size) < items.length ? (i + size) : items.length;
      yield items.sublist(i, end);
    }
  }
}
