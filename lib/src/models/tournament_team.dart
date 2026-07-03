class TournamentTeam {
  const TournamentTeam({
    required this.id,
    required this.name,
    this.crest,
  });

  final String id;
  final String name;
  final String? crest;

  factory TournamentTeam.fromMap({
    required String id,
    required Map<String, Object?> data,
  }) {
    final rawName = data['name'] as String?;
    final name = rawName?.trim();
    final crest = (data['crest'] as String?)?.trim();
    return TournamentTeam(
      id: id,
      name: (name != null && name.isNotEmpty) ? name : id,
      crest: (crest != null && crest.isNotEmpty) ? crest : null,
    );
  }
}
