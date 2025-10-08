class GroupMember {
  final String groupId;
  final String contactAccount;
  final String? memberName;
  final String contributionAmount;
  final DateTime createdAt;

  GroupMember({
    required this.groupId,
    required this.contactAccount,
    this.memberName,
    required this.contributionAmount,
    required this.createdAt,
  });

  factory GroupMember.create({
    required String groupId,
    required String contactAccount,
    String? memberName,
    String contributionAmount = '0.00',
  }) {
    return GroupMember(
      groupId: groupId,
      contactAccount: contactAccount,
      memberName: memberName,
      contributionAmount: contributionAmount,
      createdAt: DateTime.now(),
    );
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      groupId: map['group_id'],
      contactAccount: map['contact_account'],
      memberName: map['member_name'],
      contributionAmount: map['contribution_amount'] ?? '0.00',
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'contact_account': contactAccount,
      'member_name': memberName,
      'contribution_amount': contributionAmount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupMember copyWith({
    String? groupId,
    String? contactAccount,
    String? memberName,
    String? contributionAmount,
    DateTime? createdAt,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      contactAccount: contactAccount ?? this.contactAccount,
      memberName: memberName ?? this.memberName,
      contributionAmount: contributionAmount ?? this.contributionAmount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupMember(groupId: $groupId, contactAccount: $contactAccount, memberName: $memberName, contributionAmount: $contributionAmount, createdAt: $createdAt)';
  }
}
