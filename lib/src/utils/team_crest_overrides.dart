/// Manual crest URLs for teams missing from football-data.org and flagcdn mapping.
///
/// Prefer Firestore enrichment (`npm run enrich:crests` in `functions/`) which
/// fills `tournaments/wc2026/teams/{id}.crest` from flagcdn.com automatically.
const Map<String, String> teamCrestOverrides = {
  // Example:
  // 'CUW': 'https://example.com/curacao.png',
};

String? crestOverrideForTeamId(String teamId) {
  final normalized = teamId.trim().toUpperCase();
  if (normalized.isEmpty || normalized.startsWith('TBD_')) return null;
  return teamCrestOverrides[normalized];
}
