class Group {
  final String id;
  final String name;
  final String? description;
  final String amount;
  final int memberCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  Group({
    required this.id,
    required this.name,
    this.description,
    required this.amount,
    required this.memberCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Group.create({
    required String id,
    required String name,
    String? description,
    required String amount,
    required int memberCount,
  }) {
    final now = DateTime.now();
    return Group(
      id: id,
      name: name,
      description: description,
      amount: amount,
      memberCount: memberCount,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      amount: map['amount'],
      memberCount: map['member_count'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'amount': amount,
      'member_count': memberCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Group copyWith({
    String? id,
    String? name,
    String? description,
    String? amount,
    int? memberCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Group(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      memberCount: memberCount ?? this.memberCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Group(id: $id, name: $name, description: $description, amount: $amount, memberCount: $memberCount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}
