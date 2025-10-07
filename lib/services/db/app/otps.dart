import 'package:flutter/cupertino.dart';
import 'package:rimba/models/otp.dart';
import 'package:rimba/services/db/db.dart';
import 'package:sqflite/sqflite.dart';

class OTPsTable extends DBTable {
  OTPsTable(super.db);

  @override
  String get name => 't_otps';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      source TEXT NOT NULL,
      source_type TEXT NOT NULL,
      code TEXT NOT NULL,
      created_at TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      UNIQUE(source)
    )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    // Create indexes for faster lookups
    await db.execute('''
      CREATE INDEX idx_${name}_source ON $name (source)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_source_type ON $name (source_type)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_expires_at ON $name (expires_at)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_created_at ON $name (created_at)
    ''');
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 0 && newVersion >= 1) {
      await create(db);
    }
  }

  /// Save or update OTP for a source (email/phone)
  Future<void> saveOTP({
    required String source,
    required String sourceType,
    required String code,
    required DateTime createdAt,
    required DateTime expiresAt,
  }) async {
    await db.insert(
      name,
      {
        'source': source,
        'source_type': sourceType,
        'code': code,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get OTP for a source
  Future<OTP?> getOTP(String source) async {
    final result = await db.query(
      name,
      where: 'source = ?',
      whereArgs: [source],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return OTP.fromMap(result.first);
  }

  /// Verify OTP for a source
  Future<bool> verifyOTP(String source, String code) async {
    final otp = await getOTP(source);

    if (otp == null) {
      debugPrint('No OTP found for source: $source');
      return false;
    }

    final now = DateTime.now();
    if (now.isAfter(otp.expiresAt)) {
      debugPrint('OTP expired for source: $source');
      await deleteOTP(source);
      return false;
    }

    final isValid = otp.code == code;

    if (isValid) {
      debugPrint('OTP verified successfully for source: $source');
    } else {
      debugPrint('Invalid OTP for source: $source');
    }

    return isValid;
  }

  /// Delete OTP for a source
  Future<void> deleteOTP(String source) async {
    await db.delete(
      name,
      where: 'source = ?',
      whereArgs: [source],
    );
  }

  /// Clean up expired OTPs
  Future<void> cleanupExpiredOTPs() async {
    final now = DateTime.now().toIso8601String();
    await db.delete(
      name,
      where: 'expires_at < ?',
      whereArgs: [now],
    );
    debugPrint('Cleaned up expired OTPs');
  }

  /// Get all OTPs (for debugging)
  Future<List<OTP>> getAllOTPs() async {
    final result = await db.query(name);
    return result.map((map) => OTP.fromMap(map)).toList();
  }
}
