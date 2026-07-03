class Group {
  Group({
    required this.id,
    required this.name,
    required this.currency,
    required this.entryFeeCents,
    required this.predictionLockMinutes,
    required this.adminUids,
    required this.matchFilter,
    required this.carryOverPotCents,
  });

  final String id;
  final String name;
  final String currency;
  final int entryFeeCents;
  final int predictionLockMinutes;
  final List<String> adminUids;
  final GroupMatchFilter matchFilter;
  final int carryOverPotCents;

  Map<String, Object?> toMap() => {
    'name': name,
    'currency': currency,
    'entryFeeCents': entryFeeCents,
    'predictionLockMinutes': predictionLockMinutes,
    'adminUids': adminUids,
    'matchFilter': matchFilter.toMap(),
    'carryOverPotCents': carryOverPotCents,
  };

  static Group fromMap({
    required String id,
    required Map<String, Object?> map,
  }) {
    return Group(
      id: id,
      name: (map['name'] as String?) ?? '',
      currency: (map['currency'] as String?) ?? 'BRL',
      entryFeeCents: (map['entryFeeCents'] as num?)?.toInt() ?? 0,
      predictionLockMinutes:
          (map['predictionLockMinutes'] as num?)?.toInt() ?? 15,
      adminUids: ((map['adminUids'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      matchFilter: GroupMatchFilter.fromMap(
        (map['matchFilter'] as Map?)?.cast<String, Object?>() ?? const {},
      ),
      carryOverPotCents: (map['carryOverPotCents'] as num?)?.toInt() ?? 0,
    );
  }
}

class GroupMatchFilter {
  GroupMatchFilter({required this.teamIds, required this.stages});

  final List<String> teamIds;
  final List<String> stages;

  Map<String, Object?> toMap() => {'teamIds': teamIds, 'stages': stages};

  static GroupMatchFilter fromMap(Map<String, Object?> map) {
    return GroupMatchFilter(
      teamIds: ((map['teamIds'] as List?) ?? const [])
          .whereType<String>()
          .toList(growable: false),
      stages: ((map['stages'] as List?) ?? const []).whereType<String>().toList(
        growable: false,
      ),
    );
  }
}
