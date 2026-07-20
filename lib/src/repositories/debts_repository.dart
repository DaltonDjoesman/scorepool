import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/debt.dart';
import 'firestore_client.dart';

class DebtsRepository {
  DebtsRepository(this._client);

  final FirestoreClient _client;

  Stream<List<DebtItem>> watchDebtItems({
    required String groupId,
    required String matchId,
  }) {
    return _client
        .debtItems(groupId: groupId, matchId: matchId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => DebtItem.fromMap(id: d.id, map: d.data()))
              .toList(growable: false),
        );
  }

  Future<void> declareDebtPaid({
    required String groupId,
    required String matchId,
    required String debtItemId,
  }) async {
    await _client
        .debtItems(groupId: groupId, matchId: matchId)
        .doc(debtItemId)
        .update({
          'status': DebtStatus.paid.name,
          'declaredPaidAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> updateDebtRecipient({
    required String groupId,
    required String matchId,
    required String debtItemId,
    required String toUid,
  }) async {
    await _client
        .debtItems(groupId: groupId, matchId: matchId)
        .doc(debtItemId)
        .update({'toUid': toUid});
  }

  static List<DebtItem> sortDebtsForLedger(List<DebtItem> debts) {
    final copy = [...debts];
    copy.sort((a, b) {
      final statusOrder = a.status.index.compareTo(b.status.index);
      if (statusOrder != 0) return statusOrder;
      final fromCompare = a.fromUid.compareTo(b.fromUid);
      if (fromCompare != 0) return fromCompare;
      return a.toUid.compareTo(b.toUid);
    });
    return copy;
  }
}
