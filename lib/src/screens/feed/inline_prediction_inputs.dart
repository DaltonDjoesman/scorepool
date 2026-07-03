import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../models/match.dart';
import '../../models/prediction.dart';
import '../../theme/app_colors.dart';
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
      text: widget.prediction?.predictedHomeScore?.toString() ?? '',
    );
    _awayController = TextEditingController(
      text: widget.prediction?.predictedAwayScore?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant InlinePredictionInputs oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_saving) return;
    final home = widget.prediction?.predictedHomeScore?.toString() ?? '';
    final away = widget.prediction?.predictedAwayScore?.toString() ?? '';
    if (_homeController.text != home) _homeController.text = home;
    if (_awayController.text != away) _awayController.text = away;
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

    final homeEmpty = _homeController.text.trim().isEmpty;
    final awayEmpty = _awayController.text.trim().isEmpty;
    int? home;
    int? away;

    if (!homeEmpty || !awayEmpty) {
      if (homeEmpty != awayEmpty) {
        AppToast.error(context, 'Preencha os dois placares ou deixe ambos vazios.');
        return;
      }
      home = int.tryParse(_homeController.text.trim());
      away = int.tryParse(_awayController.text.trim());
      if (home == null || away == null || home < 0 || away < 0) {
        AppToast.error(context, 'Use números inteiros ≥ 0.');
        return;
      }
    }

    setState(() => _saving = true);
    try {
      await repos.firestore.upsertPrediction(
        groupId: widget.groupId,
        uid: uid,
        matchId: widget.match.matchId,
        predictedHomeScore: home,
        predictedAwayScore: away,
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

String formatPredictionLabel(Prediction? prediction) {
  final home = prediction?.predictedHomeScore;
  final away = prediction?.predictedAwayScore;
  if (home == null || away == null) return 'Sem palpite';
  return '$home x $away';
}
