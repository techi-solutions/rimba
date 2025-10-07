import 'package:pay_app/models/group_member.dart';
import 'package:pay_app/services/db/db.dart';
import 'package:sqflite/sqflite.dart';

class GroupMembersTable extends DBTable {
  GroupMembersTable(super.db);

  @override
  String get name => 't_group_members';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      group_id TEXT NOT NULL,
      contact_account TEXT NOT NULL,
      created_at TEXT NOT NULL,
      PRIMARY KEY (group_id, contact_account),
      FOREIGN KEY (group_id) REFERENCES t_groups(id) ON DELETE CASCADE,
      FOREIGN KEY (contact_account) REFERENCES t_contacts(account) ON DELETE CASCADE
    )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    // Create indexes for faster lookups
    await db.execute('''
      CREATE INDEX idx_${name}_group_id ON $name (group_id)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_contact ON $name (contact_account)
    ''');
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    // No migrations needed for version 1
  }

  // Fetch all members of a group
  Future<List<GroupMember>> getByGroupId(String groupId) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'group_id = ?',
      whereArgs: [groupId],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => GroupMember.fromMap(maps[i]));
  }

  // Fetch all groups for a contact
  Future<List<GroupMember>> getByContactAccount(String contactAccount) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'contact_account = ?',
      whereArgs: [contactAccount],
      orderBy: 'created_at ASC',
    );
    return List.generate(maps.length, (i) => GroupMember.fromMap(maps[i]));
  }

  // Check if a contact is a member of a group
  Future<bool> isMember(String groupId, String contactAccount) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'group_id = ? AND contact_account = ?',
      whereArgs: [groupId, contactAccount],
    );
    return maps.isNotEmpty;
  }

  // Add member to group
  Future<void> addMember(GroupMember member) async {
    await db.insert(
      name,
      member.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Remove member from group
  Future<void> removeMember(String groupId, String contactAccount) async {
    await db.delete(
      name,
      where: 'group_id = ? AND contact_account = ?',
      whereArgs: [groupId, contactAccount],
    );
  }

  // Remove all members from a group
  Future<void> removeAllMembers(String groupId) async {
    await db.delete(
      name,
      where: 'group_id = ?',
      whereArgs: [groupId],
    );
  }

  // Get member count for a group
  Future<int> getMemberCount(String groupId) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $name WHERE group_id = ?',
      [groupId],
    );
    return result.first['count'] as int;
  }
}
