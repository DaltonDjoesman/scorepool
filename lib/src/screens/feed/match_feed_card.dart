import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/match_lock.dart';
import '../../utils/match_score_display.dart';
import '../../utils/team_display.dart';
import '../../utils/money_format.dart';
import '../../utils/pot_calculator.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/match_status_badge.dart';
import '../../widgets/team_flag.dart';
import '../match/match_details_screen.dart';
import 'inline_prediction_inputs.dart';
import 'secar_palpites_sheet.dart';

class MatchFeedCard extends StatelessWidget {
  const MatchFeedCard({
    super.key,
    required this.groupId,
    required this.match,
    required this.memberNames,
    required this.currency,
    required this.predictionLockMinutes,
    required this.repos,
    required this.currentUid,
    this.archived = false,
    this.prediction,
    this.canEditPrediction = false,
    this.lockedForPredictions = false,
    this.entryFeeCents = 0,
    this.inPotParticipantCount = 0,
  });

  final String groupId;
  final GroupMatchOverlay match;
  final Map<String, String> memberNames;
  final String currency;
  final int predictionLockMinutes;
  final Repositories repos;
  final String? currentUid;
  final bool archived;
  final Prediction? prediction;
  final bool canEditPrediction;
  final bool lockedForPredictions;
  final int entryFeeCents;
  final int inPotParticipantCount;

  String _formatTime(DateTime utc) {
    final local = utc.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  int _potCents() {
    return PotCalculator.displayPotCents(
      match: match,
      entryFeeCents: entryFeeCents,
      inPotParticipantCount: inPotParticipantCount,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final isFinished = match.status == MatchStatus.finished;
    final isLive = match.status == MatchStatus.live;
    final isScheduled = match.status == MatchStatus.scheduled;
    final hasWinners = match.winnerUids.isNotEmpty;
    final hasAccumulation = match.accumulatedFromPreviousCents > 0;
    final pot = _potCents();
    final showPotBanner = hasAccumulation && !archived;
    final showScheduledPot = isScheduled && !archived && !showPotBanner;

    return AppCard(
      onTap: archived
          ? null
          : () => context.go(MatchDetailsScreen.routePathFor(matchId: match.matchId)),
      borderColor: isFinished && hasWinners && !archived
          ? colors.gold.withValues(alpha: 0.5)
          : null,
      backgroundColor: isFinished && hasWinners && !archived
          ? colors.goldLight.withValues(alpha: 0.2)
          : null,
      child: Opacity(
        opacity: archived ? 0.75 : 1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showPotBanner) ...[
              _PotBanner(amountCents: pot, currency: currency),
              const SizedBox(height: 12),
            ],
            if (showScheduledPot) ...[
              _PotBanner(
                amountCents: pot,
                currency: currency,
                label: 'POTE ESTIMADO',
              ),
              const SizedBox(height: 12),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                MatchStatusBadge(status: match.status, archived: archived),
                Text(
                  _formatTime(match.matchTimeUtc),
                  style: AppTextStyles.sub(context).copyWith(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isScheduled && canEditPrediction && !archived)
              _ScheduledPredictionBlock(
                groupId: groupId,
                match: match,
                prediction: prediction,
                canEdit: canEditPrediction,
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: _TeamSide(teamId: match.homeTeamId, crestUrl: match.homeFlag)),
                  Expanded(
                    flex: 2,
                    child: Text(
                      matchCenterDisplay(
                        match: match,
                        showPredictionInputs: false,
                      ),
                      textAlign: TextAlign.center,
                      style: AppTextStyles.displayHeadline(context, size: 20),
                    ),
                  ),
                  Expanded(child: _TeamSide(teamId: match.awayTeamId, crestUrl: match.awayFlag)),
                ],
              ),
            if (archived) ...[
              const SizedBox(height: 8),
              Text(
                '🚫 Excluído do Bolão pelas regras de filtragem.',
                style: TextStyle(fontSize: 11, color: colors.danger),
              ),
            ],
            if (isLive && !archived && lockedForPredictions) ...[
              const SizedBox(height: 12),
              Divider(color: colors.phoneBorder),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Seu Palpite trancado:', style: AppTextStyles.sub(context)),
                  Row(
                    children: [
                      Icon(Icons.lock_outline, size: 14, color: colors.phoneMuted),
                      const SizedBox(width: 4),
                      Text(
                        formatPredictionLabel(prediction),
                        style: AppTextStyles.body(context, weight: FontWeight.w700),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AppButtonOutline(
                label: 'Secar Palpites da Galera',
                onPressed: currentUid == null
                    ? null
                    : () => SecarPalpitesSheet.show(
                        context,
                        repos: repos,
                        groupId: groupId,
                        match: match,
                        memberNames: memberNames,
                        currentUid: currentUid!,
                      ),
              ),
            ],
            if (isFinished && !archived) ...[
              const SizedBox(height: 12),
              Divider(color: colors.phoneBorder),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      hasWinners
                          ? '🏆 Vencedores: ${match.winnerUids.map((uid) => memberNames[uid] ?? uid).join(', ')}'
                          : 'Sem vencedores — pote acumulado',
                      style: AppTextStyles.sub(context).copyWith(fontSize: 12),
                    ),
                  ),
                  Text(
                    'Ver Detalhes >',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: colors.accent,
                    ),
                  ),
                ],
              ),
              if (pot > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Pote Total: ${MoneyFormat.format(amountCents: pot, currency: currency)}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: hasWinners ? colors.gold : colors.phoneMuted,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _PotBanner extends StatelessWidget {
  const _PotBanner({
    required this.amountCents,
    required this.currency,
    this.label = 'POTE ACUMULADO',
  });

  final int amountCents;
  final String currency;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.goldLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.gold.withValues(alpha: 0.35)),
      ),
      child: Text(
        '🔥 $label: ${MoneyFormat.format(amountCents: amountCents, currency: currency)}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: colors.gold,
        ),
      ),
    );
  }
}

