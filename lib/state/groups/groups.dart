import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/models/group_request.dart';
import 'package:pay_app/services/groups/groups.dart';
import 'package:pay_app/services/db/app/db.dart';
import 'package:pay_app/services/db/app/contacts.dart';
import 'package:pay_app/services/db/app/groups.dart';
import 'package:pay_app/services/db/app/group_members.dart';
import 'package:pay_app/services/preferences/preferences.dart';
import 'package:pay_app/services/secure/secure.dart';
import 'package:pay_app/services/config/config.dart';
import 'package:pay_app/services/wallet/wallet.dart';

class GroupsState extends ChangeNotifier {
  // Services
  late GroupsService _groupsService;
  late GroupsTable _groupsTable;
  final ContactsTable _contacts = AppDBService().contacts;
  final GroupMembersTable _groupMembersTable = AppDBService().groupMembers;
  final PreferencesService _preferences = PreferencesService();
  final SecureService _secureService = SecureService();
  final Config _config;

  // State variables
  List<Group> groups = [];
  List<GroupMember> currentGroupMembers = [];
  List<GroupRequest> groupRequests = [];
  Group? selectedGroup;
  String searchQuery = '';
  bool isLoading = false;
  String? error;

  // Private variables
  bool _mounted = true;
  Timer? _pollingTimer;
  static const pollingInterval = 10000;

  // Constructor
  GroupsState({required String account, required Config config})
      : _config = config {
    _groupsService = GroupsService();
    _groupsTable = AppDBService().groups;
  }

  String? get _userAccountAddress {
    final lastAccount = _preferences.lastAccount;
    if (lastAccount != null) {
      return lastAccount;
    }

    // Fall back to secure credentials
    final credentials = _secureService.getCredentials();
    if (credentials == null) {
      return null;
    }

    final (account, _) = credentials;
    return account.hexEip55;
  }

  String? get userAccountAddress => _userAccountAddress;

  // Safe notify listeners
  void safeNotifyListeners() {
    if (_mounted) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _mounted = false;
    stopPolling();
    super.dispose();
  }

  // State methods

  /// Fetch all groups
  Future<void> fetchGroups() async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final dbGroups = await _groupsTable.getAll();
      if (dbGroups.isNotEmpty) {
        groups = dbGroups;
        safeNotifyListeners();
      }

      await _syncGroupsFromAPI();

