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

/// Prefer flagcdn PNG for national teams; fall back to raster API crests.
///
/// football-data.org PNG crests are valid but often slower/less reliable than
/// flagcdn for nation flags. SVG API crests are never used (Flutter Image.network).
String? displayCrestUrl({required String teamId, String? apiCrest}) {
  final flagcdn = resolveCrestUrl(teamId);
  if (flagcdn != null) return flagcdn;

  final api = apiCrest?.trim();
  if (api != null && api.isNotEmpty && !isSvgCrestUrl(api)) return api;
  return null;
}
