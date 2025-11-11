import 'package:flutter/cupertino.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pay_app/models/payment.dart';
import 'package:pay_app/services/api/api.dart';

class PaymentsService {
  final APIService _apiService;

  PaymentsService({String? baseUrl})
      : _apiService = APIService(
          baseURL: baseUrl ?? dotenv.env['RIMBA_API_BASE_URL'] ?? '',
        );

  /// POST /payments
  Future<PaymentResponse> createPayments({
    required String groupId,
    required String userId,
    required List<PaymentUserOp> userOps,
  }) async {
    try {
      final request = PaymentRequest(
        groupId: groupId,
        userId: userId,
        userOps: userOps,
      );

      final response = await _apiService.post(
        url: '/payments',
        body: request.toJson(),
      );

      return PaymentResponse.fromJson(response);
    } catch (e, s) {
      debugPrint('Failed to create payments: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }

  /// Creates payments with custom headers (e.g., for authentication)
  Future<PaymentResponse> createPaymentsWithHeaders({
    required String groupId,
    required String userId,
    required List<PaymentUserOp> userOps,
    required Map<String, String> headers,
  }) async {
    try {
      final request = PaymentRequest(
        groupId: groupId,
        userId: userId,
        userOps: userOps,
      );

      final response = await _apiService.post(
        url: '/payments',
        body: request.toJson(),
        headers: headers,
      );

      return PaymentResponse.fromJson(response);
    } catch (e, s) {
      debugPrint('Failed to create payments: $e');
      debugPrint('Stack trace: $s');
      rethrow;
    }
  }
}

