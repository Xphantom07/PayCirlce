import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/firebase_config.dart';
import '../constants/app_constants.dart';
import '../models/group_model.dart';
import '../providers/group_provider.dart';
import '../providers/user_provider.dart';
import '../utils/validators.dart';
import '../widgets/app_logo.dart';
import '../widgets/main_bottom_nav.dart';

class JoinGroupScreen extends StatefulWidget {
  const JoinGroupScreen({super.key});

  @override
  State<JoinGroupScreen> createState() => _JoinGroupScreenState();
}

class _JoinGroupScreenState extends State<JoinGroupScreen> {
  final _joinFormKey = GlobalKey<FormState>();
  final _createFormKey = GlobalKey<FormState>();
  final _groupCodeController = TextEditingController();
  final _groupNameController = TextEditingController();

  @override
  void dispose() {
    _groupCodeController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  /// Fetch groups where user is member
  Future<List<Group>> _getUserMemberGroups() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return [];

    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db
          .collection('groups')
          .where('members', arrayContains: user.userId)
          .get();

      return snapshot.docs.map((doc) => Group.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  /// Fetch groups where user is admin
  Future<List<Group>> _getUserAdminGroups() async {
    final user = context.read<UserProvider>().currentUser;
    if (user == null) return [];

    try {
      final db = FirebaseFirestore.instance;
      final snapshot = await db
          .collection('groups')
          .where('adminId', isEqualTo: user.userId)
          .get();

      return snapshot.docs.map((doc) => Group.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  /// Switch to a different group
  Future<void> _switchToGroup(Group group) async {
    try {
      final provider = context.read<GroupProvider>();
      await provider.setCurrentGroup(group);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed(routeDashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error switching group: $e')));
      }
    }
  }

  Future<void> _joinGroup() async {
    if (!(_joinFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      return;
    }
    final provider = context.read<GroupProvider>();
    final ok = await provider.joinGroup(
      groupCode: _groupCodeController.text.trim().toUpperCase(),
      user: user,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      Navigator.of(context).pushReplacementNamed(routeDashboard);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Unable to join group.')),
    );
  }

  Future<void> _createGroup() async {
    if (!(_createFormKey.currentState?.validate() ?? false)) {
      return;
    }
    final user = context.read<UserProvider>().currentUser;
    if (user == null) {
      return;
    }

    final provider = context.read<GroupProvider>();
    final ok = await provider.createGroup(
      groupName: _groupNameController.text.trim(),
      user: user,
    );

    if (!mounted) {
      return;
    }

    if (ok) {
      Navigator.of(context).pushReplacementNamed(routeDashboard);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(provider.error ?? 'Unable to create group.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<GroupProvider>().isLoading;
    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(4),
          child: AppLogo(size: 40),
        ),
        title: const Text('Join or Create Group'),
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
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                FirebaseConfig.isReady
                    ? ''
                    : 'Firebase not configured for this platform yet. Complete FlutterFire setup to continue.',
                style: TextStyle(
                  color: FirebaseConfig.isReady ? Colors.green : Colors.orange,
                ),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'Join Group'),
                Tab(text: 'Create Group'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  // Join Tab
                  Padding(
                    padding: const EdgeInsets.all(paddingMedium),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _joinFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _groupCodeController,
                              textCapitalization: TextCapitalization.characters,
                              maxLength: 6,
                              decoration: const InputDecoration(
                                labelText: 'Group Code',
                                hintText: 'ABC123',
                              ),
                              validator: Validators.validateGroupCode,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: isLoading ? null : _joinGroup,
                              child: Text(
                                isLoading ? 'Joining...' : 'Join Group',
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'My Groups',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<List<Group>>(
                              future: _getUserMemberGroups(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final groups = snapshot.data ?? [];
                                if (groups.isEmpty) {
                                  return const Text(
                                    'No groups yet. Join or create one!',
                                    style: TextStyle(color: Colors.grey),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groups.length,
                                  itemBuilder: (context, index) {
                                    final group = groups[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(group.groupName),
                                        subtitle: Text(
                                          'Code: ${group.groupCode}',
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward,
                                          color: Colors.grey[400],
                                        ),
                                        onTap: () => _switchToGroup(group),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Create Tab
                  Padding(
                    padding: const EdgeInsets.all(paddingMedium),
                    child: SingleChildScrollView(
                      child: Form(
                        key: _createFormKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _groupNameController,
                              decoration: const InputDecoration(
                                labelText: 'Group Name',
                                hintText: 'Trip Friends',
                              ),
                              validator: Validators.validateGroupName,
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: isLoading ? null : _createGroup,
                              child: Text(
                                isLoading ? 'Creating...' : 'Create Group',
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Divider(),
                            const SizedBox(height: 16),
                            const Text(
                              'My Admin Groups',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FutureBuilder<List<Group>>(
                              future: _getUserAdminGroups(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }

                                final groups = snapshot.data ?? [];
                                if (groups.isEmpty) {
                                  return const Text(
                                    'You are not admin of any groups yet.',
                                    style: TextStyle(color: Colors.grey),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: groups.length,
                                  itemBuilder: (context, index) {
                                    final group = groups[index];
                                    return Card(
                                      child: ListTile(
                                        title: Text(group.groupName),
                                        subtitle: Text(
                                          'Code: ${group.groupCode} • Members: ${group.members.length}',
                                        ),
                                        trailing: Icon(
                                          Icons.arrow_forward,
                                          color: Colors.grey[400],
                                        ),
                                        onTap: () => _switchToGroup(group),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
