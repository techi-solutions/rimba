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
}
