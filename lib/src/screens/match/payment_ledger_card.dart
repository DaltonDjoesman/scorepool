import 'package:flutter/material.dart';

import '../../models/debt.dart';
import '../../models/match.dart';
import '../../models/match_status.dart';
import '../../models/prediction.dart';
import '../../repositories/debts_repository.dart';
import '../../repositories/repositories.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/money_format.dart';
import '../../utils/pot_calculator.dart';
import '../../utils/prediction_input.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/status_badge.dart';

class PaymentLedgerCard extends StatefulWidget {
  const PaymentLedgerCard({
    super.key,
    required this.repos,
    required this.groupId,
    required this.matchId,
    required this.match,
    required this.currentUid,
    required this.currency,
    required this.memberNames,
    required this.entryFeeCents,
  });

  final Repositories repos;
  final String groupId;
  final String matchId;
  final GroupMatchOverlay match;
  final String currentUid;
  final String currency;
  final Map<String, String> memberNames;
  final int entryFeeCents;

  @override
  State<PaymentLedgerCard> createState() => _PaymentLedgerCardState();
}

class _PaymentLedgerCardState extends State<PaymentLedgerCard> {
  final _searchController = TextEditingController();
  final Set<String> _declaring = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _canDeclarePaid =>
      widget.match.status == MatchStatus.finished;

  String _nameFor(String uid) => widget.memberNames[uid] ?? uid;

  bool _matchesSearch(String uid) {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return _nameFor(uid).toLowerCase().contains(q);
  }

  Future<void> _declarePaid(DebtItem debt) async {
    setState(() => _declaring.add(debt.id));
    try {
      await widget.repos.debts.declareDebtPaid(
        groupId: widget.groupId,
        matchId: widget.matchId,
        debtItemId: debt.id,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _declaring.remove(debt.id));
    }
  }

