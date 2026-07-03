import 'package:flutter/material.dart';

import '../../models/debt.dart';
import '../../models/match.dart';
import '../../repositories/firestore_repository.dart';
import '../../repositories/repositories.dart';

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
  });

  final Repositories repos;
  final String groupId;
  final String matchId;
  final GroupMatchOverlay match;
  final String currentUid;
  final String currency;
  final Map<String, String> memberNames;

  @override
  State<PaymentLedgerCard> createState() => _PaymentLedgerCardState();
}

class _PaymentLedgerCardState extends State<PaymentLedgerCard> {
  final Set<String> _declaring = {};

  bool get _canDeclarePaid {
    return DateTime.now().toUtc().isBefore(widget.match.matchTimeUtc);
  }

  String _nameFor(String uid) => widget.memberNames[uid] ?? uid;

  String _formatAmount(int amountCents) {
    final major = amountCents / 100;
    return '${widget.currency} ${major.toStringAsFixed(2)}';
  }

  Future<void> _declarePaid(DebtItem debt) async {
    setState(() => _declaring.add(debt.id));
    try {
      await widget.repos.firestore.declareDebtPaid(
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<DebtItem>>(
      stream: widget.repos.firestore.watchDebtItems(
        groupId: widget.groupId,
        matchId: widget.matchId,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(snapshot.error.toString()),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        final debts = FirestoreRepository.sortDebtsForLedger(snapshot.data!);
        if (debts.isEmpty) {
          return const SizedBox.shrink();
        }

        final pending = debts.where((d) => d.status == DebtStatus.pending).length;
        final paid = debts.length - pending;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Pagamentos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '$pending pendente(s) · $paid pago(s)',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ...debts.map((debt) {
                  final isMine = debt.fromUid == widget.currentUid;
                  final canPay = isMine &&
                      debt.status == DebtStatus.pending &&
                      _canDeclarePaid;
                  final declaring = _declaring.contains(debt.id);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_nameFor(debt.fromUid)} → ${_nameFor(debt.toUid)}',
                    ),
                    subtitle: Text(
                      debt.status == DebtStatus.pending
                          ? 'Pendente'
                          : 'Pago',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_formatAmount(debt.amountCents)),
                        if (canPay) ...[
                          const SizedBox(width: 8),
                          FilledButton.tonal(
                            onPressed: declaring ? null : () => _declarePaid(debt),
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
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}
