import 'dart:convert';
import 'package:pay_app/models/place.dart';
import 'package:pay_app/services/db/db.dart';
import 'package:pay_app/services/wallet/contracts/profile.dart';
import 'package:sqflite/sqflite.dart';

enum ContactType {
  place,
  user,
}

class DBContact {
  final String account;
  final String username;
  final String name;
  final ContactType type;
  final String? profile;
  final String? place;

  DBContact({
    required this.account,
    required this.username,
    required this.name,
    required this.type,
    this.profile,
    this.place,
  });

  factory DBContact.fromMap(Map<String, dynamic> map) {
    return DBContact(
      account: map['account'],
      username: map['username'],
      name: map['name'],
      type: ContactType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ContactType.user,
      ),
      profile: map['profile'],
      place: map['place'],
    );
  }

  factory DBContact.fromProfile(ProfileV1 profile) {
    return DBContact(
      account: profile.account,
      username: profile.username,
      name: profile.name,
      type: ContactType.user,
      profile: jsonEncode(profile.toJson()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'account': account,
      'username': username,
      'name': name,
      'type': type.name,
      'profile': profile,
      'place': place,
    };
  }

  ProfileV1? getProfile() {
    if (profile == null) return null;
    return ProfileV1.fromJson(jsonDecode(profile!));
  }

  Place? getPlace() {
    if (place == null) return null;
    return Place.fromJson(jsonDecode(place!));
  }
}

class ContactsTable extends DBTable {
  ContactsTable(super.db);

  @override
  String get name => 't_contacts';

  @override
  String get createQuery => '''
    CREATE TABLE $name (
      account TEXT PRIMARY KEY,
      username TEXT NOT NULL,
      name TEXT NOT NULL,
      type TEXT NOT NULL,
      profile TEXT,
      place TEXT
    )
  ''';

  @override
  Future<void> create(Database db) async {
    await db.execute(createQuery);

    // Create indexes for faster lookups
    await db.execute('''
      CREATE INDEX idx_${name}_account ON $name (account)
    ''');
    await db.execute('''
      CREATE INDEX idx_${name}_username ON $name (username)
    ''');
  }

  @override
  Future<void> migrate(Database db, int oldVersion, int newVersion) async {
    // No migrations needed for version 1
  }

  // Fetch all contacts
  Future<List<DBContact>> getAll() async {
    final List<Map<String, dynamic>> maps = await db.query(name);
    return List.generate(maps.length, (i) => DBContact.fromMap(maps[i]));
  }

  // Fetch contact by account
  Future<DBContact?> getByAccount(String account) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'account = ?',
      whereArgs: [account],
    );
    if (maps.isEmpty) return null;
    return DBContact.fromMap(maps.first);
  }

  // Fetch contact by username
  Future<DBContact?> getByUsername(String username) async {
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isEmpty) return null;
    return DBContact.fromMap(maps.first);
  }

  // Upsert contact by account
  Future<void> upsert(DBContact contact) async {
    await db.insert(
      name,
      contact.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Search contacts by username, name, or account address
  Future<List<DBContact>> search(String query) async {
    final searchQuery = query.toLowerCase();
    
    final List<Map<String, dynamic>> maps = await db.query(
      name,
      where: 'LOWER(username) LIKE ? OR LOWER(name) LIKE ? OR LOWER(account) LIKE ?',
      whereArgs: ['%$searchQuery%', '%$searchQuery%', '%$searchQuery%'],
    );

    return List.generate(maps.length, (i) => DBContact.fromMap(maps[i]));
  }
}
