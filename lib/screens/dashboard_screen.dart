import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';

import '../constants/app_constants.dart';
import '../models/user_model.dart';
import '../providers/group_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../models/transaction_model.dart';
import '../services/member_service.dart';
import '../widgets/main_bottom_nav.dart';
import 'member_profile_screen.dart';
import '../widgets/app_logo.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Future<List<User>>? _membersFuture;
  String? _listeningGroupId;

  Future<void> _openAdminGroupSettings({
    required List<User> members,
    required String adminId,
  }) async {
    final groupProvider = context.read<GroupProvider>();
    final group = groupProvider.currentGroup;
    final user = context.read<UserProvider>().currentUser;
    if (group == null || user == null || user.userId != adminId) {
      return;
    }

    final groupNameController = TextEditingController(text: group.groupName);
    final tagsController = TextEditingController(text: group.tags.join(', '));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final removableMembers = members
                .where((m) => m.userId != adminId)
                .toList();

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 10,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Manage Group',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: groupNameController,
                      decoration: const InputDecoration(
                        labelText: 'Group Name',
                        prefixIcon: Icon(Icons.edit_outlined),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        hintText: 'Food, Travel, Rent',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Remove Members',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (removableMembers.isEmpty)
                      const Text(
                        'No removable members',
                        style: TextStyle(color: Colors.grey),
                      )
                    else
                      ...removableMembers.map(
                        (member) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(member.name),
                          subtitle: Text(
                            member.email.isEmpty ? '-' : member.email,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.person_remove_outlined),
                            color: Colors.red,
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Remove Member'),
                                  content: Text(
                                    'Remove ${member.name} from this group?',
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
                                      child: const Text('Remove'),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm != true) return;
                              final ok = await groupProvider.removeMember(
                                member.userId,
                              );
                              if (!context.mounted) return;
                              if (ok) {
                                setSheetState(() {});
                                setState(() {
                                  _membersFuture =
                                      MemberService.getGroupMembers(
                                        group.groupId,
                                      );
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${member.name} removed'),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      groupProvider.error ??
                                          'Unable to remove member',
                                    ),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final groupName = groupNameController.text.trim();
                          if (groupName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Group name is required'),
                              ),
                            );
                            return;
                          }

                          final tags = tagsController.text
                              .split(',')
                              .map((e) => e.trim())
                              .where((e) => e.isNotEmpty)
                              .toSet()
                              .toList();

                          final ok = await groupProvider.updateGroupSettings(
                            groupName: groupName,
                            tags: tags,
                          );

                          if (!context.mounted) return;
                          if (ok) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Group updated')),
                            );
                            await _refreshDashboard();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  groupProvider.error ??
                                      'Unable to update group',
                                ),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.save_outlined),
                        label: const Text('Save Group Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      // Fix for '_dependents.isEmpty': is not true
      if (mounted) {
        _refreshDashboard();
      }
    });

    groupNameController.dispose();
    tagsController.dispose();
  }

  Future<void> _refreshDashboard() async {
    final groupProvider = context.read<GroupProvider>();
    await groupProvider.loadStoredGroup();
    final group = groupProvider.currentGroup;
    if (group != null) {
      _membersFuture = MemberService.getGroupMembers(group.groupId);
      context.read<TransactionProvider>().startListening(group.groupId);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Map<String, double> _computeBalances({
    required List<Transaction> transactions,
    required Iterable<String> memberIds,
  }) {
    final balances = <String, double>{for (final id in memberIds) id: 0};

    for (final txn in transactions) {
      if (txn.deleted || txn.participants.isEmpty) {
        continue;
      }
      final share = txn.amount / txn.participants.length;
      balances[txn.paidBy] = (balances[txn.paidBy] ?? 0) + (txn.amount - share);

      for (final participant in txn.participants) {
        if (participant == txn.paidBy) {
          continue;
        }
        balances[participant] = (balances[participant] ?? 0) - share;
      }
    }

    return balances;
  }

  ImageProvider? _getProfileImage(String? photoUrl) {
    if (photoUrl == null || photoUrl.isEmpty) {
      return null;
    }

    // Check if it's a Base64 string (doesn't start with http)
    if (!photoUrl.startsWith('http')) {
      try {
        final imageBytes = base64Decode(photoUrl);
        return MemoryImage(imageBytes);
      } catch (e) {
        return null;
      }
    }

    return NetworkImage(photoUrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final group = context.read<GroupProvider>().currentGroup;
    if (group != null && _listeningGroupId != group.groupId) {
      _listeningGroupId = group.groupId;
      _membersFuture = MemberService.getGroupMembers(group.groupId);
      context.read<TransactionProvider>().startListening(group.groupId);
    }
  }

  @override
  void dispose() {
    context.read<TransactionProvider>().stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().currentUser;
    final group = context.watch<GroupProvider>().currentGroup;
    final transactions = context.watch<TransactionProvider>().transactions;
    final balances = group == null
        ? <String, double>{}
        : _computeBalances(
            transactions: transactions,
            memberIds: group.members,
          );

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Home'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(paddingMedium),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hi ${user?.name ?? 'Friend'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.swap_horiz),
                            onPressed: () {
                              Navigator.of(context).pushNamed('/join-group');
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Group: ${group?.groupName ?? 'Not joined'}'),
                      if (group != null) Text('Code: ${group.groupCode}'),
                      if (group != null)
                        Text('Members: ${group.members.length}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => Navigator.of(context).pushNamed(routeRandomPayer),
                child: Ink(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF8A65), Color(0xFFFFD54F)],
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.casino_rounded, color: Colors.white, size: 30),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Random Payer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Spin the wheel and let luck decide',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (group != null)
                FutureBuilder<List<User>>(
                  future: _membersFuture,
                  builder: (context, snapshot) {
                    if (_membersFuture == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final members = snapshot.data ?? [];
                    if (members.isEmpty) {
                      return const Text('No members in group');
                    }

                    return RepaintBoundary(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Member Balances',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (user?.userId == group.adminId)
                                    IconButton(
                                      tooltip: 'Manage group',
                                      onPressed: () => _openAdminGroupSettings(
                                        members: members,
                                        adminId: group.adminId,
                                      ),
                                      icon: const Icon(Icons.settings),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Table(
                                columnWidths: const {
                                  0: FlexColumnWidth(2),
                                  1: FlexColumnWidth(1),
                                },
                                children: [
                                  TableRow(
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                    ),
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(
                                          'Member',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          'Balance',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ...members.map((member) {
                                    final balance =
                                        balances[member.userId] ?? 0;
                                    final isAdmin =
                                        group.adminId == member.userId;
                                    final isCurrentUser =
                                        user?.userId == member.userId;

                                    return TableRow(
                                      decoration: BoxDecoration(
                                        border: Border(
                                          bottom: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                      ),
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute<void>(
                                                  builder: (_) =>
                                                      MemberProfileScreen(
                                                        member: member,
                                                        balance: balance,
                                                        groupName:
                                                            group.groupName,
                                                      ),
                                                ),
                                              );
                                            },
                                            child: Row(
                                              children: [
                                                // Profile Avatar
                                                CircleAvatar(
                                                  radius: 16,
                                                  backgroundImage:
                                                      _getProfileImage(
                                                        member.photoUrl,
                                                      ),
                                                  child:
                                                      (member.photoUrl ==
                                                              null ||
                                                          member
                                                              .photoUrl!
                                                              .isEmpty)
                                                      ? const Icon(
                                                          Icons.person,
                                                          size: 20,
                                                          color: Colors.grey,
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    '${member.name}${isCurrentUser ? ' (You)' : ''}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                if (isAdmin)
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[100],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            4,
                                                          ),
                                                    ),
                                                    child: const Text(
                                                      'Admin',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        color: Colors.orange,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              if (balance > 0.01)
                                                Icon(
                                                  Icons.arrow_upward,
                                                  color: Colors.green,
                                                  size: 16,
                                                )
                                              else if (balance < -0.01)
                                                Icon(
                                                  Icons.arrow_downward,
                                                  color: Colors.red,
                                                  size: 16,
                                                )
                                              else
                                                const SizedBox(width: 16),
                                              const SizedBox(width: 4),
                                              Text(
                                                '₹${balance.abs().toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w500,
                                                  fontSize: 14,
                                                  color: balance > 0.01
                                                      ? Colors.green
                                                      : balance < -0.01
                                                      ? Colors.red
                                                      : Colors.black,
                                                ),
                                                textAlign: TextAlign.right,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    );
                                  }),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).pushNamed(routeAddExpense),
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }
}
