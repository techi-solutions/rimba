import 'dart:convert';

class UserOperation {
  final String id;
  final String paymaster;
  final String contactAccount;
  final String? groupId;
  final Map<String, dynamic> contents;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime createdAt;

  UserOperation({
    required this.id,
    required this.paymaster,
    required this.contactAccount,
    this.groupId,
    required this.contents,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
  });

  factory UserOperation.create({
    required String id,
    required String paymaster,
    required String contactAccount,
    String? groupId,
    required Map<String, dynamic> contents,
    required DateTime validFrom,
    required DateTime validUntil,
  }) {
    return UserOperation(
      id: id,
      paymaster: paymaster,
      contactAccount: contactAccount,
      groupId: groupId,
      contents: contents,
      validFrom: validFrom,
      validUntil: validUntil,
      createdAt: DateTime.now(),
    );
  }

  factory UserOperation.fromMap(Map<String, dynamic> map) {
    return UserOperation(
      id: map['id'],
      paymaster: map['paymaster'],
      contactAccount: map['contact_account'],
      groupId: map['group_id'],
      contents: jsonDecode(map['contents']),
      validFrom: DateTime.parse(map['valid_from']),
      validUntil: DateTime.parse(map['valid_until']),
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'paymaster': paymaster,
      'contact_account': contactAccount,
      'group_id': groupId,
      'contents': jsonEncode(contents),
      'valid_from': validFrom.toIso8601String(),
      'valid_until': validUntil.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  UserOperation copyWith({
    String? id,
    String? paymaster,
    String? contactAccount,
    String? groupId,
    Map<String, dynamic>? contents,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
  }) {
    return UserOperation(
      id: id ?? this.id,
      paymaster: paymaster ?? this.paymaster,
      contactAccount: contactAccount ?? this.contactAccount,
      groupId: groupId ?? this.groupId,
      contents: contents ?? this.contents,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(validFrom) && now.isBefore(validUntil);
  }

  bool get isExpired {
    return DateTime.now().isAfter(validUntil);
  }

  bool get isNotYetValid {
    return DateTime.now().isBefore(validFrom);
  }

  @override
  String toString() {
    return 'UserOperation(id: $id, paymaster: $paymaster, contactAccount: $contactAccount, groupId: $groupId, validFrom: $validFrom, validUntil: $validUntil, createdAt: $createdAt)';
  }
}
