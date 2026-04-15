import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/transaction_model.dart';
import '../services/firebase_service.dart';

class TransactionProvider extends ChangeNotifier {
  final List<Transaction> _transactions = <Transaction>[];
  bool _isLoading = false;
  StreamSubscription<List<Transaction>>? _sub;

  List<Transaction> get transactions =>
      List<Transaction>.unmodifiable(_transactions);
  bool get isLoading => _isLoading;

  void startListening(String groupId) {
    _sub?.cancel();
    _isLoading = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      notifyListeners();
    });

    _sub = FirebaseService.streamGroupTransactions(groupId).listen((items) {
      _transactions
        ..clear()
        ..addAll(items);
      _isLoading = false;
      notifyListeners();
    });
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
