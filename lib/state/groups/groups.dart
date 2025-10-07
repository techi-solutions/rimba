import 'package:flutter/cupertino.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/services/groups/groups.dart';

class GroupsState extends ChangeNotifier {
  // Services
  final GroupsService _groupsService = GroupsService();

  // State variables
  List<Group> groups = [];
  List<GroupMember> currentGroupMembers = [];
  Group? selectedGroup;
  String searchQuery = '';
  bool isLoading = false;
  String? error;

  // Private variables
  bool _mounted = true;

  // Constructor
  GroupsState();

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

  /// Fetch all groups
  Future<void> fetchGroups() async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      groups = await _groupsService.getGroups();
    } catch (e) {
      error = 'Failed to fetch groups: $e';
      print('Error fetching groups: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Create a new group
  Future<Group?> createGroup({
    required String name,
    String? description,
    required String amount,
    required List<String> memberAccounts,
  }) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final newGroup = await _groupsService.createGroup(
        name: name,
        description: description,
        amount: amount,
        memberAccounts: memberAccounts,
      );

      groups.add(newGroup);
      return newGroup;
    } catch (e) {
      error = 'Failed to create group: $e';
      print('Error creating group: $e');
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Update an existing group
  Future<Group?> updateGroup({
    required String id,
    String? name,
    String? description,
    String? amount,
  }) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final updatedGroup = await _groupsService.updateGroup(
        id: id,
        name: name,
        description: description,
        amount: amount,
      );

      if (updatedGroup != null) {
        final index = groups.indexWhere((group) => group.id == id);
        if (index != -1) {
          groups[index] = updatedGroup;
        }

        // Update selected group if it's the one being updated
        if (selectedGroup?.id == id) {
          selectedGroup = updatedGroup;
        }
      }

      return updatedGroup;
    } catch (e) {
      error = 'Failed to update group: $e';
      print('Error updating group: $e');
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Delete a group
  Future<bool> deleteGroup(String id) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final success = await _groupsService.deleteGroup(id);

      if (success) {
        groups.removeWhere((group) => group.id == id);

        // Clear selected group if it's the one being deleted
        if (selectedGroup?.id == id) {
          selectedGroup = null;
          currentGroupMembers = [];
        }
      }

      return success;
    } catch (e) {
      error = 'Failed to delete group: $e';
      print('Error deleting group: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Get a specific group by ID
  Future<Group?> getGroupById(String id) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final group = await _groupsService.getGroupById(id);
      return group;
    } catch (e) {
      error = 'Failed to fetch group: $e';
      print('Error fetching group: $e');
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Select a group and fetch its members
  Future<void> selectGroup(String id) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final group = await _groupsService.getGroupById(id);
      if (group != null) {
        selectedGroup = group;
        currentGroupMembers = await _groupsService.getGroupMembers(id);
      }
    } catch (e) {
      error = 'Failed to select group: $e';
      print('Error selecting group: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Clear selected group
  void clearSelectedGroup() {
    selectedGroup = null;
    currentGroupMembers = [];
    safeNotifyListeners();
  }

  /// Add a member to the selected group
  Future<GroupMember?> addGroupMember(String contactAccount) async {
    if (selectedGroup == null) return null;

    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final newMember = await _groupsService.addGroupMember(
        groupId: selectedGroup!.id,
        contactAccount: contactAccount,
      );

      if (newMember != null) {
        currentGroupMembers.add(newMember);

        // Update the group in the list with new member count
        final index =
            groups.indexWhere((group) => group.id == selectedGroup!.id);
        if (index != -1) {
          final updatedGroup =
              await _groupsService.getGroupById(selectedGroup!.id);
          if (updatedGroup != null) {
            groups[index] = updatedGroup;
            selectedGroup = updatedGroup;
          }
        }
      }

      return newMember;
    } catch (e) {
      error = 'Failed to add group member: $e';
      print('Error adding group member: $e');
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Remove a member from the selected group
  Future<bool> removeGroupMember(String contactAccount) async {
    if (selectedGroup == null) return false;

    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final success = await _groupsService.removeGroupMember(
        groupId: selectedGroup!.id,
        contactAccount: contactAccount,
      );

      if (success) {
        currentGroupMembers.removeWhere(
          (member) => member.contactAccount == contactAccount,
        );

        // Update the group in the list with new member count
        final index =
            groups.indexWhere((group) => group.id == selectedGroup!.id);
        if (index != -1) {
          final updatedGroup =
              await _groupsService.getGroupById(selectedGroup!.id);
          if (updatedGroup != null) {
            groups[index] = updatedGroup;
            selectedGroup = updatedGroup;
          }
        }
      }

      return success;
    } catch (e) {
      error = 'Failed to remove group member: $e';
      print('Error removing group member: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Search groups
  Future<void> searchGroups(String query) async {
    try {
      isLoading = true;
      error = null;
      searchQuery = query;
      safeNotifyListeners();

      if (query.isEmpty) {
        groups = await _groupsService.getGroups();
      } else {
        groups = await _groupsService.searchGroups(query);
      }
    } catch (e) {
      error = 'Failed to search groups: $e';
      print('Error searching groups: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Clear search
  void clearSearch() {
    searchQuery = '';
    fetchGroups();
  }

  /// Clear error
  void clearError() {
    error = null;
    safeNotifyListeners();
  }

  /// Get filtered groups based on search query
  List<Group> get filteredGroups {
    if (searchQuery.isEmpty) return groups;

    final lowercaseQuery = searchQuery.toLowerCase();
    return groups.where((group) {
      return group.name.toLowerCase().contains(lowercaseQuery) ||
          (group.description?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Check if a group has a specific member
  bool hasMember(String groupId, String contactAccount) {
    return currentGroupMembers.any(
      (member) =>
          member.groupId == groupId && member.contactAccount == contactAccount,
    );
  }

  /// Get member count for a specific group
  int getMemberCount(String groupId) {
    return currentGroupMembers
        .where((member) => member.groupId == groupId)
        .length;
  }
}
