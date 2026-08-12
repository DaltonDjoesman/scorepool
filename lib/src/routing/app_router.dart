import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../app_state/app_state.dart';
import '../config/app_config.dart';
import '../screens/group/group_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/group/edit_group_filter_screen.dart';
import '../screens/group/edit_profile_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/match/match_details_screen.dart';
import '../screens/ranking/ranking_screen.dart';
import '../screens/shell/feed_shell_screen.dart';
import '../screens/shell/feed_shell_tab.dart';

GoRouter createAppRouter({
  required AppConfig config,
  AuthController? auth,
  AppState? appState,
}) {
  final refresh = <Listenable>[
    ?auth,
    ?appState,
  ];

  return GoRouter(
    refreshListenable: refresh.isEmpty ? null : Listenable.merge(refresh),
    initialLocation: LoginScreen.routePath,
    redirect: (context, state) {
      final signedIn = auth?.isSignedIn ?? false;
      final location = state.matchedLocation;
      final onLogin = location == LoginScreen.routePath;
      final groupId = appState?.currentGroupId;
      final sessionReady = appState?.sessionReady ?? false;

      if (!signedIn && !onLogin) return LoginScreen.routePath;

      if (signedIn) {
        if (onLogin) {
          if (!sessionReady) return null;
          if (groupId != null) return FeedShellScreen.routePath;
          return GroupScreen.routePath;
        }

        if (sessionReady &&
            groupId != null &&
            location == GroupScreen.routePath) {
          return FeedShellScreen.routePath;
        }
      }

      if (location == RankingScreen.routePath) {
        return '${FeedShellScreen.routePath}?tab=${FeedShellTab.ranking.queryValue}';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => LoginScreen(auth: auth),
      ),
      GoRoute(
        path: GroupScreen.routePath,
        builder: (context, state) => const GroupScreen(),
      ),
      GoRoute(
        path: CreateGroupScreen.routePath,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: EditGroupFilterScreen.routePath,
        builder: (context, state) => const EditGroupFilterScreen(),
      ),
      GoRoute(
        path: EditProfileScreen.routePath,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: FeedShellScreen.routePath,
        builder: (context, state) {
          final tab = FeedShellTab.fromQuery(state.uri.queryParameters['tab']);
          return FeedShellScreen(initialTab: tab);
        },
      ),
      GoRoute(
        path: MatchDetailsScreen.routePath,
        builder: (context, state) {
          final matchId = state.pathParameters['matchId']!;
          return MatchDetailsScreen(matchId: matchId);
        },
      ),
      GoRoute(
        path: RankingScreen.routePath,
        redirect: (_, state) =>
            '${FeedShellScreen.routePath}?tab=${FeedShellTab.ranking.queryValue}',
      ),
    ],
  );
}