  Future<void> _updateRecipient(DebtItem debt, String toUid) async {
    try {
      await widget.repos.debts.updateDebtRecipient(
        groupId: widget.groupId,
        matchId: widget.matchId,
        debtItemId: debt.id,
        toUid: toUid,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.match.status != MatchStatus.finished ||
        widget.match.winnerUids.isEmpty) {
      return const SizedBox.shrink();
    }

    final colors = appColors(context);
    final isWinner = widget.match.winnerUids.contains(widget.currentUid);
    final hasWinners = widget.match.winnerUids.isNotEmpty;
    final pot = PotCalculator.settledPotCents(widget.match) ?? 0;
    final perWinner = hasWinners ? pot ~/ widget.match.winnerUids.length : 0;

    return StreamBuilder<List<Prediction>>(
      stream: widget.repos.predictions.watchMatchPredictions(
        groupId: widget.groupId,
        matchId: widget.matchId,
      ),
      builder: (context, predSnap) {
        final predictionsByUid = {
          for (final p in predSnap.data ?? []) p.uid: p,
        };

        return StreamBuilder<Map<String, bool>>(
          stream: widget.repos.predictions.watchMatchParticipations(
            groupId: widget.groupId,
            matchId: widget.matchId,
          ),
          builder: (context, partSnap) {
            final participations = partSnap.data ?? {};
            final outOfPotUids = widget.memberNames.keys.where((uid) {
              return !(participations[uid] ?? true) &&
                  !widget.match.winnerUids.contains(uid);
            }).toList();

            return StreamBuilder<List<DebtItem>>(
              stream: widget.repos.debts.watchDebtItems(
                groupId: widget.groupId,
                matchId: widget.matchId,
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AppCard(child: Text(snapshot.error.toString()));
                }
                if (!snapshot.hasData) {
                  return const AppCard(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final debts =
                    DebtsRepository.sortDebtsForLedger(snapshot.data!);
                final pending =
                    debts.where((d) => d.status == DebtStatus.pending);
                final paid = debts.where((d) => d.status == DebtStatus.paid);
                final myPending = pending
                    .where((d) => d.fromUid == widget.currentUid)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      borderColor: colors.gold.withValues(alpha: 0.4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ledger de Pagamentos',
                            style: AppTextStyles.body(
                              context,
                              weight: FontWeight.w700,
                            ).copyWith(color: colors.gold),
                          ),
                          Text(
                            '${pending.length} pendente(s) · ${paid.length} pago(s)',
                            style: AppTextStyles.sub(context).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (hasWinners && !isWinner && myPending.isNotEmpty) ...[
                      AppCard(
                        borderColor: colors.danger.withValues(alpha: 0.3),
                        backgroundColor: colors.danger.withValues(alpha: 0.08),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Seu Status: Errou o Palpite',
                              style: AppTextStyles.body(
                                context,
                                weight: FontWeight.w700,
                              ).copyWith(color: colors.danger),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Você precisa pagar ${MoneyFormat.format(amountCents: myPending.first.amountCents, currency: widget.currency)} '
                              'para ${_nameFor(myPending.first.toUid)}.',
                              style: AppTextStyles.sub(context),
                            ),
                            const SizedBox(height: 12),
                            AppButton(
                              label: 'Já paguei',
                              backgroundColor: colors.danger,
                              onPressed: _canDeclarePaid &&
                                      !_declaring.contains(myPending.first.id)
                                  ? () => _declarePaid(myPending.first)
                                  : null,
                              isLoading:
                                  _declaring.contains(myPending.first.id),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (isWinner && hasWinners) ...[
                      AppCard(
                        borderColor: colors.gold.withValues(alpha: 0.5),
                        backgroundColor: colors.goldLight.withValues(alpha: 0.2),
                        child: Text(
                          '🎉 Você acertou em cheio! Recebe ${MoneyFormat.format(amountCents: perWinner, currency: widget.currency)} do pote.',
                          style: AppTextStyles.body(
                            context,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (debts.isNotEmpty || outOfPotUids.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Fila de Transparência',
                            style: AppTextStyles.titleCaps(context),
                          ),
                          Text(
                            '${paid.length} pago(s) · ${pending.length} pendente(s)',
                            style: AppTextStyles.sub(context).copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'Buscar participante...',
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (pending
                          .where((d) => _matchesSearch(d.fromUid))
                          .isNotEmpty) ...[
                        _SectionHeader(label: 'Pendentes', color: colors.danger),
                        const SizedBox(height: 8),
                        ...pending.where((d) => _matchesSearch(d.fromUid)).map(
                              (d) => _DebtRow(
                                debt: d,
                                nameFor: _nameFor,
                                currency: widget.currency,
                                predictionLabel: formatPredictionLabel(
                                  predictionsByUid[d.fromUid],
                                ),
                                declaring: _declaring.contains(d.id),
                                canPay: d.fromUid == widget.currentUid &&
                                    _canDeclarePaid,
                                onPay: () => _declarePaid(d),
                                winnerUids: widget.match.winnerUids,
                                onRecipientChanged: (toUid) =>
                                    _updateRecipient(d, toUid),
                              ),
                            ),
                        const SizedBox(height: 16),
                      ],
                      if (paid
                          .where((d) => _matchesSearch(d.fromUid))
                          .isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Pagamento Declarado',
                          color: colors.success,
                        ),
                        const SizedBox(height: 8),
                        ...paid.where((d) => _matchesSearch(d.fromUid)).map(
                              (d) => _DebtRow(
                                debt: d,
                                nameFor: _nameFor,
                                currency: widget.currency,
                                predictionLabel: formatPredictionLabel(
                                  predictionsByUid[d.fromUid],
                                ),
                                declaring: false,
                                canPay: false,
                                onPay: null,
                                winnerUids: const [],
                                onRecipientChanged: null,
                              ),
                            ),
                        const SizedBox(height: 16),
                      ],
                      if (widget.match.winnerUids
                          .where(_matchesSearch)
                          .isNotEmpty) ...[
                        _SectionHeader(label: 'Vencedores', color: colors.gold),
                        const SizedBox(height: 8),
                        ...widget.match.winnerUids.where(_matchesSearch).map(
                              (uid) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(_nameFor(uid)),
                                subtitle: Text(
                                  'Palpite: ${formatPredictionLabel(predictionsByUid[uid])}',
                                ),
                                trailing: const StatusBadge(
                                  label: '🏆 Vencedor',
                                  variant: StatusBadgeVariant.winner,
                                ),
                              ),
                            ),
                        const SizedBox(height: 16),
                      ],
                      if (outOfPotUids.where(_matchesSearch).isNotEmpty) ...[
                        _SectionHeader(
                          label: 'Fora do Pote',
                          color: colors.phoneMuted,
                        ),
                        const SizedBox(height: 8),
                        ...outOfPotUids.where(_matchesSearch).map(
                              (uid) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(_nameFor(uid)),
                                subtitle: const Text('Não participou desta rodada'),
                                trailing: const StatusBadge(
                                  label: '🚫 Fora',
                                  variant: StatusBadgeVariant.ended,
                                ),
                              ),
                            ),
                      ],
                    ],
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.06,
        color: color,
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({
    required this.debt,
    required this.nameFor,
    required this.currency,
    required this.predictionLabel,
    required this.declaring,
    required this.canPay,
    required this.onPay,
    required this.winnerUids,
    required this.onRecipientChanged,
  });

  final DebtItem debt;
  final String Function(String uid) nameFor;
  final String currency;
  final String predictionLabel;
  final bool declaring;
  final bool canPay;
  final VoidCallback? onPay;
  final List<String> winnerUids;
  final ValueChanged<String>? onRecipientChanged;

  @override
  Widget build(BuildContext context) {
    final colors = appColors(context);
    final pending = debt.status == DebtStatus.pending;
    final showDropdown =
        winnerUids.length > 1 && pending && onRecipientChanged != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(nameFor(debt.fromUid)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palpite: $predictionLabel'),
          Row(
            children: [
              const Text('Pagar a: '),
              if (showDropdown)
                DropdownButton<String>(
                  value: winnerUids.contains(debt.toUid)
                      ? debt.toUid
                      : winnerUids.first,
                  underline: const SizedBox(),
                  style: TextStyle(
                    color: colors.accent,
                    fontWeight: FontWeight.bold,
                  ),
                  items: winnerUids.map((uid) {
                    return DropdownMenuItem<String>(
                      value: uid,
                      child: Text(nameFor(uid)),
                    );
                  }).toList(),
                  onChanged: (newUid) {
                    if (newUid != null && newUid != debt.toUid) {
                      onRecipientChanged!(newUid);
                    }
                  },
                )
              else
                Text(
                  nameFor(debt.toUid),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            MoneyFormat.format(
              amountCents: debt.amountCents,
              currency: currency,
            ),
          ),
          if (canPay && onPay != null) ...[
            const SizedBox(width: 8),
            FilledButton.tonal(
              onPressed: declaring ? null : onPay,
              child: declaring
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Já paguei'),
            ),
          ],
        ],
      ),
    );
  }
}
