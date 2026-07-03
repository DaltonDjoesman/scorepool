import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../feed/feed_tab_content.dart';
import '../group/group_screen.dart';
import '../ranking/ranking_tab.dart';
import '../rules/rules_tab.dart';
import 'feed_shell_tab.dart';

class FeedShellScreen extends StatefulWidget {
  const FeedShellScreen({super.key, this.initialTab = FeedShellTab.feed});

  static const routePath = '/feed';

  final FeedShellTab initialTab;

  @override
  State<FeedShellScreen> createState() => _FeedShellScreenState();
}

class _FeedShellScreenState extends State<FeedShellScreen> {
  late FeedShellTab _tab = widget.initialTab;

  @override
  void didUpdateWidget(covariant FeedShellScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      _tab = widget.initialTab;
    }
  }

  void _selectTab(FeedShellTab tab) {
    if (_tab == tab) return;
    setState(() => _tab = tab);
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Scaffold(
      backgroundColor: colors.phoneBg,
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState(context),
          builder: (context, _) {
            final currentGroupId = appState(context).currentGroupId;
            final currentRepos = appRepos(context);

            if (currentGroupId == null || currentRepos == null) {
              return _NoGroupEmptyState(
                onGoToGroup: () => context.go(GroupScreen.routePath),
              );
            }

            final uid = appAuth(context)?.user?.uid;
            return StreamBuilder<Group?>(
              stream: currentRepos.firestore.watchGroup(currentGroupId),
              builder: (context, snapshot) {
                final group = snapshot.data;
                final isAdmin =
                    group != null && uid != null && group.adminUids.contains(uid);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _FeedShellHeader(
                      groupName: group?.name ?? currentGroupId,
                      onLeaveGroup: () {
                        appState(context).clearCurrentGroupId();
                        context.go(GroupScreen.routePath);
                      },
                    ),
                    Expanded(
                      child: IndexedStack(
                        index: _tab.index,
                        children: [
                          FeedTabContent(groupId: currentGroupId),
                          RankingTab(groupId: currentGroupId, isAdmin: isAdmin),
                          RulesTab(groupId: currentGroupId),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: appState(context),
        builder: (context, _) {
          if (appState(context).currentGroupId == null) return const SizedBox.shrink();
          return NavigationBar(
              selectedIndex: _tab.index,
              onDestinationSelected: (index) =>
                  _selectTab(FeedShellTab.values[index]),
              backgroundColor: colors.phoneSurface,
              indicatorColor: colors.accentLight,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.sports_soccer_outlined, color: colors.phoneMuted),
                  selectedIcon: Icon(Icons.sports_soccer, color: colors.accent),
                  label: 'Feed',
                ),
                NavigationDestination(
                  icon: Icon(Icons.leaderboard_outlined, color: colors.phoneMuted),
                  selectedIcon: Icon(Icons.leaderboard, color: colors.accent),
                  label: 'Ranking',
                ),
                NavigationDestination(
                  icon: Icon(Icons.info_outline, color: colors.phoneMuted),
                  selectedIcon: Icon(Icons.info, color: colors.accent),
                  label: 'Regulamento',
                ),
              ],
            );
        },
      ),
    );
  }
}

class _NoGroupEmptyState extends StatelessWidget {
  const _NoGroupEmptyState({required this.onGoToGroup});

  final VoidCallback onGoToGroup;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📂', style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Selecione um grupo',
            style: AppTextStyles.displayHeadline(context, size: 20),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Você precisa entrar em um bolão ou criar um novo para ver os jogos e o ranking.',
            style: AppTextStyles.sub(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          AppButton(label: 'Ir para Grupos', onPressed: onGoToGroup),
        ],
      ),
    );
  }
}

class _FeedShellHeader extends StatelessWidget {
  const _FeedShellHeader({
    required this.groupName,
    required this.onLeaveGroup,
  });

  final String groupName;
  final VoidCallback onLeaveGroup;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(groupName, style: AppTextStyles.displayHeadline(context, size: 22)),
              ],
            ),
          ),
          TextButton(
            onPressed: onLeaveGroup,
            style: TextButton.styleFrom(
              foregroundColor: colors.accent,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
            child: const Text('Sair do Grupo'),
          ),
        ],
      ),
    );
  }
}
