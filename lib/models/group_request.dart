class GroupRequest {
  final String id;
  final String groupId;
  final String groupName;
  final String? groupDescription;
  final DateTime requestedAt;

  GroupRequest({
    required this.id,
    required this.groupId,
    required this.groupName,
    this.groupDescription,
    required this.requestedAt,
  });

  factory GroupRequest.create({
    required String id,
    required String groupId,
    required String groupName,
    String? groupDescription,
  }) {
    return GroupRequest(
      id: id,
      groupId: groupId,
      groupName: groupName,
      groupDescription: groupDescription,
      requestedAt: DateTime.now(),
    );
  }

  factory GroupRequest.fromMap(Map<String, dynamic> map) {
    // Handle the actual API response structure
    final group = map['group'] as Map<String, dynamic>?;

    return GroupRequest(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      groupName: group?['name'] as String? ?? 'Unknown Group',
      groupDescription: group?['description'] as String?,
      requestedAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'group_id': groupId,
      'group_name': groupName,
      'group_description': groupDescription,
      'requested_at': requestedAt.toIso8601String(),
    };
  }

  // JSON serialization methods for API integration
  Map<String, dynamic> toJson() => toMap();

  factory GroupRequest.fromJson(Map<String, dynamic> json) =>
      GroupRequest.fromMap(json);

  // Helper method to create list from JSON array
  static List<GroupRequest> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => GroupRequest.fromJson(json)).toList();
  }

  GroupRequest copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? groupDescription,
    DateTime? requestedAt,
  }) {
    return GroupRequest(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      groupDescription: groupDescription ?? this.groupDescription,
      requestedAt: requestedAt ?? this.requestedAt,
    );
  }

  @override
  String toString() {
    return 'GroupRequest(id: $id, groupId: $groupId, groupName: $groupName, requestedAt: $requestedAt)';
  }
}
