import 'team_crest_overrides.dart';
import 'team_flag_emoji.dart';

const _teamFlagCdnCode = <String, String>{
  'ENG': 'gb-eng',
  'WAL': 'gb-wls',
  'SCO': 'gb-sct',
};

String flagCdnCrestUrl(String flagCode, {int width = 80}) {
  return 'https://flagcdn.com/w$width/${flagCode.toLowerCase()}.png';
}

/// PNG/JPEG crest for Flutter [Image.network] (SVG from the API is not supported).
String? resolveCrestUrl(String teamId) {
  final normalized = teamId.trim().toUpperCase();
  if (normalized.isEmpty || normalized.startsWith('TBD_')) return null;

  final flagCode =
      _teamFlagCdnCode[normalized] ?? iso2ForTeamId(normalized);
  if (flagCode == null) return crestOverrideForTeamId(teamId);

  return flagCdnCrestUrl(flagCode);
}

bool isSvgCrestUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.svg');
}

/// Prefer raster API crests; fall back to flagcdn for SVG/missing URLs.
String? displayCrestUrl({required String teamId, String? apiCrest}) {
  final api = apiCrest?.trim();
  if (api != null && api.isNotEmpty && !isSvgCrestUrl(api)) return api;
  return resolveCrestUrl(teamId);
}
