import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/match_score_display.dart';
import '../../utils/team_display.dart';
import '../../utils/money_format.dart';
import '../../utils/pot_calculator.dart';
import '../../widgets/app_card.dart';
import '../../widgets/team_flag.dart';

class MatchHeroCard extends StatelessWidget {
  const MatchHeroCard({
    super.key,
    required this.match,
    required this.currency,
    required this.memberNames,
    required this.entryFeeCents,
    required this.inPotParticipantCount,
  });

  final GroupMatchOverlay match;
  final String currency;
  final Map<String, String> memberNames;
  final int entryFeeCents;
  final int inPotParticipantCount;

  String _formatTime(DateTime utc) {
    final local = utc.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final pot = PotCalculator.displayPotCents(
      match: match,
      entryFeeCents: entryFeeCents,
      inPotParticipantCount: inPotParticipantCount,
    );
    final winners = match.winnerUids;
    final hasWinners = winners.isNotEmpty;
    final perWinner = hasWinners ? pot ~/ winners.length : null;
    final potLabel = PotCalculator.potSubtitle(
      match: match,
      hasWinners: hasWinners,
    );

    return AppCard(
      borderColor: hasWinners ? colors.gold.withValues(alpha: 0.4) : null,
      backgroundColor: hasWinners
          ? colors.goldLight.withValues(alpha: 0.15)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${_formatTime(match.matchTimeUtc)} · ${match.stage.toUpperCase()} · ${match.status.name.toUpperCase()}',
            style: AppTextStyles.titleCaps(context),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    TeamFlag(teamId: match.homeTeamId, crestUrl: match.homeFlag, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      TeamDisplay.label(match.homeTeamId),
                      style: AppTextStyles.body(context, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Text(
                matchCenterDisplay(match: match, showPredictionInputs: false),
                style: AppTextStyles.displayHeadline(context, size: 22),
              ),
              Expanded(
                child: Column(
                  children: [
                    TeamFlag(teamId: match.awayTeamId, crestUrl: match.awayFlag, size: 32),
                    const SizedBox(height: 6),
                    Text(
                      TeamDisplay.label(match.awayTeamId),
                      style: AppTextStyles.body(context, weight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: colors.phoneBorder),
          const SizedBox(height: 12),
          Text(potLabel, style: AppTextStyles.sub(context)),
          const SizedBox(height: 4),
          Text(
            MoneyFormat.format(amountCents: pot, currency: currency),
            style: AppTextStyles.displayHeadline(context, size: 26)
                .copyWith(color: colors.gold),
          ),
          const SizedBox(height: 8),
          Text(
            hasWinners
                ? '🏆 Dividido entre: ${winners.map((uid) => memberNames[uid] ?? uid).join(' e ')}'
                    '${perWinner != null ? ' (${MoneyFormat.format(amountCents: perWinner, currency: currency)} cada)' : ''}'
                : (match.status == MatchStatus.finished
                    ? 'Sem vencedores — pote acumulado ❄️'
                    : '$inPotParticipantCount no pote · entrada ${MoneyFormat.format(amountCents: entryFeeCents, currency: currency)}'),
            style: AppTextStyles.body(context, weight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
