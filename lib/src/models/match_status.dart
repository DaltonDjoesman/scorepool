enum MatchStatus {
  scheduled,
  live,
  finished;

  static MatchStatus fromString(String value) {
    return MatchStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => MatchStatus.scheduled,
    );
  }
}
