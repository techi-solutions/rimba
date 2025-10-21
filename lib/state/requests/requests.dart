import 'package:flutter/cupertino.dart';
import 'package:pay_app/services/request/requests.dart';

class RequestsState extends ChangeNotifier {
  // Services
  late RequestsService _requestsService;

  // State variables
  List<Map<String, dynamic>> pendingRequests = [];
  bool isLoading = false;
  String? error;

  // Private variables
  bool _mounted = true;

  // Constructor
  RequestsState() {
    _requestsService = RequestsService();
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

  /// Create a new request
  Future<Map<String, dynamic>?> createRequest({
    required String userAddress,
    required String groupId,
    bool isActive = true,
  }) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final request = await _requestsService.createRequest(
        userAddress: userAddress,
        groupId: groupId,
        isActive: isActive,
      );

      return request;
    } catch (e) {
      error = 'Failed to create request: $e';
      print('Error creating request: $e');
      return null;
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Get pending requests for a user
  Future<void> fetchPendingRequests(String userAddress) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      pendingRequests = await _requestsService.getPendingRequests(userAddress);
    } catch (e) {
      error = 'Failed to fetch pending requests: $e';
      print('Error fetching pending requests: $e');
    } finally {
      isLoading = false;
      safeNotifyListeners();
    }
  }

  /// Update request status (accept/decline)
  Future<bool> updateRequestStatus({
    required String requestId,
    required String status, // "accepted" or "rejected"
  }) async {
    try {
      isLoading = true;
      error = null;
      safeNotifyListeners();

      final success = await _requestsService.updateRequestStatus(
        requestId: requestId,
        status: status,
      );

      if (success) {
        // Remove from local list
        pendingRequests.removeWhere((request) => request['id'] == requestId);
      }

      return success;
    } catch (e) {
      error = 'Failed to update request status: $e';
      print('Error updating request status: $e');
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

  /// Clear pending requests
  void clearPendingRequests() {
    pendingRequests = [];
    safeNotifyListeners();
  }
}
