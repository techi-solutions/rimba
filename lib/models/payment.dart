class PaymentUserOp {
  final dynamic userOp;
  final String startDate;
  final String endDate;
  final int executionMonth;
  final String? status;

  PaymentUserOp({
    required this.userOp,
    required this.startDate,
    required this.endDate,
    required this.executionMonth,
    this.status,
  });

  Map<String, dynamic> toJson() {
    return {
      'userOp': userOp,
      'startDate': startDate,
      'endDate': endDate,
      'executionMonth': executionMonth,
      if (status != null) 'status': status,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory PaymentUserOp.fromJson(Map<String, dynamic> json) {
    return PaymentUserOp(
      userOp: json['userOp'],
      startDate: json['startDate'] as String,
      endDate: json['endDate'] as String,
      executionMonth: json['executionMonth'] as int,
      status: json['status'] as String?,
    );
  }

  factory PaymentUserOp.fromMap(Map<String, dynamic> map) =>
      PaymentUserOp.fromJson(map);

  PaymentUserOp copyWith({
    dynamic userOp,
    String? startDate,
    String? endDate,
    int? executionMonth,
    String? status,
  }) {
    return PaymentUserOp(
      userOp: userOp ?? this.userOp,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      executionMonth: executionMonth ?? this.executionMonth,
      status: status ?? this.status,
    );
  }

  @override
  String toString() {
    return 'PaymentUserOp(startDate: $startDate, endDate: $endDate, executionMonth: $executionMonth, status: $status)';
  }
}

class PaymentRequest {
  final String groupId;
  final String userId;
  final List<PaymentUserOp> userOps;

  PaymentRequest({
    required this.groupId,
    required this.userId,
    required this.userOps,
  });

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'userId': userId,
      'userOps': userOps.map((op) => op.toJson()).toList(),
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory PaymentRequest.fromJson(Map<String, dynamic> json) {
    return PaymentRequest(
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
      userOps: (json['userOps'] as List)
          .map((op) => PaymentUserOp.fromJson(op as Map<String, dynamic>))
          .toList(),
    );
  }

  factory PaymentRequest.fromMap(Map<String, dynamic> map) =>
      PaymentRequest.fromJson(map);

  @override
  String toString() {
    return 'PaymentRequest(groupId: $groupId, userId: $userId, userOps: ${userOps.length} ops)';
  }
}

class PaymentData {
  final int count;
  final String groupId;
  final String userId;

  PaymentData({
    required this.count,
    required this.groupId,
    required this.userId,
  });

  factory PaymentData.fromJson(Map<String, dynamic> json) {
    return PaymentData(
      count: json['count'] as int,
      groupId: json['groupId'] as String,
      userId: json['userId'] as String,
    );
  }

  factory PaymentData.fromMap(Map<String, dynamic> map) =>
      PaymentData.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'count': count,
      'groupId': groupId,
      'userId': userId,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  @override
  String toString() {
    return 'PaymentData(count: $count, groupId: $groupId, userId: $userId)';
  }
}

class PaymentResponse {
  final bool success;
  final PaymentData? data;
  final String? message;
  final String? error;

  PaymentResponse({
    required this.success,
    this.data,
    this.message,
    this.error,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) {
    return PaymentResponse(
      success: json['success'] as bool,
      data: json['data'] != null
          ? PaymentData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      message: json['message'] as String?,
      error: json['error'] as String?,
    );
  }

  factory PaymentResponse.fromMap(Map<String, dynamic> map) =>
      PaymentResponse.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      if (data != null) 'data': data!.toJson(),
      if (message != null) 'message': message,
      if (error != null) 'error': error,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  @override
  String toString() {
    return 'PaymentResponse(success: $success, data: $data, message: $message, error: $error)';
  }
}
