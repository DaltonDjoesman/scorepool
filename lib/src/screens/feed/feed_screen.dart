export '../shell/feed_shell_screen.dart' show FeedShellScreen;
export '../shell/feed_shell_tab.dart' show FeedShellTab;

import '../shell/feed_shell_screen.dart';
import '../shell/feed_shell_tab.dart';

/// Back-compat alias; prefer [FeedShellScreen].
class FeedScreen extends FeedShellScreen {
  const FeedScreen({super.key, super.initialTab = FeedShellTab.feed});

  static const routePath = FeedShellScreen.routePath;
}
