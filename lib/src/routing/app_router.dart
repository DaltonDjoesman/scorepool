import 'package:go_router/go_router.dart';

import '../auth/auth_controller.dart';
import '../config/app_config.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/group/group_screen.dart';
import '../screens/group/create_group_screen.dart';
import '../screens/group/edit_group_filter_screen.dart';
import '../screens/login/login_screen.dart';
import '../screens/match/match_details_screen.dart';
import '../screens/ranking/ranking_screen.dart';

GoRouter createAppRouter({required AppConfig config, AuthController? auth}) {
  return GoRouter(
    refreshListenable: auth,
    initialLocation: LoginScreen.routePath,
    redirect: (context, state) {
      if (!config.firebaseEnabled) return null;

      final signedIn = auth?.isSignedIn ?? false;
      final onLogin = state.matchedLocation == LoginScreen.routePath;

      if (!signedIn && !onLogin) return LoginScreen.routePath;
      if (signedIn && onLogin) return GroupScreen.routePath;

      return null;
    },
    routes: [
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => LoginScreen(config: config, auth: auth),
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
        path: FeedScreen.routePath,
        builder: (context, state) => const FeedScreen(),
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
        builder: (context, state) => const RankingScreen(),
      ),
    ],
  );
}
