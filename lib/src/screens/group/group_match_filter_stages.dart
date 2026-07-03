class GroupMatchFilterStage {
  const GroupMatchFilterStage({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

const groupMatchFilterStages = <GroupMatchFilterStage>[
  GroupMatchFilterStage(id: 'group', label: 'Grupos'),
  GroupMatchFilterStage(id: 'round_of_32', label: '32 avos'),
  GroupMatchFilterStage(id: 'round_of_16', label: 'Oitavas'),
  GroupMatchFilterStage(id: 'quarterfinal', label: 'Quartas'),
  GroupMatchFilterStage(id: 'semifinal', label: 'Semi'),
  GroupMatchFilterStage(id: 'third_place', label: '3º lugar'),
  GroupMatchFilterStage(id: 'final', label: 'Final'),
];

const groupMatchKnockoutStageIds = <String>{
  'round_of_32',
  'round_of_16',
  'quarterfinal',
  'semifinal',
  'third_place',
  'final',
};
