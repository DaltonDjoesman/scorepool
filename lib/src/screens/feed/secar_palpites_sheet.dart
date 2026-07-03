import 'package:flutter/material.dart';

import '../../models/match.dart';
import '../../models/prediction.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_text_styles.dart';
import 'inline_prediction_inputs.dart';

class SecarPalpitesSheet extends StatelessWidget {
  const SecarPalpitesSheet({
    super.key,
    required this.repos,
    required this.groupId,
    required this.match,
    required this.memberNames,
    required this.currentUid,
  });

  final Repositories repos;
  final String groupId;
  final GroupMatchOverlay match;
  final Map<String, String> memberNames;
  final String currentUid;

  static Future<void> show(
    BuildContext context, {
    required Repositories repos,
    required String groupId,
    required GroupMatchOverlay match,
    required Map<String, String> memberNames,
    required String currentUid,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SecarPalpitesSheet(
        repos: repos,
        groupId: groupId,
        match: match,
        memberNames: memberNames,
        currentUid: currentUid,
      ),
    );
  }

  String _nameFor(String uid) => memberNames[uid] ?? uid;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Secar Palpites da Galera',
                style: AppTextStyles.displayHeadline(context, size: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Acompanhando palpites trancados de todos os participantes.',
                style: AppTextStyles.sub(context),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: StreamBuilder<List<Prediction>>(
                  stream: repos.firestore.watchMatchPredictions(
                    groupId: groupId,
                    matchId: match.matchId,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text(snapshot.error.toString()));
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final predictions = [...snapshot.data!]
                      ..sort((a, b) => _nameFor(a.uid).compareTo(_nameFor(b.uid)));

                    if (predictions.isEmpty) {
                      return Center(
                        child: Text(
                          'Ninguém palpitou neste jogo.',
                          style: AppTextStyles.sub(context),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: predictions.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final p = predictions[index];
                        final isMe = p.uid == currentUid;
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${_nameFor(p.uid)}${isMe ? ' (Você)' : ''}',
                                  style: TextStyle(
                                    fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                formatPredictionLabel(p),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
