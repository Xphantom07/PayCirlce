import 'package:flutter/foundation.dart';

import '../models/transaction_model.dart';

class BalanceProvider extends ChangeNotifier {
  final Map<String, double> _balances = <String, double>{};

  Map<String, double> get balances =>
      Map<String, double>.unmodifiable(_balances);

  double balanceOf(String userId) => _balances[userId] ?? 0;

  void recomputeFromTransactions({
    required List<Transaction> transactions,
    required Iterable<String> memberIds,
  }) {
    _balances
      ..clear()
      ..addEntries(memberIds.map((id) => MapEntry(id, 0)));

    for (final txn in transactions) {
      if (txn.deleted || txn.participants.isEmpty) {
        continue;
      }
      final share = txn.amount / txn.participants.length;

      _balances[txn.paidBy] =
          (_balances[txn.paidBy] ?? 0) + (txn.amount - share);
      for (final participant in txn.participants) {
        if (participant == txn.paidBy) {
          continue;
        }
        _balances[participant] = (_balances[participant] ?? 0) - share;
      }
    }

    notifyListeners();
  }
}
