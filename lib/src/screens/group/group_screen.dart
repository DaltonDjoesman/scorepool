import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/user_group_membership.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/money_format.dart';
import '../../widgets/alert_box.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/status_badge.dart';
import '../feed/feed_screen.dart';
import 'create_group_screen.dart';
import 'edit_profile_screen.dart';

class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  static const routePath = '/group';

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  final _groupIdController = TextEditingController();
  bool _joining = false;
  String? _error;
  String? _busyGroupId;

  @override
  void dispose() {
    _groupIdController.dispose();
    super.dispose();
  }

  void _selectGroup(String groupId) {
    appState(context).setCurrentGroupId(groupId);
    context.go(FeedScreen.routePath);
  }

  Future<void> _joinGroup() async {
    final auth = appAuth(context);
    final repos = appRepos(context);
    final state = appState(context);
    final user = auth?.user;
    if (user == null || repos == null) return;

    final groupId = _groupIdController.text.trim();
    if (groupId.isEmpty) {
      setState(() => _error = 'Informe o código do grupo.');
      return;
    }

    setState(() {
      _joining = true;
      _error = null;
    });

    try {
      await repos.firestore.joinGroup(
        groupId: groupId,
        uid: user.uid,
        displayName: user.displayName ?? '',
        photoUrl: user.photoURL,
      );

      state.setCurrentGroupId(groupId);
      if (!mounted) return;
      context.go(FeedScreen.routePath);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  Future<void> _deleteGroup(UserGroupMembership membership) async {
    final repos = appRepos(context);
    final state = appState(context);
    final user = appAuth(context)?.user;
    if (repos == null || user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar bolão?'),
        content: Text(
          'O bolão "${membership.group.name}" será removido. '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyGroupId = membership.groupId);
    try {
      await repos.firestore.deleteGroup(membership.groupId);
      if (state.currentGroupId == membership.groupId) {
        state.clearCurrentGroupId();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível apagar: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyGroupId = null);
    }
  }

  Future<void> _leaveGroup(UserGroupMembership membership) async {
    final repos = appRepos(context);
    final state = appState(context);
    final user = appAuth(context)?.user;
    if (repos == null || user == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do bolão?'),
        content: Text('Você deixará o bolão "${membership.group.name}".'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyGroupId = membership.groupId);
    try {
      await repos.firestore.leaveGroup(
        groupId: membership.groupId,
        uid: user.uid,
      );
      if (state.currentGroupId == membership.groupId) {
        state.clearCurrentGroupId();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível sair: $e')),
      );
    } finally {
      if (mounted) setState(() => _busyGroupId = null);
    }
  }

  Future<void> _signOut() async {
    appState(context).clearCurrentGroupId();
    await appAuth(context)?.signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final auth = appAuth(context);
    final user = auth?.user;
    final repos = appRepos(context);
    final colors = appColors(context);

    return Scaffold(
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState(context),
          builder: (context, _) {
            final activeGroupId = appState(context).currentGroupId;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ÁREA DO USUÁRIO',
                              style: AppTextStyles.titleCaps(context),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Meus bolões',
                              style: AppTextStyles.displayHeadline(context, size: 24),
                            ),
                          ],
                        ),
                      ),
                      AppButtonOutline(
                        label: 'Sair',
                        expand: false,
                        onPressed: _signOut,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (user != null && repos != null)
                    StreamBuilder(
                      stream: repos.firestore.watchUserProfile(user.uid),
                      builder: (context, profileSnap) {
                        final profile = profileSnap.data;
                        final displayName = profile?.displayName.isNotEmpty == true
                            ? profile!.displayName
                            : (user.displayName ?? user.email ?? 'Visitante');

                        return AppCard(
                          child: Row(
                            children: [
                              _UserAvatar(displayName: displayName),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      displayName,
                                      style: AppTextStyles.body(
                                        context,
                                        weight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      user.email ?? '',
                                      style: AppTextStyles.sub(context),
                                    ),
                                  ],
                                ),
                              ),
                              AppButtonOutline(
                                label: 'Editar',
                                expand: false,
                                onPressed: () =>
                                    context.go(EditProfileScreen.routePath),
                              ),
                            ],
                          ),
                        );
                      },
                    )
                  else
                    AlertBox(
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: colors.phoneBorder,
                            child: Icon(Icons.person, color: colors.phoneMuted),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.email ?? 'Visitante',
                                  style: AppTextStyles.body(
                                    context,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Seus bolões ficam ligados a esta conta.',
                                  style: AppTextStyles.sub(context),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                  if (user != null && repos != null)
                    StreamBuilder<List<UserGroupMembership>>(
                      stream: repos.firestore.watchUserGroups(user.uid),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return AlertBox(
                            variant: AlertBoxVariant.danger,
                            child: Text(snapshot.error.toString()),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final memberships = snapshot.data!;
                        if (memberships.isEmpty) {
                          return AlertBox(
                            variant: AlertBoxVariant.warning,
                            child: const Text(
                              'Você ainda não participa de nenhum bolão. '
                              'Crie um novo ou entre com o código.',
                            ),
                          );
                        }

                        return Column(
                          children: [
                            for (final membership in memberships)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _GroupListTile(
                                  membership: membership,
                                  isActive: membership.groupId == activeGroupId,
                                  isBusy: _busyGroupId == membership.groupId,
                                  onOpen: () => _selectGroup(membership.groupId),
                                  onDelete: membership.isAdmin
                                      ? () => _deleteGroup(membership)
                                      : null,
                                  onLeave: membership.isAdmin
                                      ? null
                                      : () => _leaveGroup(membership),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Entrar com código',
                          style: AppTextStyles.body(
                            context,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_error != null) ...[
                          AlertBox(
                            variant: AlertBoxVariant.danger,
                            padding: const EdgeInsets.all(10),
                            child: Text(
                              _error!,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        AppTextField(
                          controller: _groupIdController,
                          hint: 'Cole o ID do grupo',
                          enabled: !_joining,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Entrar no grupo',
                          onPressed: _joining ? null : _joinGroup,
                          isLoading: _joining,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButtonOutline(
                    label: 'Criar novo bolão',
                    icon: Icon(Icons.add, size: 18, color: colors.accent),
                    onPressed: () => context.go(CreateGroupScreen.routePath),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.displayName});

  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final trimmed = displayName.trim();

    return CircleAvatar(
      backgroundColor: colors.phoneBorder,
      child: trimmed.isNotEmpty
          ? Text(
              trimmed[0].toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700),
            )
          : Icon(Icons.person, color: colors.phoneMuted),
    );
  }
}

class _GroupListTile extends StatelessWidget {
  const _GroupListTile({
    required this.membership,
    required this.isActive,
    required this.isBusy,
    required this.onOpen,
    this.onDelete,
    this.onLeave,
  });

  final UserGroupMembership membership;
  final bool isActive;
  final bool isBusy;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;
  final VoidCallback? onLeave;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final feeLabel =
        '${MoneyFormat.format(amountCents: membership.group.entryFeeCents, currency: membership.group.currency)}/jogo';

    return AppCard(
      child: InkWell(
        onTap: isBusy ? null : onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            membership.group.name,
                            style: AppTextStyles.displayHeadline(
                              context,
                              size: 18,
                            ),
                          ),
                        ),
                        if (isActive)
                          StatusBadge(
                            label: 'Ativo',
                            variant: StatusBadgeVariant.winner,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      membership.groupId,
                      style: AppTextStyles.sub(context),
                    ),
                    const SizedBox(height: 8),
                    StatusBadge(
                      label: feeLabel,
                      variant: StatusBadgeVariant.info,
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else ...[
                if (onDelete != null)
                  IconButton(
                    tooltip: 'Apagar bolão',
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline, color: colors.danger),
                  ),
                if (onLeave != null)
                  IconButton(
                    tooltip: 'Sair do bolão',
                    onPressed: onLeave,
                    icon: Icon(Icons.logout, color: colors.phoneMuted),
                  ),
                Icon(Icons.chevron_right, color: colors.phoneMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
