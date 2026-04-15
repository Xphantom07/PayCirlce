import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/group_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../services/firebase_service.dart';
import '../services/member_service.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_bottom_nav.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  Future<List<User>>? _membersFuture;

  Future<void> _refreshHistory() async {
    final group = context.read<GroupProvider>().currentGroup;
    if (group != null) {
      _membersFuture = MemberService.getGroupMembers(group.groupId);
      context.read<TransactionProvider>().startListening(group.groupId);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteTransaction({
    required String groupId,
    required String txnId,
    required String deletedBy,
    required double amount,
    required String paidBy,
    required List<String> participants,
  }) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final share = amount / participants.length;

      // Roll back balances so balance docs remain consistent after soft delete.
      for (final participant in participants) {
        final reverseDelta = participant == paidBy ? -(amount - share) : share;
        await FirebaseService.updateBalance(
          groupId: groupId,
          userId: participant,
          amount: reverseDelta,
        );
      }

      await FirebaseService.deleteTransaction(
        groupId: groupId,
        txnId: txnId,
        deletedBy: deletedBy,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Transaction deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  String _nameFor(Map<String, String> namesById, String userId) {
    return namesById[userId] ?? userId;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context.read<GroupProvider>().currentGroup;

    if (group != null) {
      _membersFuture = MemberService.getGroupMembers(group.groupId);
      final txnProvider = context.read<TransactionProvider>();
      if (txnProvider.transactions.isEmpty && !txnProvider.isLoading) {
        txnProvider.startListening(group.groupId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().currentGroup;
    final user = context.watch<UserProvider>().currentUser;
    final txns = context.watch<TransactionProvider>().transactions;
    final isLoading = context.watch<TransactionProvider>().isLoading;

    if (group == null || user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.all(4),
            child: AppLogo(size: 40),
          ),
          title: const Text('Transaction History'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: _refreshHistory,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        bottomNavigationBar: const MainBottomNav(currentIndex: 3),
        body: const Center(child: Text('Group or user not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Transaction History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 3),
      body: FutureBuilder<List<User>>(
        future: _membersFuture,
        builder: (context, snapshot) {
          final members = snapshot.data ?? <User>[];
          final namesById = <String, String>{
            for (final m in members) m.userId: m.name,
          };

          if (isLoading && txns.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (txns.isEmpty) {
            return const Center(child: Text('No transactions yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: txns.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final txn = txns[index];
              final paidByName = _nameFor(namesById, txn.paidBy);
              final participantNames = txn.participants
                  .map((id) => _nameFor(namesById, id))
                  .join(', ');
              final dateLabel = DateFormat(
                'dd MMM yyyy, hh:mm a',
              ).format(txn.timestamp);
              final canDelete = !txn.deleted && txn.paidBy == user.userId;

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (txn.tag != null && txn.tag!.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      txn.tag!,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                Text(
                                  txn.description?.trim().isNotEmpty == true
                                      ? txn.description!.trim()
                                      : 'Expense',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${txn.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Paid by: $paidByName'),
                      const SizedBox(height: 4),
                      Text('Participants: $participantNames'),
                      const SizedBox(height: 4),
                      Text(
                        dateLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      if (txn.deleted) ...[
                        const SizedBox(height: 8),
                        const Text(
                          'Deleted',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ] else if (canDelete) ...[
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: const Text(
                                    'Are you sure you want to delete this transaction?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await _deleteTransaction(
                                  groupId: group.groupId,
                                  txnId: txn.txnId,
                                  deletedBy: user.userId,
                                  amount: txn.amount,
                                  paidBy: txn.paidBy,
                                  participants: txn.participants,
                                );
                              }
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
