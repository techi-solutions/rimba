class GroupMember {
  final String groupId;
  final String contactAccount;
  final String? memberName;
  final String contributionAmount;
  final int payoutPosition;
  final bool isReady;
  final DateTime createdAt;

  GroupMember({
    required this.groupId,
    required this.contactAccount,
    this.memberName,
    required this.contributionAmount,
    required this.payoutPosition,
    this.isReady = false,
    required this.createdAt,
  });

  factory GroupMember.create({
    required String groupId,
    required String contactAccount,
    String? memberName,
    String contributionAmount = '0.00',
    int payoutPosition = 0,
    bool isReady = false,
  }) {
    return GroupMember(
      groupId: groupId,
      contactAccount: contactAccount,
      memberName: memberName,
      contributionAmount: contributionAmount,
      payoutPosition: payoutPosition,
      isReady: isReady,
      createdAt: DateTime.now(),
    );
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    final user = map['user'] as Map<String, dynamic>?;

    final isReadyValue = map['is_ready'] ?? map['isReady'] ?? false;
    final isReady = isReadyValue is bool ? isReadyValue : (isReadyValue == 1);

    return GroupMember(
      groupId: (map['group_id'] ?? map['groupId']) as String,
      contactAccount: map['userAddress'] as String,
      memberName: user?['name'] as String?,
      contributionAmount:
          (map['contribution_amount'] ?? map['contributionAmount']) ?? '0.00',
      payoutPosition:
          (map['payout_position'] ?? map['payoutPosition'] ?? 0) as int,
      isReady: isReady,
      createdAt:
          DateTime.parse((map['created_at'] ?? map['createdAt']) as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'contact_account': contactAccount,
      'member_name': memberName,
      'contribution_amount': contributionAmount,
      'payout_position': payoutPosition,
      'is_ready': isReady ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupMember copyWith({
    String? groupId,
    String? contactAccount,
    String? memberName,
    String? contributionAmount,
    int? payoutPosition,
    bool? isReady,
    DateTime? createdAt,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      contactAccount: contactAccount ?? this.contactAccount,
      memberName: memberName ?? this.memberName,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      payoutPosition: payoutPosition ?? this.payoutPosition,
      isReady: isReady ?? this.isReady,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupMember(groupId: $groupId, contactAccount: $contactAccount, memberName: $memberName, contributionAmount: $contributionAmount, payoutPosition: $payoutPosition, isReady: $isReady, createdAt: $createdAt)';
  }
}
