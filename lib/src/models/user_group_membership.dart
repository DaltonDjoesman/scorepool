import 'group.dart';
import 'member.dart';

class UserGroupMembership {
  const UserGroupMembership({
    required this.groupId,
    required this.group,
    required this.role,
  });

  final String groupId;
  final Group group;
  final GroupRole role;

  bool get isAdmin => role == GroupRole.admin;
}
