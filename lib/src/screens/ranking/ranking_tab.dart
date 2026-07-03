import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../../models/member.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import 'podium_widget.dart';

/// Ranking tab content inside the feed shell (HTML prototype style).
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

    return StreamBuilder<Group?>(
      stream: repos.firestore.watchGroup(groupId),
      builder: (context, groupSnap) {
        final group = groupSnap.data;
        final isAdmin = uid != null && (group?.adminUids.contains(uid) ?? false);

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
                    isAdmin: isAdmin,
                    repos: repos,
                    groupId: groupId,
                  );
                }),
              ],
            );
          },
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
    required this.isAdmin,
    required this.repos,
    required this.groupId,
  });

  final int rank;
  final MemberProfile member;
  final bool isCurrentUser;
  final bool isAdmin;
  final Repositories repos;
  final String groupId;

  String _displayName() =>
      member.displayName.isNotEmpty ? member.displayName : member.uid;

  Future<void> _editScore(BuildContext context) async {
    final controller = TextEditingController(
      text: '${member.perfectScoresCount}',
    );
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ajustar acertos — ${_displayName()}'),
        content: Form(
          key: formKey,
          child: AppTextField(
            controller: controller,
            label: 'Placares exatos',
            keyboardType: TextInputType.number,
            validator: (value) {
              final n = int.tryParse(value?.trim() ?? '');
              if (n == null || n < 0) return 'Use um número ≥ 0';
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          AppButton(
            label: 'Salvar',
            expand: false,
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) return;

    try {
      await repos.firestore.updateMemberPerfectScoresCount(
        groupId: groupId,
        uid: member.uid,
        perfectScoresCount: int.parse(controller.text.trim()),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return Material(
      color: colors.phoneSurface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: isAdmin ? () => _editScore(context) : null,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
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
              if (isAdmin) ...[
                const SizedBox(width: 8),
                Icon(Icons.edit_outlined, size: 16, color: colors.phoneMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
