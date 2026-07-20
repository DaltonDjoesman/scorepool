import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app.dart';
import '../../models/group.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/money_format.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_toast.dart';

/// Regulamento tab inside the feed shell (styled cards in section 7).
class RulesTab extends StatelessWidget {
  const RulesTab({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context) {
    final repos = appRepos(context);

    if (repos == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text('Firebase não configurado.', style: AppTextStyles.body(context)),
      );
    }

    return StreamBuilder<Group?>(
      stream: repos.groups.watchGroup(groupId),
      builder: (context, snapshot) {
        final group = snapshot.data;
        if (group == null && snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (group == null) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Grupo não encontrado.', style: AppTextStyles.sub(context)),
          );
        }

        final fee = MoneyFormat.format(
          amountCents: group.entryFeeCents,
          currency: group.currency,
        );

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Regulamento', style: AppTextStyles.displayHeadline(context, size: 20)),
            const SizedBox(height: 8),
            Text(
              'Regras acordadas para este bolão.',
              style: AppTextStyles.sub(context),
            ),
            const SizedBox(height: 16),
            _GroupInviteCard(groupId: groupId, groupName: group.name),
            const SizedBox(height: 16),
            AppCard(
              child: _RuleBlock(
                emoji: '💰',
                title: 'Aposta por Partida',
                body:
                    'Cada jogo tem entrada fixa de $fee. Pagos fora do aplicativo de forma transparente aos ganhadores do pote.',
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: _RuleBlock(
                emoji: '🔒',
                title: 'Bloqueio de Palpites',
                body:
                    'Tranca automaticamente ${group.predictionLockMinutes} minutos antes do início de cada jogo. Sem alterações posteriores.',
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: _RuleBlock(
                emoji: '🎯',
                title: 'Vencedor Único',
                body:
                    'Somente acerto EXATO do placar ganha. Se 2 ou mais pessoas acertarem o placar exato, dividem o pote.',
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              child: _RuleBlock(
                emoji: '❄️',
                title: 'Efeito Bola de Neve',
                body:
                    'Caso ninguém acerte o placar exato da rodada, o pote acumula integralmente para a partida seguinte.',
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GroupInviteCard extends StatelessWidget {
  const _GroupInviteCard({
    required this.groupId,
    required this.groupName,
  });

  final String groupId;
  final String groupName;

  Future<void> _copyCode(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: groupId));
    if (!context.mounted) return;
    AppToast.success(context, 'Código copiado!');
  }

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);

    return AppCard(
      borderColor: colors.accent.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🔗', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Convidar ao bolão',
                      style: AppTextStyles.body(context, weight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Envie o código abaixo para outras pessoas entrarem em '
                      '"$groupName". No app: Área do usuário → Entrar com código → colar.',
                      style: AppTextStyles.sub(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colors.phoneInputBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.phoneBorder),
            ),
            child: SelectableText(
              groupId,
              style: AppTextStyles.body(context, weight: FontWeight.w600).copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 12),
          AppButtonOutline(
            label: 'Copiar código do bolão',
            icon: Icon(Icons.copy, size: 18, color: colors.accent),
            onPressed: () => _copyCode(context),
          ),
        ],
      ),
    );
  }
}

class _RuleBlock extends StatelessWidget {
  const _RuleBlock({
    required this.emoji,
    required this.title,
    required this.body,
  });

  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body(context, weight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(body, style: AppTextStyles.sub(context)),
            ],
          ),
        ),
      ],
    );
  }
}
