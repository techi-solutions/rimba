import 'package:pay_app/models/user_operation.dart';
import 'package:pay_app/services/db/db.dart';
import 'package:sqflite/sqflite.dart';

class UserOperationsTable extends DBTable {
  UserOperationsTable(super.db);

  @override
  String get name => 't_user_operations';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      id TEXT PRIMARY KEY,
      paymaster TEXT NOT NULL,
      contact_account TEXT NOT NULL,
      group_id TEXT,
      contents TEXT NOT NULL,
      valid_from TEXT NOT NULL,
      valid_until TEXT NOT NULL,
      created_at TEXT NOT NULL,
      FOREIGN KEY (contact_account) REFERENCES t_contacts(account) ON DELETE CASCADE,
      FOREIGN KEY (group_id) REFERENCES t_groups(id) ON DELETE SET NULL
    )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    // Create indexes for faster lookups
    await db.execute('''
      CREATE INDEX idx_${name}_contact ON $name (contact_account)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_group ON $name (group_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_validity ON $name (valid_from, valid_until)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_paymaster ON $name (paymaster)
    ''');
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    // No migrations needed for version 1
  }

  // Fetch user operation by ID
  Future<UserOperation?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return UserOperation.fromMap(maps.first);
  }

  // Fetch all user operations for a contact
  Future<List<UserOperation>> getByContactAccount(String contactAccount) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'contact_account = ?',
      whereArgs: [contactAccount],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => UserOperation.fromMap(maps[i]));
  }

  // Fetch all user operations for a group
  Future<List<UserOperation>> getByGroupId(String groupId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => UserOperation.fromMap(maps[i]));
  }

  // Fetch all user operations for a paymaster
  Future<List<UserOperation>> getByPaymaster(String paymaster) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'paymaster = ?',
      whereArgs: [paymaster],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => UserOperation.fromMap(maps[i]));
  }

  // Fetch valid user operations (within validity period)
  Future<List<UserOperation>> getValid() async {
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'valid_from <= ? AND valid_until >= ?',
      whereArgs: [now, now],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => UserOperation.fromMap(maps[i]));
  }

  // Fetch expired user operations
  Future<List<UserOperation>> getExpired() async {
    final now = DateTime.now().toIso8601String();
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'valid_until < ?',
      whereArgs: [now],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => UserOperation.fromMap(maps[i]));
  }

  // Upsert user operation
  Future<void> upsert(UserOperation userOperation) async {
    await db.insert(
      name,
      userOperation.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Delete user operation
  Future<void> delete(String id) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Delete expired user operations
  Future<int> deleteExpired() async {
    final now = DateTime.now().toIso8601String();
    return await db.delete(
      name,
      where: 'valid_until < ?',
      whereArgs: [now],
    );
  }
}
