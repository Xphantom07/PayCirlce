import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class MemberService {
  static final _instance = FirebaseFirestore.instance;

  static CollectionReference get groupsCollection =>
      _instance.collection('groups');

  /// Get user from group's users subcollection
  static Future<User?> getGroupMemberUser({
    required String groupId,
    required String userId,
  }) async {
    try {
      final doc = await groupsCollection
          .doc(groupId)
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return User.fromJson(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all group members with their details
  static Future<List<User>> getGroupMembers(String groupId) async {
    try {
      final query = await groupsCollection
          .doc(groupId)
          .collection('users')
          .get();

      return query.docs.map((doc) => User.fromJson(doc.data())).toList();
    } catch (e) {
      return [];
    }
  }

  /// Stream group members for real-time updates
  static Stream<List<User>> streamGroupMembers(String groupId) {
    return groupsCollection.doc(groupId).collection('users').snapshots().map((
      snapshot,
    ) {
      return snapshot.docs.map((doc) => User.fromJson(doc.data())).toList();
    });
  }
}
