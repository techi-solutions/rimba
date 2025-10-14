import 'package:flutter/cupertino.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/services/groups/group_members.dart';
import 'package:pay_app/services/db/app/db.dart';
import 'package:pay_app/services/db/app/group_members.dart';

class GroupMembersState extends ChangeNotifier {
  // Services
  late GroupMembersService _groupMembersService;
  late GroupMembersTable _groupMembersTable;

  // State variables
  List<GroupMember> groupMembers = [];
  bool isLoading = false;
  String? error;

  // Private variables
  bool _mounted = true;

  // Constructor
  GroupMembersState() {
    _groupMembersService = GroupMembersService();
    _groupMembersTable = AppDBService().groupMembers;
  }

  // Safe notify listeners
  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  // State methods

  /// Get members for a specific group
  Future<void> fetchGroupMembers(String groupId) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final dbMembers = await _groupMembersTable.getByGroupId(groupId);
      if (dbMembers.isNotEmpty) {
        groupMembers = dbMembers;
        safeNotifyListeners();
      }

      await _syncGroupMembersFromAPI(groupId);
    } catch (e) {
      error = 'Failed to fetch group members: $e';
      print('Error fetching group members: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Remove user from group
  Future<bool> removeUserFromGroup(String userAddress, String groupId) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final success =
          await _groupMembersService.removeUserFromGroup(userAddress, groupId);

      if (success) {
        await _groupMembersTable.removeMember(groupId, userAddress);

        groupMembers = await _groupMembersTable.getByGroupId(groupId);
        safeNotifyListeners();
      }

      return success;
    } catch (e) {
      error = 'Failed to remove user from group: $e';
      print('Error removing user from group: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    error = null;
    safeNotifyListeners();
  }

  /// Clear group members
  void clearGroupMembers() {
    groupMembers = [];
    safeNotifyListeners();
  }

  /// Sync group members from API
  Future<void> _syncGroupMembersFromAPI(String groupId) async {
    try {
      final apiMembers = await _groupMembersService.getGroupMembers(groupId);

      if (apiMembers.isNotEmpty) {
        // Store in database
        for (final member in apiMembers) {
          await _groupMembersTable.addMember(member);
        }

        // Update UI
        groupMembers = await _groupMembersTable.getByGroupId(groupId);
        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error syncing group members from API: $e');
    }
  }
}
