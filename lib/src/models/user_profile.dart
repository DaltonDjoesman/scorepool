class UserProfile {
  const UserProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;

  Map<String, Object?> toMap() => {
    'displayName': displayName,
    'photoUrl': photoUrl,
  };

  static UserProfile fromMap({
    required String uid,
    required Map<String, Object?> map,
  }) {
    return UserProfile(
      uid: uid,
      displayName: (map['displayName'] as String?)?.trim() ?? '',
      photoUrl: map['photoUrl'] as String?,
    );
  }
}
