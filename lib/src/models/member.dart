enum GroupRole { admin, member }

class MemberProfile {
  MemberProfile({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.role,
    required this.perfectScoresCount,
  });

  final String uid;
  final String displayName;
  final String? photoUrl;
  final GroupRole role;
  final int perfectScoresCount;

  Map<String, Object?> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'photoUrl': photoUrl,
    'role': role.name,
    'perfectScoresCount': perfectScoresCount,
  };

  static MemberProfile fromMap({
    required String uid,
    required Map<String, Object?> map,
  }) {
    final roleString = (map['role'] as String?) ?? GroupRole.member.name;
    final role = GroupRole.values.firstWhere(
      (r) => r.name == roleString,
      orElse: () => GroupRole.member,
    );

    return MemberProfile(
      uid: uid,
      displayName: (map['displayName'] as String?) ?? '',
      photoUrl: map['photoUrl'] as String?,
      role: role,
      perfectScoresCount: (map['perfectScoresCount'] as num?)?.toInt() ?? 0,
    );
  }
}
