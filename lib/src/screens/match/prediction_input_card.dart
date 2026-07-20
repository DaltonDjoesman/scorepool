import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/match.dart';
import '../../utils/prediction_input.dart';
import '../../utils/team_display.dart';
import '../../models/match_status.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class PredictionInputCard extends StatefulWidget {
  const PredictionInputCard({
    super.key,
    required this.repos,
    required this.groupId,
    required this.uid,
    required this.match,
    required this.canEdit,
    this.prediction,
    this.embedded = false,
  });

  final Repositories repos;
  final String groupId;
  final String uid;
  final GroupMatchOverlay match;
  final bool canEdit;
  final Prediction? prediction;
  final bool embedded;

  @override
  State<PredictionInputCard> createState() => _PredictionInputCardState();
}

class _PredictionInputCardState extends State<PredictionInputCard> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  bool _saving = false;
  String? _error;
  String? _loadedKey;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController();
    _awayController = TextEditingController();
    _syncControllers();
  }

  @override
  void didUpdateWidget(covariant PredictionInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncControllers();
  }

  void _syncControllers() {
    _loadedKey = syncPredictionControllersDeduped(
      prediction: widget.prediction,
      homeController: _homeController,
      awayController: _awayController,
      isSaving: _saving,
      lastSyncedKey: _loadedKey,
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  Future<void> _save({required int? home, required int? away}) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await persistPrediction(
        predictions: widget.repos.predictions,
        groupId: widget.groupId,
        uid: widget.uid,
        matchId: widget.match.matchId,
        predictedHomeScore: home,
        predictedAwayScore: away,
      );
      if (!mounted) return;
      _loadedKey = '${home}_$away';
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    final parsed = parsePredictionScores(
      homeText: _homeController.text,
      awayText: _awayController.text,
    );
    if (!parsed.isOk) {
      setState(() => _error = predictionParseErrorMessage(parsed.error!));
      return;
    }

    await _save(home: parsed.scores!.home, away: parsed.scores!.away);
  }

  @override
  Widget build(BuildContext context) {
    final showEditor =
        widget.canEdit && widget.match.status == MatchStatus.scheduled;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Seu Palpite', style: AppTextStyles.body(context, weight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (!showEditor) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Palpite registrado:', style: AppTextStyles.sub(context)),
              Row(
                children: [
                  Icon(Icons.lock_outline, size: 14, color: appColors(context).phoneMuted),
                  const SizedBox(width: 6),
                  Text(
                    formatPredictionLabel(widget.prediction),
                    style: AppTextStyles.body(context, weight: FontWeight.w700),
                  ),
                ],
              ),
            ],
          ),
        ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _homeController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: TeamDisplay.label(widget.match.homeTeamId),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('x'),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _awayController,
                      enabled: !_saving,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        labelText: TeamDisplay.label(widget.match.awayTeamId),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.prediction == null
                    ? 'Sem palpite — você ainda entra no pote se estiver participando.'
                    : 'Palpite atual: ${formatPredictionLabel(widget.prediction)}',
                style: AppTextStyles.sub(context),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButtonOutline(
                      label: 'Limpar',
                      onPressed: _saving
                          ? null
                          : () async {
                              _homeController.clear();
                              _awayController.clear();
                              await _save(home: null, away: null);
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Salvar',
                      isLoading: _saving,
                      onPressed: _saving ? null : _submit,
                    ),
                  ),
                ],
              ),
            ],
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(
            _error!,
            style: TextStyle(color: appColors(context).danger),
          ),
        ],
      ],
    );

    if (widget.embedded) return content;
    return AppCard(child: content);
  }
}
