import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import 'group_match_filter_stages.dart';
import 'tournament_team_picker.dart';

class GroupMatchFilterSection extends StatelessWidget {
  const GroupMatchFilterSection({
    super.key,
    required this.tournamentId,
    required this.teamSearchController,
    required this.selectedTeamIds,
    required this.selectedStages,
    required this.enabled,
    required this.includedMatchesCount,
    required this.countingMatches,
    required this.onSelectionChanged,
    required this.onRecalculate,
    this.recalculateLabel = 'Recalcular Jogos',
    this.matchCountLabel = 'Total de Jogos no Filtro:',
  });

  final String tournamentId;
  final TextEditingController teamSearchController;
  final Set<String> selectedTeamIds;
  final Set<String> selectedStages;
  final bool enabled;
  final int? includedMatchesCount;
  final bool countingMatches;
  final VoidCallback onSelectionChanged;
  final VoidCallback onRecalculate;
  final String recalculateLabel;
  final String matchCountLabel;

  void _toggleStage(Set<String> stages, String stageId, bool? checked) {
    if (!enabled || checked == null) return;
    if (checked) {
      stages.add(stageId);
    } else {
      stages.remove(stageId);
    }
    onSelectionChanged();
  }

  void _selectGroupStageOnly(Set<String> stages) {
    if (!enabled) return;
    stages
      ..clear()
      ..add('group');
    onSelectionChanged();
  }

  void _selectKnockoutStages(Set<String> stages) {
    if (!enabled) return;
    stages
      ..clear()
      ..addAll(groupMatchKnockoutStageIds);
    onSelectionChanged();
  }

  void _clearStages(Set<String> stages) {
    if (!enabled || stages.isEmpty) return;
    stages.clear();
    onSelectionChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final teamCount = selectedTeamIds.length;
    final stageCount = selectedStages.length;
    final summaryParts = <String>[
      '$teamCount time${teamCount == 1 ? '' : 's'}',
      '$stageCount fase${stageCount == 1 ? '' : 's'}',
      if (includedMatchesCount != null) '$includedMatchesCount jogos',
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Filtro do Bolão', style: AppTextStyles.body(context, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            summaryParts.join(' · '),
            style: AppTextStyles.sub(context),
          ),
          const SizedBox(height: 16),
          TournamentTeamPicker(
            tournamentId: tournamentId,
            searchController: teamSearchController,
            selectedTeamIds: selectedTeamIds,
            enabled: enabled,
            onSelectionChanged: onSelectionChanged,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Icon(Icons.tour, size: 20, color: colors.phoneFg),
              const SizedBox(width: 6),
              Text('Fases', style: AppTextStyles.body(context, weight: FontWeight.w700)),
              if (stageCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: colors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colors.accent.withValues(alpha: 0.35)),
                  ),
                  child: Text(
                    '$stageCount',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: [
              TextButton(
                onPressed: enabled ? () => _selectGroupStageOnly(selectedStages) : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Só grupos'),
              ),
              TextButton(
                onPressed: enabled ? () => _selectKnockoutStages(selectedStages) : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Mata-mata'),
              ),
              TextButton(
                onPressed: enabled && stageCount > 0 ? () => _clearStages(selectedStages) : null,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 0,
              mainAxisExtent: 40,
            ),
            itemCount: groupMatchFilterStages.length,
            itemBuilder: (context, index) {
              final stage = groupMatchFilterStages[index];
              final checked = selectedStages.contains(stage.id);
              return _PhaseCheckboxTile(
                label: stage.label,
                value: checked,
                enabled: enabled,
                onChanged: (value) => _toggleStage(selectedStages, stage.id, value),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.accentLight.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.accent.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      matchCountLabel,
                      style: AppTextStyles.body(context, weight: FontWeight.w700),
                    ),
                    if (countingMatches)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Text(
                        '${includedMatchesCount ?? '—'}',
                        style: TextStyle(
                          color: colors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                AppButtonOutline(
                  label: recalculateLabel,
                  onPressed: (enabled && !countingMatches) ? onRecalculate : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PhaseCheckboxTile extends StatelessWidget {
  const _PhaseCheckboxTile({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return InkWell(
      onTap: enabled ? () => onChanged(!value) : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: value,
                onChanged: enabled ? onChanged : null,
                activeColor: colors.accent,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: colors.phoneFg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
