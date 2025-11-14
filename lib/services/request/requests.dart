import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_app/services/api/api.dart';

class RequestsService {
  final APIService apiService =
      APIService(baseURL: dotenv.env['RIMBA_API_BASE_URL'] ?? '');

  /// POST /api/v1/requests - Create Request
  Future<Map<String, dynamic>> createRequest({
    required String userAddress,
    required String groupId,
    bool isActive = true,
  }) async {
    try {
      final body = {
        'userAddress': userAddress,
        'groupId': groupId,
        'is_Active': isActive,
      };

      final response = await apiService.post(
        url: '/requests',
        body: body,
      );

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        return data['data'];
      }

      throw Exception(
          'Failed to create request: ${data['error'] ?? 'Unknown error'}');
    } catch (e, s) {
      debugPrint('Failed to create request: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// GET /api/v1/requests/user/{userAddress}/pending - Get pending requests for user
  Future<List<Map<String, dynamic>>> getPendingRequests(String userAddress) async {
    try {
      final response =
          await apiService.get(url: '/requests/user/$userAddress/pending');

      final Map<String, dynamic> data = response;
      if (data['success'] == true && data['data'] != null) {
        final List<dynamic> requestsData = data['data'] as List;
        return requestsData.cast<Map<String, dynamic>>();
      }

      return [];
    } catch (e, s) {
      debugPrint('Failed to fetch pending requests: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// PUT /api/v1/requests/{requestId}/status - Update request status (accept/decline)
  Future<bool> updateRequestStatus({
    required String requestId,
    required String status, // "accepted" or "rejected"
  }) async {
    try {
      final body = {
        'status': status,
      };

      final response = await apiService.put(
        url: '/requests/$requestId/status',
        body: body,
      );

      final Map<String, dynamic> data = response;
      return data['success'] == true;
    } catch (e, s) {
      debugPrint('Failed to update request status: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
}
