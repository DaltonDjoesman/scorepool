import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'podium_widget.dart';

/// Ranking tab content inside the feed shell.
class RankingTab extends StatelessWidget {
  const RankingTab({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final repos = appRepos(context);
    final uid = appAuth(context)?.user?.uid;

    if (repos == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Firebase não configurado.', style: AppTextStyles.body(context)),
      );
    }

    return StreamBuilder<List<MemberProfile>>(
      stream: repos.firestore.watchMembers(groupId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!;
        if (members.isEmpty) {
          return Center(
            child: Text(
              'Nenhum membro no grupo.',
              style: AppTextStyles.sub(context),
            ),
          );
        }

        final sorted = [...members]
          ..sort((a, b) {
            final score = b.perfectScoresCount.compareTo(a.perfectScoresCount);
            if (score != 0) return score;
            final name = a.displayName.compareTo(b.displayName);
            if (name != 0) return name;
            return a.uid.compareTo(b.uid);
          });

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            Text(
              'Ranking de Bruxos',
              style: AppTextStyles.displayHeadline(context, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              'Eficiência pura baseada em acertos exatos do placar.',
              style: AppTextStyles.sub(context),
            ),
            if (sorted.length >= 3) ...[
              const SizedBox(height: 16),
              PodiumWidget(members: sorted.take(3).toList()),
            ],
            const SizedBox(height: 16),
            _RankingTableHeader(),
            const SizedBox(height: 4),
            ...sorted.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final member = entry.value;
              return _RankingRow(
                rank: rank,
                member: member,
                isCurrentUser: uid == member.uid,
              );
            }),
          ],
        );
      },
    );
  }
}

class _RankingTableHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'POSIÇÃO & NOME',
              style: AppTextStyles.titleCaps(context).copyWith(fontSize: 11),
            ),
          ),
          Text(
            'ACERTOS',
            style: AppTextStyles.titleCaps(context).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.member,
    required this.isCurrentUser,
  });

  final int rank;
  final MemberProfile member;
  final bool isCurrentUser;

  String _displayName() =>
      member.displayName.isNotEmpty ? member.displayName : member.uid;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: colors.phoneSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrentUser
              ? colors.accent.withValues(alpha: 0.5)
              : colors.phoneBorder,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$rank. ${_displayName()}${isCurrentUser ? ' (Você)' : ''}',
              style: AppTextStyles.body(
                context,
                weight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
              ).copyWith(
                color: isCurrentUser ? colors.accent : colors.phoneFg,
              ),
            ),
          ),
          Text(
            '${member.perfectScoresCount}',
            style: AppTextStyles.displayHeadline(context, size: 18).copyWith(
              color: isCurrentUser ? colors.accent : colors.phoneFg,
            ),
          ),
        ],
      ),
    );
  }
}
