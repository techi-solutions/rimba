import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_app/models/group.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/models/group_request.dart';
import 'package:pay_app/services/api/api.dart';

class GroupsService {
  final APIService _apiService;

  // Hardcoded test user ID for testing
  static const String _testUserId = 'cmgkykqro0007i2s5ud0tmpqx';

  GroupsService({
    String? baseUrl,
  }) : _apiService = APIService(
          baseURL: baseUrl ?? dotenv.env['RIMBA_API_BASE_URL'] ?? '',
        );

  Future<List<Group>> getGroups() async {
    try {
      final response = await _apiService.get(url: '/groups');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> groupsApiResponse = data['data'] as List;
        return groupsApiResponse.map((group) => Group.fromMap(group)).toList();
      }

      return [];
    } catch (e, s) {
      debugPrint('Failed to fetch groups: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Get groups for a specific user
  Future<List<Group>> getUserGroups(String userId) async {
    try {
      final response = await _apiService.get(url: '/groups?userId=$userId');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> groupsApiResponse = data['data'] as List;
        return groupsApiResponse.map((group) => Group.fromMap(group)).toList();
      }

      return [];
    } catch (e, s) {
      debugPrint('Failed to fetch user groups: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  Future<Group> createNewGroup({
    required String name,
    String? description,
    required String amount,
    int memberCount = 0,
  }) async {
    try {
      final response = await _apiService.post(
        url: '/groups',
        body: {
          'name': name,
          'description': description,
          'amount': amount,
          'member_count': memberCount,
        },
      );

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        return Group.fromMap(data['data']);
      }

      throw Exception('Failed to create group');
    } catch (e, s) {
      debugPrint('Failed to create group: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Get group details by ID
  Future<Group?> getGroupDetails(String groupId) async {
    try {
      final response = await _apiService.get(url: '/groups/$groupId');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        return Group.fromMap(data['data']);
      }

      return null;
    } catch (e, s) {
      debugPrint('Failed to fetch group details: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Delete a group by ID
  Future<bool> deleteGroupById(String groupId) async {
    try {
      await _apiService.delete(
        url: '/groups/$groupId',
        body: {},
      );
      return true;
    } catch (e, s) {
      debugPrint('Failed to delete group: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  // Group Request methods

  /// Fetch all group requests for the current user
  Future<List<GroupRequest>> getGroupRequests() async {
    try {
      final response =
          await _apiService.get(url: '/requests/user/$_testUserId/pending');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> requestsApiResponse = data['data'] as List;
        return requestsApiResponse
            .map((request) => GroupRequest.fromJson(request))
            .toList();
      }

      return [];
    } catch (e, s) {
      debugPrint('Failed to fetch group requests: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Accept a group request
  Future<bool> acceptGroupRequest(String requestId) async {
    try {
      await _apiService.put(
        url: '/requests/$requestId/status',
        body: {
          'status': 'accepted',
          'userId': _testUserId,
        },
      );

      return true;
    } catch (e, s) {
      debugPrint('Failed to accept group request: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Decline a group request
  Future<bool> declineGroupRequest(String requestId) async {
    try {
      await _apiService.put(
        url: '/requests/$requestId/status',
        body: {
          'status': 'rejected',
          'userId': _testUserId,
        },
      );

      return true;
    } catch (e, s) {
      debugPrint('Failed to decline group request: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Get group by ID (alias for getGroupDetails)
  Future<Group?> getGroupById(String groupId) async {
    return getGroupDetails(groupId);
  }

  /// Remove a member from a group
  Future<bool> removeGroupMember({
    required String groupId,
    required String contactAccount,
  }) async {
    try {
      await _apiService.delete(
        url: '/user-groups/$contactAccount/$groupId',
        body: {},
      );
      return true;
    } catch (e, s) {
      debugPrint('Failed to remove group member: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Search groups by name or description
  Future<List<Group>> searchGroups(String query) async {
    try {
      final response = await _apiService.get(url: '/groups?search=$query');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> groupsApiResponse = data['data'] as List;
        return groupsApiResponse.map((group) => Group.fromMap(group)).toList();
      }

      return [];
    } catch (e, s) {
      debugPrint('Failed to search groups: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Get group members for a specific group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await _apiService.get(url: '/groups/$groupId/users');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> membersData = data['data'] as List;
        return membersData
            .map((member) => GroupMember.fromMap(member))
            .toList();
      }

      return [];
    } catch (e, s) {
      debugPrint('Failed to fetch group members: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Add a member to a group
  Future<GroupMember?> addGroupMember({
    required String groupId,
    required String contactAccount,
    String? memberName,
    String contributionAmount = '0.00',
  }) async {
    try {
      final response = await _apiService.post(
        url: '/groups/$groupId/users',
        body: {
          'contactAccount': contactAccount,
          'memberName': memberName,
          'contributionAmount': contributionAmount,
        },
      );

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        return GroupMember.fromMap(data['data']);
      }

      return null;
    } catch (e, s) {
      debugPrint('Failed to add group member: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Update a group by ID
  Future<Group?> updateGroup({
    required String groupId,
    required String name,
    String? description,
    required String amount,
  }) async {
    try {
      final response = await _apiService.put(
        url: '/groups/$groupId',
        body: {
          'name': name,
          'description': description,
          'amount': amount,
        },
      );

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        return Group.fromMap(data['data']);
      }

      return null;
    } catch (e, s) {
      debugPrint('Failed to update group: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
}
