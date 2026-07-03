enum FeedShellTab {
  feed,
  ranking,
  rules;

  static FeedShellTab fromQuery(String? value) {
    return switch (value) {
      'ranking' => FeedShellTab.ranking,
      'rules' => FeedShellTab.rules,
      _ => FeedShellTab.feed,
    };
  }

  String get queryValue => name;
}
