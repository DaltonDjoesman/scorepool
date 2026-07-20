/// Shared FIFA team metadata: display name + ISO2 for flags.
class TeamEntry {
  const TeamEntry({required this.displayName, required this.iso2});

  final String displayName;
  final String iso2;
}

abstract final class TeamMetadata {
  static const entries = <String, TeamEntry>{
    'BRA': TeamEntry(displayName: 'Brasil', iso2: 'BR'),
    'ARG': TeamEntry(displayName: 'Argentina', iso2: 'AR'),
    'URU': TeamEntry(displayName: 'Uruguai', iso2: 'UY'),
    'USA': TeamEntry(displayName: 'EUA', iso2: 'US'),
    'MEX': TeamEntry(displayName: 'México', iso2: 'MX'),
    'FRA': TeamEntry(displayName: 'França', iso2: 'FR'),
    'ESP': TeamEntry(displayName: 'Espanha', iso2: 'ES'),
    'POR': TeamEntry(displayName: 'Portugal', iso2: 'PT'),
    'ENG': TeamEntry(displayName: 'Inglaterra', iso2: 'GB'),
    'GER': TeamEntry(displayName: 'Alemanha', iso2: 'DE'),
    'ITA': TeamEntry(displayName: 'Itália', iso2: 'IT'),
    'NED': TeamEntry(displayName: 'Holanda', iso2: 'NL'),
    'COL': TeamEntry(displayName: 'Colômbia', iso2: 'CO'),
    'CHI': TeamEntry(displayName: 'Chile', iso2: 'CL'),
    'ECU': TeamEntry(displayName: 'Equador', iso2: 'EC'),
    'PER': TeamEntry(displayName: 'Peru', iso2: 'PE'),
    'PAR': TeamEntry(displayName: 'Paraguai', iso2: 'PY'),
    'BOL': TeamEntry(displayName: 'Bolívia', iso2: 'BO'),
    'VEN': TeamEntry(displayName: 'Venezuela', iso2: 'VE'),
    'CRC': TeamEntry(displayName: 'Costa Rica', iso2: 'CR'),
    'PAN': TeamEntry(displayName: 'Panamá', iso2: 'PA'),
    'JAM': TeamEntry(displayName: 'Jamaica', iso2: 'JM'),
    'CAN': TeamEntry(displayName: 'Canadá', iso2: 'CA'),
    'JPN': TeamEntry(displayName: 'Japão', iso2: 'JP'),
    'KOR': TeamEntry(displayName: 'Coreia do Sul', iso2: 'KR'),
    'AUS': TeamEntry(displayName: 'Austrália', iso2: 'AU'),
    'NZL': TeamEntry(displayName: 'Nova Zelândia', iso2: 'NZ'),
    'MAR': TeamEntry(displayName: 'Marrocos', iso2: 'MA'),
    'SEN': TeamEntry(displayName: 'Senegal', iso2: 'SN'),
    'NGA': TeamEntry(displayName: 'Nigéria', iso2: 'NG'),
    'GHA': TeamEntry(displayName: 'Gana', iso2: 'GH'),
    'CMR': TeamEntry(displayName: 'Camarões', iso2: 'CM'),
    'CIV': TeamEntry(displayName: 'Costa do Marfim', iso2: 'CI'),
    'TUN': TeamEntry(displayName: 'Tunísia', iso2: 'TN'),
    'ALG': TeamEntry(displayName: 'Argélia', iso2: 'DZ'),
    'EGY': TeamEntry(displayName: 'Egito', iso2: 'EG'),
    'SAU': TeamEntry(displayName: 'Arábia Saudita', iso2: 'SA'),
    'QAT': TeamEntry(displayName: 'Catar', iso2: 'QA'),
    'IRN': TeamEntry(displayName: 'Irã', iso2: 'IR'),
    'CRO': TeamEntry(displayName: 'Croácia', iso2: 'HR'),
    'SRB': TeamEntry(displayName: 'Sérvia', iso2: 'RS'),
    'SUI': TeamEntry(displayName: 'Suíça', iso2: 'CH'),
    'BEL': TeamEntry(displayName: 'Bélgica', iso2: 'BE'),
    'POL': TeamEntry(displayName: 'Polônia', iso2: 'PL'),
    'DEN': TeamEntry(displayName: 'Dinamarca', iso2: 'DK'),
    'SWE': TeamEntry(displayName: 'Suécia', iso2: 'SE'),
    'NOR': TeamEntry(displayName: 'Noruega', iso2: 'NO'),
    'AUT': TeamEntry(displayName: 'Áustria', iso2: 'AT'),
    'CZE': TeamEntry(displayName: 'Tchéquia', iso2: 'CZ'),
    'UKR': TeamEntry(displayName: 'Ucrânia', iso2: 'UA'),
    'TUR': TeamEntry(displayName: 'Turquia', iso2: 'TR'),
    'WAL': TeamEntry(displayName: 'País de Gales', iso2: 'GB'),
    'SCO': TeamEntry(displayName: 'Escócia', iso2: 'GB'),
    'BIH': TeamEntry(displayName: 'Bósnia e Herzegovina', iso2: 'BA'),
    'COD': TeamEntry(displayName: 'RD Congo', iso2: 'CD'),
    'CPV': TeamEntry(displayName: 'Cabo Verde', iso2: 'CV'),
    'CUW': TeamEntry(displayName: 'Curaçao', iso2: 'CW'),
    'HAI': TeamEntry(displayName: 'Haiti', iso2: 'HT'),
    'IRQ': TeamEntry(displayName: 'Iraque', iso2: 'IQ'),
    'JOR': TeamEntry(displayName: 'Jordânia', iso2: 'JO'),
    'KSA': TeamEntry(displayName: 'Arábia Saudita', iso2: 'SA'),
    'RSA': TeamEntry(displayName: 'África do Sul', iso2: 'ZA'),
    'UZB': TeamEntry(displayName: 'Uzbequistão', iso2: 'UZ'),
  };

  static String? _normalize(String teamId) {
    final id = teamId.trim().toUpperCase();
    return id.isEmpty ? null : id;
  }

  static TeamEntry? entryFor(String teamId) {
    final id = _normalize(teamId);
    if (id == null) return null;
    return entries[id];
  }

  static bool isPlaceholder(String teamId) {
    final id = teamId.trim().toUpperCase();
    return id.isEmpty || id.startsWith('TBD_');
  }

  static String label(String teamId) {
    final id = teamId.trim();
    if (isPlaceholder(id)) return 'A definir';
    final normalized = id.toUpperCase();
    return entries[normalized]?.displayName ?? id;
  }

  static String? iso2ForTeamId(String teamId) {
    final id = _normalize(teamId);
    if (id == null) return null;
    return entries[id]?.iso2;
  }
}
