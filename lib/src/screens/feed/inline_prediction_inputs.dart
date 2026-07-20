import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../models/match.dart';
import '../../models/prediction.dart';
import '../../theme/app_colors.dart';
import '../../utils/prediction_input.dart';
import '../../widgets/app_toast.dart';

class InlinePredictionInputs extends StatefulWidget {
  const InlinePredictionInputs({
    super.key,
    required this.groupId,
    required this.match,
    this.prediction,
    this.enabled = true,
  });

  final String groupId;
  final GroupMatchOverlay match;
  final Prediction? prediction;
  final bool enabled;

  @override
  State<InlinePredictionInputs> createState() => InlinePredictionInputsState();
}

class InlinePredictionInputsState extends State<InlinePredictionInputs> {
  late final TextEditingController _homeController;
  late final TextEditingController _awayController;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _homeController = TextEditingController(
      text: predictionControllerText(widget.prediction?.predictedHomeScore),
    );
    _awayController = TextEditingController(
      text: predictionControllerText(widget.prediction?.predictedAwayScore),
    );
  }

  @override
  void didUpdateWidget(covariant InlinePredictionInputs oldWidget) {
    super.didUpdateWidget(oldWidget);
    syncPredictionControllers(
      prediction: widget.prediction,
      homeController: _homeController,
      awayController: _awayController,
      isSaving: _saving,
    );
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  Future<void> save() async {
    final repos = appRepos(context);
    final uid = appAuth(context)?.user?.uid;
    if (repos == null || uid == null) return;

    final parsed = parsePredictionScores(
      homeText: _homeController.text,
      awayText: _awayController.text,
    );
    if (!parsed.isOk) {
      AppToast.error(context, predictionParseErrorMessage(parsed.error!));
      return;
    }

    setState(() => _saving = true);
    try {
      await persistPrediction(
        predictions: repos.predictions,
        groupId: widget.groupId,
        uid: uid,
        matchId: widget.match.matchId,
        predictedHomeScore: parsed.scores!.home,
        predictedAwayScore: parsed.scores!.away,
      );
      if (!mounted) return;
      AppToast.success(context, 'Palpite salvo!');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        _ScoreBox(
          controller: _homeController,
          enabled: widget.enabled && !_saving,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            'x',
            style: TextStyle(
              fontSize: 16,
              color: colors.phoneMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _ScoreBox(
          controller: _awayController,
          enabled: widget.enabled && !_saving,
        ),
      ],
    );
  }
}

class _ScoreBox extends StatelessWidget {
  const _ScoreBox({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    return SizedBox(
      width: 44,
      height: 40,
      child: TextField(
        controller: controller,
        enabled: enabled,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        maxLength: 2,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colors.phoneFg,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: '-',
          contentPadding: EdgeInsets.zero,
          filled: true,
          fillColor: colors.phoneInputBg,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: colors.phoneBorder),
          ),
        ),
      ),
    );
  }
}