      startPolling();
    } catch (e) {
      error = 'Failed to fetch groups: $e';
      debugPrint('Error fetching groups: $e');
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
    required List<String> memberIds,
  }) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final creatorAccountAddress = _userAccountAddress;
      if (creatorAccountAddress == null) {
        error = 'No account address found';
        return null;
      }

      final newGroup = await _groupsService.createNewGroup(
        name: name,
        description: description,
        amount: amount,
        userAddress: creatorAccountAddress,
        memberCount: memberIds.length + 1,
      );

      groups.add(newGroup);

      if (memberIds.isNotEmpty) {
        try {
          await _groupsService.sendGroupRequestsToMembers(
            groupId: newGroup.id,
            userAddresses: memberIds,
          );
        } catch (e) {
          debugPrint('Error sending group requests: $e');
        }
      }

      return newGroup;
    } catch (e, stackTrace) {
      error = 'Failed to create group: $e';
      debugPrint('Error creating group: $e');
      debugPrint('Stack trace: $stackTrace');
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
        groupId: id,
        name: name ?? '',
        description: description,
        amount: amount ?? '',
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
        await _groupsTable.upsert(updatedGroup);
      }

      return updatedGroup;
    } catch (e) {
      error = 'Failed to update group: $e';
      debugPrint('Error updating group: $e');
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

      final success = await _groupsService.deleteGroupById(id);

      if (success) {
        groups.removeWhere((group) => group.id == id);

        await _groupsTable.delete(id);

        // Clear selected group if it's the one being deleted
        if (selectedGroup?.id == id) {
          selectedGroup = null;
          currentGroupMembers = [];
        }
      }

      return success;
    } catch (e) {
      error = 'Failed to delete group: $e';
      debugPrint('Error deleting group: $e');
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

      // First, try to load from local database
      final cachedGroup = await _groupsTable.getById(id);
      if (cachedGroup != null) {
        debugPrint('Loaded group $id from cache');
        isLoading = false;
        safeNotifyListeners();

        // Try to sync with API in background
        _syncGroupFromAPI(id);

        return cachedGroup;
      }

      // If not in cache, fetch from API
      final group = await _groupsService.getGroupById(id);
      if (group != null) {
        await _groupsTable.upsert(group);
      }
      return group;
    } catch (e) {
      error = 'Failed to fetch group: $e';
      debugPrint('Error fetching group: $e');

      // Try one more time from cache in case of network error
      final cachedGroup = await _groupsTable.getById(id);
      if (cachedGroup != null) {
        debugPrint('Returning cached group after API error');
        return cachedGroup;
      }

      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Sync a single group from API in background
  Future<void> _syncGroupFromAPI(String id) async {
    try {
      final group = await _groupsService.getGroupById(id);
      if (group != null) {
        await _groupsTable.upsert(group);

        // Update in memory if it's in the list
        final index = groups.indexWhere((g) => g.id == id);
        if (index != -1) {
          groups[index] = group;
        }

        // Update selected group if it's the one we just synced
        if (selectedGroup?.id == id) {
          selectedGroup = group;
        }

        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Background sync failed for group $id: $e');
      // Fail silently - cached data is already being used
    }
  }

  /// Select a group and fetch its members
  Future<void> selectGroup(String id) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      // First, try to load from local database
      final cachedGroup = await _groupsTable.getById(id);
      if (cachedGroup != null) {
        selectedGroup = cachedGroup;
        debugPrint('Loaded selected group from cache');

        // Load cached members
        final cachedMembers = await _groupMembersTable.getByGroupId(id);
        if (cachedMembers.isNotEmpty) {
          currentGroupMembers = cachedMembers;
          debugPrint('Loaded ${cachedMembers.length} group members from cache');
          await _fetchMemberProfiles();
        }

        safeNotifyListeners();
      }

      // Try to fetch fresh data from API
      try {
        final group = await _groupsService.getGroupById(id);
        if (group != null) {
          selectedGroup = group;
          await _groupsTable.upsert(group);

          // Update in groups list
          final index = groups.indexWhere((g) => g.id == id);
          if (index != -1) {
            groups[index] = group;
          }
        }

        final apiMembers = await _groupsService.getGroupMembers(id);
        currentGroupMembers = apiMembers;

        // Cache the members
        await _cacheGroupMembers(id, apiMembers);

        await _fetchMemberProfiles();
      } catch (e) {
        debugPrint('Failed to sync group from API, using cached data: $e');
        // Continue with cached data - don't throw error
        if (selectedGroup == null) {
          throw e; // Only throw if we have no cached data
        }
      }
    } catch (e) {
      error = 'Failed to select group: $e';
      debugPrint('Error selecting group: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Cache group members to local database
  Future<void> _cacheGroupMembers(
      String groupId, List<GroupMember> members) async {
    try {
      // Clear existing members for this group
      await _groupMembersTable.removeAllMembers(groupId);

      // Add all members
      for (final member in members) {
        await _groupMembersTable.addMember(member);
      }

      debugPrint('Cached ${members.length} members for group $groupId');
    } catch (e) {
      debugPrint('Error caching group members: $e');
    }
  }

  Future<void> _fetchMemberProfiles() async {
    if (currentGroupMembers.isEmpty) return;

    final futures =
        currentGroupMembers.map((member) => _fetchMemberProfile(member));
    await Future.wait(futures);
    safeNotifyListeners();
  }

  Future<void> _fetchMemberProfile(GroupMember member) async {
    try {
      // Check cache first
      final contact = await _contacts.getByAccount(member.contactAccount);
      final cachedProfile = contact?.getProfile();

      if (cachedProfile != null) {
        _updateMemberName(member.contactAccount, cachedProfile.name);
        safeNotifyListeners();
      }

      // Fetch from blockchain
      final profile = await getProfile(_config, member.contactAccount);
      if (profile != null) {
        _updateMemberName(member.contactAccount, profile.name);

        // Cache the profile
        await _contacts.upsert(DBContact.fromProfile(profile));
      }
    } catch (e) {
      debugPrint('Failed to fetch profile for ${member.contactAccount}: $e');
    }
  }

  void _updateMemberName(String contactAccount, String name) {
    final index = currentGroupMembers.indexWhere(
      (m) => m.contactAccount == contactAccount,
    );
    if (index != -1) {
      currentGroupMembers[index] = currentGroupMembers[index].copyWith(
        memberName: name,
      );
    }
  }

  /// Clear selected group
  void clearSelectedGroup() {
    selectedGroup = null;
    currentGroupMembers = [];
    safeNotifyListeners();
  }

  /// Send a group request to a user for the selected group
  Future<bool> sendGroupRequest(String userAddress) async {
    if (selectedGroup == null) return false;

    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final request = await _groupsService.sendGroupRequest(
        userAddress: userAddress,
        groupId: selectedGroup!.id,
      );

      return request != null;
    } catch (e) {
      error = 'Failed to send group request: $e';
      debugPrint('Error sending group request: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
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

        // Cache the new member
        await _groupMembersTable.addMember(newMember);

        await _fetchMemberProfile(newMember);

        final index =
            groups.indexWhere((group) => group.id == selectedGroup!.id);
        if (index != -1) {
          final updatedGroup =
              await _groupsService.getGroupById(selectedGroup!.id);
          if (updatedGroup != null) {
            groups[index] = updatedGroup;
            selectedGroup = updatedGroup;
            await _groupsTable.upsert(updatedGroup);
          }
        }
      }

      return newMember;
    } catch (e) {
      error = 'Failed to add group member: $e';
      debugPrint('Error adding group member: $e');
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

        // Remove from cache
        await _groupMembersTable.removeMember(
            selectedGroup!.id, contactAccount);

        // Update the group in the list with new member count
        final index =
            groups.indexWhere((group) => group.id == selectedGroup!.id);
        if (index != -1) {
          final updatedGroup =
              await _groupsService.getGroupById(selectedGroup!.id);
          if (updatedGroup != null) {
            groups[index] = updatedGroup;
            selectedGroup = updatedGroup;
            await _groupsTable.upsert(updatedGroup);
          }
        }
      }

      return success;
    } catch (e) {
      error = 'Failed to remove group member: $e';
      debugPrint('Error removing group member: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  void searchGroups(String query) {
    searchQuery = query;
    safeNotifyListeners();
  }

  /// Clear search
  void clearSearch() {
    searchQuery = '';
    safeNotifyListeners();
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

  Future<void> fetchUserGroups([String? userAddress]) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final actualUserAddress = userAddress ?? _userAccountAddress;
      if (actualUserAddress == null) {
        error = 'No account address found';
        return;
      }

      final dbGroups = await _groupsTable.getAll();
      if (dbGroups.isNotEmpty) {
        groups = dbGroups;
        safeNotifyListeners();
      }

      await _syncUserGroupsFromAPI(actualUserAddress);
    } catch (e) {
      error = 'Failed to fetch user groups: $e';
      debugPrint('Error fetching user groups: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Create a new group using the new API
  Future<Group?> createNewGroup({
    required String name,
    required String description,
    required String amount,
    int memberCount = 0,
  }) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final creatorAccountAddress = _userAccountAddress;
      if (creatorAccountAddress == null) {
        error = 'No account address found';
        return null;
      }

      final newGroup = await _groupsService.createNewGroup(
        name: name,
        description: description,
        amount: amount,
        userAddress: creatorAccountAddress,
        memberCount: memberCount,
      );

      // Store in database
      await _groupsTable.upsert(newGroup);

      // Update UI
      groups = await _groupsTable.getAll();
      safeNotifyListeners();

      return newGroup;
    } catch (e) {
      error = 'Failed to create group: $e';
      debugPrint('Error creating group: $e');
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Get group details using the new API
  Future<Group?> fetchGroupDetails(String groupId) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      // First, try to load from local database
      final cachedGroup = await _groupsTable.getById(groupId);
      if (cachedGroup != null) {
        debugPrint('Loaded group details from cache');
        isLoading = false;
        safeNotifyListeners();

        // Try to sync with API in background
        _syncGroupDetailsFromAPI(groupId);

        return cachedGroup;
      }

      // If not in cache, fetch from API
      final group = await _groupsService.getGroupDetails(groupId);
      if (group != null) {
        await _groupsTable.upsert(group);
      }
      return group;
    } catch (e) {
      error = 'Failed to fetch group details: $e';
      debugPrint('Error fetching group details: $e');

      // Try one more time from cache in case of network error
      final cachedGroup = await _groupsTable.getById(groupId);
      if (cachedGroup != null) {
        debugPrint('Returning cached group details after API error');
        return cachedGroup;
      }

      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Sync group details from API in background
  Future<void> _syncGroupDetailsFromAPI(String groupId) async {
    try {
      final group = await _groupsService.getGroupDetails(groupId);
      if (group != null) {
        await _groupsTable.upsert(group);

        // Update in memory if it's in the list
        final index = groups.indexWhere((g) => g.id == groupId);
        if (index != -1) {
          groups[index] = group;
        }

        // Update selected group if it's the one we just synced
        if (selectedGroup?.id == groupId) {
          selectedGroup = group;
        }

        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Background sync failed for group details $groupId: $e');
      // Fail silently - cached data is already being used
    }
  }

  /// Delete group using the new API
  Future<bool> deleteGroupById(String groupId) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final success = await _groupsService.deleteGroupById(groupId);

      if (success) {
        groups.removeWhere((group) => group.id == groupId);

        await _groupsTable.delete(groupId);

        // Clear selected group if it's the one being deleted
        if (selectedGroup?.id == groupId) {
          selectedGroup = null;
          currentGroupMembers = [];
        }
      }

      return success;
    } catch (e) {
      error = 'Failed to delete group: $e';
      debugPrint('Error deleting group: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  // Group Requests methods

  /// Fetch group requests
  Future<void> fetchGroupRequests() async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final accountAddress = _userAccountAddress;
      if (accountAddress == null) {
        error = 'No account address found';
        return;
      }

      groupRequests = await _groupsService.getGroupRequests(accountAddress);
    } catch (e) {
      error = 'Failed to fetch group requests: $e';
      debugPrint('Error fetching group requests: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Accept a group request
  Future<bool> acceptGroupRequest(String requestId) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final accountAddress = _userAccountAddress;
      if (accountAddress == null) {
        error = 'No account address found';
        return false;
      }

      final success =
          await _groupsService.acceptGroupRequest(requestId, accountAddress);

      if (success) {
        // Remove from local list
        groupRequests.removeWhere((req) => req.id == requestId);
      }

      return success;
    } catch (e) {
      error = 'Failed to accept group request: $e';
      debugPrint('Error accepting group request: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Decline a group request
  Future<bool> declineGroupRequest(String requestId) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final accountAddress = _userAccountAddress;
      if (accountAddress == null) {
        error = 'No account address found';
        return false;
      }

      final success =
          await _groupsService.declineGroupRequest(requestId, accountAddress);

      if (success) {
        // Remove from local list
        groupRequests.removeWhere((req) => req.id == requestId);
      }

      return success;
    } catch (e) {
      error = 'Failed to decline group request: $e';
      debugPrint('Error declining group request: $e');
      return false;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  void startPolling() {
    stopPolling();
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: pollingInterval),
      (_) => _pollGroups(),
    );
  }

  /// Stop polling
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Poll for group updates
  Future<void> _pollGroups() async {
    try {
      debugPrint('Polling groups for updates');
      await _syncGroupsFromAPI();

      // Also poll for group requests
      final accountAddress = _userAccountAddress;
      if (accountAddress != null) {
        groupRequests = await _groupsService.getGroupRequests(accountAddress);
        safeNotifyListeners();
      }
    } catch (e) {
      debugPrint('Error polling groups: $e');
    }
  }

  /// Sync groups from API and update database
  Future<void> _syncGroupsFromAPI() async {
    try {
      final userAddress = _userAccountAddress;
      if (userAddress == null) {
        debugPrint('Cannot sync groups: No user address available');
        return;
      }

      // Get groups from API for the current user
      final apiGroups = await _groupsService.getUserGroups(userAddress);

      final apiGroupIds = apiGroups.map((g) => g.id).toSet();

      final localGroups = await _groupsTable.getAll();

      for (final localGroup in localGroups) {
        if (!apiGroupIds.contains(localGroup.id)) {
          await _groupsTable.delete(localGroup.id);
          debugPrint(
              'Deleted group ${localGroup.id} from local DB (not in API response)');
        }
      }

      for (final group in apiGroups) {
        await _groupsTable.upsert(group);
      }

      groups = await _groupsTable.getAll();
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Error syncing groups from API: $e');
      // Don't throw - show cached data even if sync fails
    }
  }

  /// Sync user groups from API
  Future<void> _syncUserGroupsFromAPI(String userAddress) async {
    try {
      final apiGroups = await _groupsService.getUserGroups(userAddress);

      final apiGroupIds = apiGroups.map((g) => g.id).toSet();

      final localGroups = await _groupsTable.getAll();

      for (final localGroup in localGroups) {
        if (!apiGroupIds.contains(localGroup.id)) {
          await _groupsTable.delete(localGroup.id);
          debugPrint(
              'Deleted group ${localGroup.id} from local DB (not in API response)');
        }
      }

      for (final group in apiGroups) {
        await _groupsTable.upsert(group);
      }

      groups = await _groupsTable.getAll();
      safeNotifyListeners();
    } catch (e) {
      debugPrint('Error syncing user groups from API: $e');
    }
  }

  /// Refresh groups (force API sync)
  Future<void> refreshGroups() async {
    stopPolling();
    groups = [];
    safeNotifyListeners();
    await fetchGroups();
  }
}
