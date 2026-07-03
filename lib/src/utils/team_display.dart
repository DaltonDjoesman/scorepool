/// Human-readable labels for tournament team ids (including knockout placeholders).
class TeamDisplay {
  TeamDisplay._();

  static const _teamNames = <String, String>{
    'BRA': 'Brasil',
    'ARG': 'Argentina',
    'URU': 'Uruguai',
    'USA': 'EUA',
    'MEX': 'México',
    'FRA': 'França',
    'ESP': 'Espanha',
    'POR': 'Portugal',
    'ENG': 'Inglaterra',
    'GER': 'Alemanha',
    'ITA': 'Itália',
    'NED': 'Holanda',
    'COL': 'Colômbia',
    'CHI': 'Chile',
    'ECU': 'Equador',
    'PER': 'Peru',
    'PAR': 'Paraguai',
    'BOL': 'Bolívia',
    'VEN': 'Venezuela',
    'CRC': 'Costa Rica',
    'PAN': 'Panamá',
    'JAM': 'Jamaica',
    'CAN': 'Canadá',
    'JPN': 'Japão',
    'KOR': 'Coreia do Sul',
    'AUS': 'Austrália',
    'NZL': 'Nova Zelândia',
    'MAR': 'Marrocos',
    'SEN': 'Senegal',
    'NGA': 'Nigéria',
    'GHA': 'Gana',
    'CMR': 'Camarões',
    'CIV': 'Costa do Marfim',
    'TUN': 'Tunísia',
    'ALG': 'Argélia',
    'EGY': 'Egito',
    'SAU': 'Arábia Saudita',
    'QAT': 'Catar',
    'IRN': 'Irã',
    'CRO': 'Croácia',
    'SRB': 'Sérvia',
    'SUI': 'Suíça',
    'BEL': 'Bélgica',
    'POL': 'Polônia',
    'DEN': 'Dinamarca',
    'SWE': 'Suécia',
    'NOR': 'Noruega',
    'AUT': 'Áustria',
    'CZE': 'Tchéquia',
    'UKR': 'Ucrânia',
    'TUR': 'Turquia',
    'WAL': 'País de Gales',
    'SCO': 'Escócia',
    'BIH': 'Bósnia e Herzegovina',
    'COD': 'RD Congo',
    'CPV': 'Cabo Verde',
    'CUW': 'Curaçao',
    'HAI': 'Haiti',
    'IRQ': 'Iraque',
    'JOR': 'Jordânia',
    'KSA': 'Arábia Saudita',
    'RSA': 'África do Sul',
    'UZB': 'Uzbequistão',
  };

  static bool isPlaceholder(String teamId) {
    final id = teamId.trim().toUpperCase();
    return id.isEmpty || id.startsWith('TBD_');
  }

  static String label(String teamId) {
    final id = teamId.trim();
    if (isPlaceholder(id)) return 'A definir';
    final normalized = id.toUpperCase();
    return _teamNames[normalized] ?? id;
  }
}
