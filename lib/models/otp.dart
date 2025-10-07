class OTP {
  final int? id;
  final String source;
  final String sourceType;
  final String code;
  final DateTime createdAt;
  final DateTime expiresAt;

  const OTP({
    this.id,
    required this.source,
    required this.sourceType,
    required this.code,
    required this.createdAt,
    required this.expiresAt,
  });

  factory OTP.fromMap(Map<String, dynamic> map) {
    return OTP(
      id: map['id'] as int?,
      source: map['source'] as String,
      sourceType: map['source_type'] as String,
      code: map['code'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      expiresAt: DateTime.parse(map['expires_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'source': source,
      'source_type': sourceType,
      'code': code,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
    };
  }

  OTP copyWith({
    int? id,
    String? source,
    String? sourceType,
    String? code,
    DateTime? createdAt,
    DateTime? expiresAt,
  }) {
    return OTP(
      id: id ?? this.id,
      source: source ?? this.source,
      sourceType: sourceType ?? this.sourceType,
      code: code ?? this.code,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  @override
  String toString() {
    return 'OTP(id: $id, source: $source, sourceType: $sourceType, code: $code, createdAt: $createdAt, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is OTP &&
        other.id == id &&
        other.source == source &&
        other.sourceType == sourceType &&
        other.code == code &&
        other.createdAt == createdAt &&
        other.expiresAt == expiresAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        source.hashCode ^
        sourceType.hashCode ^
        code.hashCode ^
        createdAt.hashCode ^
        expiresAt.hashCode;
  }
}
