import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/services/api/api.dart';

class GroupMembersService {
  final APIService apiService =
      APIService(baseURL: dotenv.env['RIMBA_API_BASE_URL'] ?? '');

  /// GET /api/v1/groups/{groupId}/users - Get members for group
  Future<List<GroupMember>> getGroupMembers(String groupId) async {
    try {
      final response = await apiService.get(url: '/groups/$groupId/users');

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

  /// DELETE /api/v1/user-groups/{userAddress}/{groupId} - Remove user from group
  Future<bool> removeUserFromGroup(String userAddress, String groupId) async {
    try {
      final response = await apiService.delete(
        url: '/user-groups/$userAddress/$groupId',
        body: {},
      );

      final Map<String, dynamic> data = response;
      return data['success'] == true;
    } catch (e, s) {
      debugPrint('Failed to remove user from group: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// PATCH /api/v1/groups/{groupId}/users - Update ready status for a member
  Future<bool> updateReadyStatus({
    required String groupId,
    required String userAddress,
    required bool isReady,
  }) async {
    try {
      final response = await apiService.patch(
        url: '/groups/$groupId/users',
        body: {
          'userAddress': userAddress,
          'isReady': isReady,
        },
      );

      final Map<String, dynamic> data = response;
      return data['success'] == true;
    } catch (e, s) {
      debugPrint('Failed to update ready status: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// PATCH /api/v1/groups/{groupId}/users - Update payout position for a member
  Future<bool> updatePayoutPosition({
    required String groupId,
    required String userAddress,
    required int payoutPosition,
  }) async {
    try {
      final response = await apiService.patch(
        url: '/groups/$groupId/users',
        body: {
          'userAddress': userAddress,
          'payout_position': payoutPosition,
        },
      );

      final Map<String, dynamic> data = response;
      return data['success'] == true;
    } catch (e, s) {
      debugPrint('Failed to update payout position: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
}
