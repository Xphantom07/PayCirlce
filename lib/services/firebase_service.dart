import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/firebase_config.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/group_model.dart';

class FirebaseService {
  static final _instance = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get groupsCollection =>
      _instance.collection('groups');
  static CollectionReference get authUsersCollection =>
      _instance.collection('auth_users');

  static void _ensureReady() {
    if (!FirebaseConfig.isReady) {
      throw StateError(
        'Firebase is not configured for this platform yet. Complete FlutterFire setup for Android, iOS, and Web.',
      );
    }
  }

  /// Create a new group
  static Future<Group> createGroup({
    required String groupId,
    required String groupCode,
    required String groupName,
    required String adminId,
  }) async {
    _ensureReady();
    final group = Group(
      groupId: groupId,
      groupCode: groupCode,
      groupName: groupName,
      members: {adminId},
      adminId: adminId,
      createdAt: DateTime.now(),
    );

    try {
      await groupsCollection.doc(groupId).set(group.toJson());
      return group;
    } catch (e) {
      rethrow;
    }
  }

  /// Get group by ID
  static Future<Group?> getGroup(String groupId) async {
    _ensureReady();

    try {
      final doc = await groupsCollection.doc(groupId).get();
      if (doc.exists) {
        return Group.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get group by code
  static Future<Group?> getGroupByCode(String groupCode) async {
    _ensureReady();

    try {
      final query = await groupsCollection
          .where('groupCode', isEqualTo: groupCode)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return Group.fromJson(query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Add user to group
  static Future<void> addUserToGroup({
    required String groupId,
    required String userId,
    required User user,
  }) async {
    _ensureReady();

    try {
      // Add user to members set
      await groupsCollection.doc(groupId).update({
        'members': FieldValue.arrayUnion([userId]),
      });

      // Add user document in group subcollection
      await groupsCollection
          .doc(groupId)
          .collection('users')
          .doc(userId)
          .set(user.toJson());

      // Initialize balance for user
      await groupsCollection
          .doc(groupId)
          .collection('balances')
          .doc(userId)
          .set({
            'userId': userId,
            'amount': 0.0,
            'lastUpdated': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Update group-level settings like name and tags.
  static Future<void> updateGroupSettings({
    required String groupId,
    String? groupName,
    List<String>? tags,
  }) async {
    _ensureReady();
    final updates = <String, dynamic>{};
    if (groupName != null) {
      updates['groupName'] = groupName.trim();
    }
    if (tags != null) {
      updates['tags'] = tags;
    }
    if (updates.isEmpty) {
      return;
    }
    await groupsCollection.doc(groupId).update(updates);
  }

  /// Remove a member from group and related sub-collections.
  static Future<void> removeUserFromGroup({
    required String groupId,
    required String userId,
  }) async {
    _ensureReady();

    final groupRef = groupsCollection.doc(groupId);
    await groupRef.update({
      'members': FieldValue.arrayRemove([userId]),
    });
    await groupRef.collection('users').doc(userId).delete();
    await groupRef.collection('balances').doc(userId).delete();
  }

  /// Add transaction
  static Future<void> addTransaction({
    required String groupId,
    required app_models.Transaction transaction,
  }) async {
    _ensureReady();

    try {
      await groupsCollection
          .doc(groupId)
          .collection('transactions')
          .doc(transaction.txnId)
          .set(transaction.toJson());
    } catch (e) {
      rethrow;
    }
  }

  /// Get all transactions for group
  static Future<List<app_models.Transaction>> getGroupTransactions(
    String groupId,
  ) async {
    _ensureReady();

    try {
      final query = await groupsCollection
          .doc(groupId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .get();

      return query.docs
          .map((doc) => app_models.Transaction.fromJson(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream transactions for real-time updates
  static Stream<List<app_models.Transaction>> streamGroupTransactions(
    String groupId,
  ) {
    _ensureReady();

    return groupsCollection
        .doc(groupId)
        .collection('transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => app_models.Transaction.fromJson(doc.data()))
              .toList();
        });
  }

  /// Update user balance
  static Future<void> updateBalance({
    required String groupId,
    required String userId,
    required double amount,
  }) async {
    _ensureReady();

    try {
      await groupsCollection
          .doc(groupId)
          .collection('balances')
          .doc(userId)
          .update({
            'amount': FieldValue.increment(amount),
            'lastUpdated': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Get all balances for group
  static Future<Map<String, double>> getGroupBalances(String groupId) async {
    _ensureReady();

    try {
      final query = await groupsCollection
          .doc(groupId)
          .collection('balances')
          .get();

      final balances = <String, double>{};
      for (final doc in query.docs) {
        final data = doc.data();
        balances[data['userId']] = (data['amount'] as num).toDouble();
      }
      return balances;
    } catch (e) {
      return {};
    }
  }

  /// Delete (mark as deleted) a transaction
  static Future<void> deleteTransaction({
    required String groupId,
    required String txnId,
    required String deletedBy,
  }) async {
    _ensureReady();

    try {
      await groupsCollection
          .doc(groupId)
          .collection('transactions')
          .doc(txnId)
          .update({
            'deleted': true,
            'deletedBy': deletedBy,
            'deletedAt': DateTime.now().toIso8601String(),
          });
    } catch (e) {
      rethrow;
    }
  }

  /// Update user profile in a group (name, photoUrl)
  static Future<void> updateUserProfile({
    required String groupId,
    required String userId,
    required Map<String, dynamic> updates,
  }) async {
    _ensureReady();

    try {
      await groupsCollection
          .doc(groupId)
          .collection('users')
          .doc(userId)
          .update(updates);
    } catch (e) {
      rethrow;
    }
  }

  /// Save or update auth profile for login across reinstalls/devices.
  static Future<void> upsertAuthUser({
    required String userId,
    required String name,
    required String email,
    required String passwordHash,
    required String pinHash,
    String? photoUrl,
    DateTime? createdAt,
  }) async {
    _ensureReady();
    final normalizedEmail = email.trim().toLowerCase();
    final now = DateTime.now().toIso8601String();

    await authUsersCollection.doc(userId).set({
      'userId': userId,
      'name': name,
      'email': normalizedEmail,
      'emailLower': normalizedEmail,
      'passwordHash': passwordHash,
      'pinHash': pinHash,
      'photoUrl': photoUrl,
      'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  /// Fetch auth profile by email (case-insensitive via normalized field).
  static Future<Map<String, dynamic>?> getAuthUserByEmail(String email) async {
    _ensureReady();
    final normalizedEmail = email.trim().toLowerCase();

    final query = await authUsersCollection
        .where('emailLower', isEqualTo: normalizedEmail)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      return null;
    }
    return query.docs.first.data() as Map<String, dynamic>;
  }
}
