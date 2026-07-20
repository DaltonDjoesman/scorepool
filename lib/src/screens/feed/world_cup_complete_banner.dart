import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/world_cup_standings.dart';
import '../../widgets/app_card.dart';
import '../../widgets/team_flag.dart';

/// Celebration card when the World Cup catalog is fully finished.
class WorldCupCompleteBanner extends StatelessWidget {
  const WorldCupCompleteBanner({super.key, required this.standing});

  final WorldCupFinaleStanding standing;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final champion = standing.champion;

    return AppCard(
      borderColor: colors.gold.withValues(alpha: 0.55),
      backgroundColor: colors.goldLight.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'A Copa acabou! 🏆',
            style: AppTextStyles.body(context, weight: FontWeight.w800).copyWith(
              fontSize: 18,
              color: colors.gold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Campeã: ${champion.label}',
            style: AppTextStyles.body(context, weight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TeamFlag(
                teamId: champion.teamId,
                crestUrl: champion.crestUrl,
                size: 40,
              ),
              const SizedBox(width: 10),
              const Text('🏆', style: TextStyle(fontSize: 28)),
            ],
          ),
          if (standing.topFour.length >= 2) ...[
            const SizedBox(height: 16),
            Text(
              'Top 4 da Copa 2026',
              style: AppTextStyles.sub(context).copyWith(
                fontWeight: FontWeight.w700,
                color: colors.phoneFg,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                for (var i = 0; i < standing.topFour.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: _RankTile(result: standing.topFour[i])),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RankTile extends StatelessWidget {
  const _RankTile({required this.result});

  final WorldCupTeamResult result;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final medal = switch (result.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => '4️⃣',
    };

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: colors.phoneSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: result.rank == 1 ? colors.gold : colors.phoneBorder,
        ),
      ),
      child: Column(
        children: [
          Text(medal, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          TeamFlag(
            teamId: result.teamId,
            crestUrl: result.crestUrl,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            result.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: colors.phoneFg,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }
}
