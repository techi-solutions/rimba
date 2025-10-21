import 'package:pay_app/models/group.dart';
import 'package:pay_app/services/db/db.dart';
import 'package:sqflite/sqflite.dart';

class GroupsTable extends DBTable {
  GroupsTable(super.db);

  @override
  String get name => 't_groups';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT,
      amount TEXT NOT NULL,
      member_count INTEGER NOT NULL,
      created_by TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    // Create indexes for faster lookups
    await db.execute('''
      CREATE INDEX idx_${name}_updated_at ON $name (updated_at DESC)
    ''');
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2 && newVersion >= 2) {
      await db.execute('ALTER TABLE $name ADD COLUMN created_by TEXT');
    }
  }

  // Fetch all groups ordered by latest updated_at
  Future<List<Group>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      orderBy: 'updated_at DESC',
    );
    return List.generate(maps.length, (i) => Group.fromMap(maps[i]));
  }

  // Fetch group by ID
  Future<Group?> getById(String id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return Group.fromMap(maps.first);
  }

  // Upsert group
  Future<void> upsert(Group group) async {
    await db.insert(
      name,
      group.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Update group
  Future<void> update(Group group) async {
    await db.update(
      name,
      group.toMap(),
      where: 'id = ?',
      whereArgs: [group.id],
    );
  }

  // Delete group
  Future<void> delete(String id) async {
    await db.delete(
      name,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Update group's updated_at timestamp
  Future<void> touch(String id) async {
    await db.update(
      name,
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
