import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/group_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class GroupProvider extends ChangeNotifier {
  Group? _currentGroup;
  bool _isLoading = false;
  String? _error;

  Group? get currentGroup => _currentGroup;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadStoredGroup() async {
    final groupId = await StorageService.getGroupId();
    if (groupId == null || groupId.isEmpty) {
      return;
    }

    _isLoading = true;
    notifyListeners();
    try {
      _currentGroup = await FirebaseService.getGroup(groupId);
    } catch (_) {
      // Ignore load errors at startup; user can still join/create explicitly.
      _currentGroup = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createGroup({
    required String groupName,
    required User user,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final groupId = Helpers.generateUserId();
      final groupCode = Helpers.generateGroupCode();

      final group = await FirebaseService.createGroup(
        groupId: groupId,
        groupCode: groupCode,
        groupName: groupName,
        adminId: user.userId,
      );

      final adminUser = user.copyWith(isGroupAdmin: true);
      await FirebaseService.addUserToGroup(
        groupId: groupId,
        userId: user.userId,
        user: adminUser,
      );

      await StorageService.saveGroupId(groupId);
      _currentGroup = group;
      return true;
    } on TimeoutException {
      _error =
        'Request timed out. Please check internet connection and try again.';
      return false;
    } on FirebaseException catch (e) {
      _error = 'Firebase error (${e.code}): ${e.message ?? 'Unknown error'}';
      return false;
    } catch (e) {
      _error = e is StateError
          ? e.message.toString()
          : 'Failed to create group. Check Firebase setup.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinGroup({
    required String groupCode,
    required User user,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final group = await FirebaseService.getGroupByCode(
        groupCode.toUpperCase(),
      );
      if (group == null) {
        _error = 'Invalid group code.';
        return false;
      }

      await FirebaseService.addUserToGroup(
        groupId: group.groupId,
        userId: user.userId,
        user: user,
      );

      await StorageService.saveGroupId(group.groupId);
      _currentGroup = group.copyWith(members: {...group.members, user.userId});
      return true;
    } on TimeoutException {
      _error =
        'Request timed out. Please check internet connection and try again.';
      return false;
    } on FirebaseException catch (e) {
      _error = 'Firebase error (${e.code}): ${e.message ?? 'Unknown error'}';
      return false;
    } catch (e) {
      _error = e is StateError
          ? e.message.toString()
          : 'Failed to join group. Check Firebase setup.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearGroup() async {
    await StorageService.remove('groupId');
    _currentGroup = null;
    notifyListeners();
  }

  Future<bool> updateGroupSettings({
    required String groupName,
    required List<String> tags,
  }) async {
    if (_currentGroup == null) {
      _error = 'No group selected.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseService.updateGroupSettings(
        groupId: _currentGroup!.groupId,
        groupName: groupName,
        tags: tags,
      );

      _currentGroup = _currentGroup!.copyWith(
        groupName: groupName,
        tags: tags,
      );
      return true;
    } catch (e) {
      _error = 'Failed to update group settings.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> removeMember(String userId) async {
    if (_currentGroup == null) {
      _error = 'No group selected.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await FirebaseService.removeUserFromGroup(
        groupId: _currentGroup!.groupId,
        userId: userId,
      );
      final updatedMembers = {..._currentGroup!.members}..remove(userId);
      _currentGroup = _currentGroup!.copyWith(members: updatedMembers);
      return true;
    } catch (e) {
      _error = 'Failed to remove member.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Switch to a different group (for existing members/admins)
  Future<void> setCurrentGroup(Group group) async {
    _isLoading = true;
    notifyListeners();

    try {
      await StorageService.saveGroupId(group.groupId);
      _currentGroup = group;
    } catch (e) {
      _error = 'Failed to switch group: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
