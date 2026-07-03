import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';

class PredictionInputCard extends StatefulWidget {
  const PredictionInputCard({
    super.key,
    required this.repos,
    required this.groupId,
    required this.uid,
    required this.match,
    required this.canEdit,
    this.prediction,
  });

  final Repositories repos;
  final String groupId;
  final String uid;
  final GroupMatchOverlay match;
  final bool canEdit;
  final Prediction? prediction;

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
    final key =
        '${widget.prediction?.predictedHomeScore}_${widget.prediction?.predictedAwayScore}';
    if (_loadedKey == key || _saving) return;
    _loadedKey = key;
    _homeController.text =
        widget.prediction?.predictedHomeScore?.toString() ?? '';
    _awayController.text =
        widget.prediction?.predictedAwayScore?.toString() ?? '';
  }

  @override
  void dispose() {
    _homeController.dispose();
    _awayController.dispose();
    super.dispose();
  }

  int? _parseScore(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return null;
    return int.tryParse(trimmed);
  }

  Future<void> _save({required int? home, required int? away}) async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.repos.firestore.upsertPrediction(
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
    final home = _parseScore(_homeController.text);
    final away = _parseScore(_awayController.text);
    final homeEmpty = _homeController.text.trim().isEmpty;
    final awayEmpty = _awayController.text.trim().isEmpty;

    if (homeEmpty && awayEmpty) {
      await _save(home: null, away: null);
      return;
    }

    if (homeEmpty != awayEmpty) {
      setState(() => _error = 'Preencha os dois placares ou deixe ambos vazios.');
      return;
    }

    if (home == null || away == null || home < 0 || away < 0) {
      setState(() => _error = 'Use números inteiros maiores ou iguais a zero.');
      return;
    }

    await _save(home: home, away: away);
  }

  String _readOnlyLabel() {
    final home = widget.prediction?.predictedHomeScore;
    final away = widget.prediction?.predictedAwayScore;
    if (home == null || away == null) return 'Sem palpite';
    return '$home x $away';
  }

  @override
  Widget build(BuildContext context) {
    final showEditor =
        widget.canEdit && widget.match.status == MatchStatus.scheduled;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Palpite',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (!showEditor) ...[
              Text(
                _readOnlyLabel(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                widget.prediction == null
                    ? 'Você pode participar do pote sem palpitar.'
                    : 'Palpite registrado para este jogo.',
                style: Theme.of(context).textTheme.bodySmall,
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
                        labelText: widget.match.homeTeamId,
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
                        labelText: widget.match.awayTeamId,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                widget.prediction == null
                    ? 'Sem palpite — você ainda entra no pote se estiver participando.'
                    : 'Palpite atual: ${_readOnlyLabel()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () async {
                              _homeController.clear();
                              _awayController.clear();
                              await _save(home: null, away: null);
                            },
                      child: const Text('Limpar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
