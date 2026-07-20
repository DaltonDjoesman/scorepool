import 'team_metadata.dart';

/// Maps FIFA-style 3-letter team ids to flag emoji via shared [TeamMetadata] ISO2.
String flagEmojiForTeamId(String teamId) {
  final iso2 = iso2ForTeamId(teamId);
  if (iso2 == null || iso2.length != 2) return '🏳️';

  final upper = iso2.toUpperCase();
  final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCodes([first, second]);
}

/// ISO 3166-1 alpha-2 for a FIFA-style 3-letter team id, when known.
String? iso2ForTeamId(String teamId) => TeamMetadata.iso2ForTeamId(teamId);

bool hasFlagMapping(String teamId) => iso2ForTeamId(teamId) != null;
