/// Maps FIFA-style 3-letter team ids to ISO 3166-1 alpha-2 for flag emoji.
const _teamIdToIso2 = <String, String>{
  'BRA': 'BR',
  'ARG': 'AR',
  'URU': 'UY',
  'USA': 'US',
  'MEX': 'MX',
  'FRA': 'FR',
  'ESP': 'ES',
  'POR': 'PT',
  'ENG': 'GB',
  'GER': 'DE',
  'ITA': 'IT',
  'NED': 'NL',
  'COL': 'CO',
  'CHI': 'CL',
  'ECU': 'EC',
  'PER': 'PE',
  'PAR': 'PY',
  'BOL': 'BO',
  'VEN': 'VE',
  'CRC': 'CR',
  'PAN': 'PA',
  'JAM': 'JM',
  'CAN': 'CA',
  'JPN': 'JP',
  'KOR': 'KR',
  'AUS': 'AU',
  'NZL': 'NZ',
  'MAR': 'MA',
  'SEN': 'SN',
  'NGA': 'NG',
  'GHA': 'GH',
  'CMR': 'CM',
  'CIV': 'CI',
  'TUN': 'TN',
  'ALG': 'DZ',
  'EGY': 'EG',
  'SAU': 'SA',
  'QAT': 'QA',
  'IRN': 'IR',
  'CRO': 'HR',
  'SRB': 'RS',
  'SUI': 'CH',
  'BEL': 'BE',
  'POL': 'PL',
  'DEN': 'DK',
  'SWE': 'SE',
  'NOR': 'NO',
  'AUT': 'AT',
  'CZE': 'CZ',
  'UKR': 'UA',
  'TUR': 'TR',
  'WAL': 'GB',
  'SCO': 'GB',
  'BIH': 'BA',
  'COD': 'CD',
  'CPV': 'CV',
  'CUW': 'CW',
  'HAI': 'HT',
  'IRQ': 'IQ',
  'JOR': 'JO',
  'KSA': 'SA',
  'RSA': 'ZA',
  'UZB': 'UZ',
};

String flagEmojiForTeamId(String teamId) {
  final normalized = teamId.trim().toUpperCase();
  final iso2 = iso2ForTeamId(normalized);
  if (iso2 == null || iso2.length != 2) return '🏳️';

  final upper = iso2.toUpperCase();
  final first = upper.codeUnitAt(0) - 0x41 + 0x1F1E6;
  final second = upper.codeUnitAt(1) - 0x41 + 0x1F1E6;
  return String.fromCharCodes([first, second]);
}

/// ISO 3166-1 alpha-2 for a FIFA-style 3-letter team id, when known.
String? iso2ForTeamId(String teamId) {
  final normalized = teamId.trim().toUpperCase();
  return _teamIdToIso2[normalized];
}

bool hasFlagMapping(String teamId) => iso2ForTeamId(teamId) != null;
