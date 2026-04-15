import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/member_service.dart';

class MemberBalanceData {
  final User user;
  final double balance;

  MemberBalanceData({required this.user, required this.balance});

  @override
  String toString() => 'MemberBalanceData(${user.name}, balance: $balance)';
}

class MemberBalanceProvider extends ChangeNotifier {
  final List<MemberBalanceData> _memberBalances = <MemberBalanceData>[];
  bool _isLoading = false;
  StreamSubscription? _memberSub;
  StreamSubscription? _balanceSub;
  String? _currentGroupId;

  List<MemberBalanceData> get memberBalances =>
      List<MemberBalanceData>.unmodifiable(_memberBalances);

  bool get isLoading => _isLoading;

  void startListening(String groupId) {
    _currentGroupId = groupId;
    _isLoading = true;
    notifyListeners();

    // Listen to member changes
    _memberSub?.cancel();
    _memberSub = MemberService.streamGroupMembers(groupId).listen((members) {
      _updateBalances(members);
    });
  }

  void _updateBalances(List<User> members) async {
    try {
      // Get current balances
      final balances = await FirebaseService.getGroupBalances(_currentGroupId!);

      _memberBalances.clear();
      for (final member in members) {
        final balance = balances[member.userId] ?? 0.0;
        _memberBalances.add(MemberBalanceData(user: member, balance: balance));
      }

      // Sort by name for consistent order
      _memberBalances.sort((a, b) => a.user.name.compareTo(b.user.name));

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  void stopListening() {
    _memberSub?.cancel();
    _memberSub = null;
    _balanceSub?.cancel();
    _balanceSub = null;
  }

  @override
  void dispose() {
    _memberSub?.cancel();
    _balanceSub?.cancel();
    super.dispose();
  }
}
