class GroupMember {
  final String groupId;
  final String contactAccount;
  final DateTime createdAt;

  GroupMember({
    required this.groupId,
    required this.contactAccount,
    required this.createdAt,
  });

  factory GroupMember.create({
    required String groupId,
    required String contactAccount,
  }) {
    return GroupMember(
      groupId: groupId,
      contactAccount: contactAccount,
      createdAt: DateTime.now(),
    );
  }

  factory GroupMember.fromMap(Map<String, dynamic> map) {
    return GroupMember(
      groupId: map['group_id'],
      contactAccount: map['contact_account'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'group_id': groupId,
      'contact_account': contactAccount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  GroupMember copyWith({
    String? groupId,
    String? contactAccount,
    DateTime? createdAt,
  }) {
    return GroupMember(
      groupId: groupId ?? this.groupId,
      contactAccount: contactAccount ?? this.contactAccount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'GroupMember(groupId: $groupId, contactAccount: $contactAccount, createdAt: $createdAt)';
  }
}
