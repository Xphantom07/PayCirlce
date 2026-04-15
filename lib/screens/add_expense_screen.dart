import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../providers/group_provider.dart';
import '../providers/user_provider.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../services/member_service.dart';
import '../utils/helpers.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_bottom_nav.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _selectedTag;
  final Set<String> _selectedParticipants = <String>{};

  bool _areAllSelected(Iterable<String> memberIds) {
    if (memberIds.isEmpty) {
      return false;
    }
    return memberIds.every(_selectedParticipants.contains);
  }

  void _toggleSelectAll(Iterable<String> memberIds, bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedParticipants
          ..clear()
          ..addAll(memberIds);
      } else {
        _selectedParticipants.clear();
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<bool> _showPinDialog() async {
    final pinController = TextEditingController();
    try {
      final result =
          await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) => AlertDialog(
              title: const Text('Verify PIN'),
              content: TextField(
                controller: pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 4,
                decoration: const InputDecoration(
                  hintText: 'Enter 4-digit PIN',
                  counterText: '',
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ) ??
          false;

      if (result && pinController.text.isNotEmpty) {
        final isValid = await AuthService.verifyStoredPin(pinController.text);
        return isValid;
      }
      return false;
    } finally {
      pinController.dispose();
    }
  }

  Future<void> _addExpense() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (_selectedParticipants.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one participant'),
          ),
        );
      }
      return;
    }

    final groupProvider = context.read<GroupProvider>();
    final availableTags = groupProvider.currentGroup?.tags ?? const <String>[];
    if (availableTags.isNotEmpty &&
        (_selectedTag == null || _selectedTag!.isEmpty)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select a tag')));
      }
      return;
    }

    // Capture all context references BEFORE any async call
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final userProvider = context.read<UserProvider>();

    final pinVerified = await _showPinDialog();
    if (!pinVerified) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('PIN verification failed')),
        );
      }
      return;
    }

    final user = userProvider.currentUser;
    final group = groupProvider.currentGroup;

    if (user == null || group == null) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('User or group not found')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final amount = double.parse(_amountController.text);
      final participants = {..._selectedParticipants, user.userId}.toList();

      final transaction = Transaction(
        txnId: Helpers.generateUserId(),
        amount: amount,
        paidBy: user.userId,
        participants: participants,
        timestamp: DateTime.now(),
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        tag: _selectedTag,
      );

      await FirebaseService.addTransaction(
        groupId: group.groupId,
        transaction: transaction,
      ).timeout(const Duration(seconds: 10));

      // Update balances for all participants
      final share = amount / participants.length;
      for (final participant in participants) {
        final balanceChange = participant == user.userId
            ? (amount - share)
            : -share;
        await FirebaseService.updateBalance(
          groupId: group.groupId,
          userId: participant,
          amount: balanceChange,
        ).timeout(const Duration(seconds: 10));
      }

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Expense added successfully!')),
      );

      _amountController.clear();
      _descriptionController.clear();
      _selectedTag = null;
      _selectedParticipants.clear();
      setState(() {});

      // Pop after success
      if (mounted) {
        nav.pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to add expense: $e';
      });
      if (mounted) {
        messenger.showSnackBar(SnackBar(content: Text(_error!)));
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = context.watch<GroupProvider>().currentGroup;
    final user = context.watch<UserProvider>().currentUser;

    if (group == null || user == null) {
      return Scaffold(
        appBar: AppBar(
          leading: const Padding(
            padding: EdgeInsets.all(4),
            child: AppLogo(size: 40),
          ),
          title: const Text('Add Expense'),
          actions: [
            IconButton(
              tooltip: 'Refresh',
              onPressed: () {
                FocusScope.of(context).unfocus();
                setState(() {});
              },
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        bottomNavigationBar: const MainBottomNav(currentIndex: 2),
        body: const Center(child: Text('Group or user not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Add Expense'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () {
              FocusScope.of(context).unfocus();
              setState(() {});
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(paddingMedium),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Group: ${group.groupName}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Paid by: ${user.name}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Amount is required';
                  }
                  if (double.tryParse(value) == null ||
                      double.parse(value) <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              if (group.tags.isNotEmpty) ...[
                const Text(
                  'Select Tag',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8.0,
                  children: group.tags.map((tag) {
                    return ChoiceChip(
                      label: Text(tag),
                      selected: _selectedTag == tag,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTag = selected ? tag : null;
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'e.g., Dinner, Groceries',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLength: 100,
              ),
              const SizedBox(height: 16),
              const Text(
                'Select Participants',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<User>>(
                stream: MemberService.streamGroupMembers(group.groupId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final members = snapshot.data ?? <User>[];
                  final memberIds = members.map((m) => m.userId).toSet();
                  final allSelected = _areAllSelected(memberIds);
                  final partiallySelected =
                      _selectedParticipants.isNotEmpty && !allSelected;

                  return Column(
                    children: [
                      CheckboxListTile(
                        key: const ValueKey('select_all'),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Select All',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        tristate: true,
                        value: allSelected
                            ? true
                            : partiallySelected
                            ? null
                            : false,
                        onChanged: _isLoading
                            ? null
                            : (value) =>
                                  _toggleSelectAll(memberIds, value == true),
                      ),
                      const Divider(height: 1),
                      ...members.map((member) {
                        final isCurrentUser = member.userId == user.userId;
                        return CheckboxListTile(
                          key: ValueKey(member.userId),
                          title: Text(
                            isCurrentUser
                                ? '${member.name} (You)'
                                : member.name,
                          ),
                          subtitle: member.isGroupAdmin
                              ? const Text(
                                  'Admin',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                          value: _selectedParticipants.contains(member.userId),
                          onChanged: _isLoading
                              ? null
                              : (selected) {
                                  setState(() {
                                    if (selected == true) {
                                      _selectedParticipants.add(member.userId);
                                    } else {
                                      _selectedParticipants.remove(
                                        member.userId,
                                      );
                                    }
                                  });
                                },
                          enabled: !_isLoading,
                        );
                      }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _addExpense,
                child: Text(_isLoading ? 'Adding...' : 'Add Expense'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