bool feedCardCanEditPrediction({
  required GroupMatchOverlay match,
  required int predictionLockMinutes,
}) {
  return match.status == MatchStatus.scheduled &&
      isBeforeLock(match: match, predictionLockMinutes: predictionLockMinutes);
}

bool feedCardLockedForPredictions({
  required GroupMatchOverlay match,
  required int predictionLockMinutes,
}) {
  return !isBeforeLock(match: match, predictionLockMinutes: predictionLockMinutes);
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.teamId, this.crestUrl});

  final String teamId;
  final String? crestUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TeamFlag(teamId: teamId, crestUrl: crestUrl),
        const SizedBox(height: 8),
        Text(
          TeamDisplay.label(teamId),
          style: AppTextStyles.body(context, weight: FontWeight.w600).copyWith(fontSize: 15),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _ScheduledPredictionBlock extends StatefulWidget {
  const _ScheduledPredictionBlock({
    required this.groupId,
    required this.match,
    required this.prediction,
    required this.canEdit,
  });

  final String groupId;
  final GroupMatchOverlay match;
  final Prediction? prediction;
  final bool canEdit;

  @override
  State<_ScheduledPredictionBlock> createState() => _ScheduledPredictionBlockState();
}

class _ScheduledPredictionBlockState extends State<_ScheduledPredictionBlock> {
  final _inputsKey = GlobalKey<InlinePredictionInputsState>();
  bool _saving = false;

  Future<void> _save() async {
    final state = _inputsKey.currentState;
    if (state == null) return;
    setState(() => _saving = true);
    try {
      await state.save();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: _TeamSide(teamId: widget.match.homeTeamId, crestUrl: widget.match.homeFlag)),
            Expanded(
              flex: 2,
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: InlinePredictionInputs(
                  key: _inputsKey,
                  groupId: widget.groupId,
                  match: widget.match,
                  prediction: widget.prediction,
                  enabled: widget.canEdit && !_saving,
                ),
              ),
            ),
            Expanded(child: _TeamSide(teamId: widget.match.awayTeamId, crestUrl: widget.match.awayFlag)),
          ],
        ),
        const SizedBox(height: 8),
        AppButton(
          label: 'Salvar Palpite',
          onPressed: widget.canEdit && !_saving ? _save : null,
          isLoading: _saving,
        ),
      ],
    );
  }
}
