import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../models/member.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_toast.dart';
import 'podium_widget.dart';

/// Ranking tab content inside the feed shell.
class RankingTab extends StatefulWidget {
  const RankingTab({
    super.key,
    required this.groupId,
    required this.isAdmin,
  });

  final String groupId;
  final bool isAdmin;

  @override
  State<RankingTab> createState() => _RankingTabState();
}

class _RankingTabState extends State<RankingTab> {
  String? _savingMemberUid;

  Future<void> _setScore(MemberProfile member, int newCount) async {
    if (newCount < 0 || newCount == member.perfectScoresCount) return;

    final repos = appRepos(context);
    if (repos == null) return;

    setState(() => _savingMemberUid = member.uid);
    try {
      await repos.profiles.updateMemberPerfectScoresCount(
        groupId: widget.groupId,
        memberUid: member.uid,
        perfectScoresCount: newCount,
      );
      if (!mounted) return;
      AppToast.success(context, 'Pontuação atualizada');
    } catch (e) {
      if (!mounted) return;
      AppToast.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _savingMemberUid = null);
    }
  }

  Future<void> _promptScore(MemberProfile member) async {
    final controller = TextEditingController(
      text: '${member.perfectScoresCount}',
    );
    final newCount = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(_displayName(member)),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Acertos exatos',
              helperText: 'Placares acertados em cheio',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 0) {
                  AppToast.error(context, 'Informe um número ≥ 0.');
                  return;
                }
                Navigator.of(context).pop(parsed);
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (newCount != null) {
      await _setScore(member, newCount);
    }
  }

  String _displayName(MemberProfile member) =>
      member.displayName.isNotEmpty ? member.displayName : member.uid;

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
      stream: repos.profiles.watchMembers(widget.groupId),
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
              widget.isAdmin
                  ? 'Eficiência pura baseada em acertos exatos. Como admin, use +/- ou toque no número para ajustar.'
                  : 'Eficiência pura baseada em acertos exatos do placar.',
              style: AppTextStyles.sub(context),
            ),
            if (sorted.length >= 3) ...[
              const SizedBox(height: 16),
              PodiumWidget(members: sorted.take(3).toList()),
            ],
            const SizedBox(height: 16),
            _RankingTableHeader(showAdminHint: widget.isAdmin),
            const SizedBox(height: 4),
            ...sorted.asMap().entries.map((entry) {
              final rank = entry.key + 1;
              final member = entry.value;
              return _RankingRow(
                rank: rank,
                member: member,
                isCurrentUser: uid == member.uid,
                isAdmin: widget.isAdmin,
                isSaving: _savingMemberUid == member.uid,
                onDecrement: member.perfectScoresCount > 0
                    ? () => _setScore(member, member.perfectScoresCount - 1)
                    : null,
                onIncrement: () => _setScore(member, member.perfectScoresCount + 1),
                onEditScore: () => _promptScore(member),
              );
            }),
          ],
        );
      },
    );
  }
}

class _RankingTableHeader extends StatelessWidget {
  const _RankingTableHeader({required this.showAdminHint});

  final bool showAdminHint;

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
            showAdminHint ? 'ACERTOS (EDITAR)' : 'ACERTOS',
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
    required this.isSaving,
    required this.onIncrement,
    this.onDecrement,
    required this.onEditScore,
  });

  final int rank;
  final MemberProfile member;
  final bool isCurrentUser;
  final bool isAdmin;
  final bool isSaving;
  final VoidCallback? onDecrement;
  final VoidCallback onIncrement;
  final VoidCallback onEditScore;

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
          if (isSaving)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else if (isAdmin)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onDecrement,
                  icon: Icon(Icons.remove_circle_outline, color: colors.phoneMuted),
                ),
                InkWell(
                  onTap: onEditScore,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${member.perfectScoresCount}',
                      style: AppTextStyles.displayHeadline(context, size: 18).copyWith(
                        color: colors.accent,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: onIncrement,
                  icon: Icon(Icons.add_circle_outline, color: colors.accent),
                ),
              ],
            )
          else
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
