import 'package:pay_app/services/db/app/contacts.dart';
import 'package:pay_app/services/db/app/groups.dart';
import 'package:pay_app/services/db/app/group_members.dart';
import 'package:pay_app/services/db/app/transactions.dart';
import 'package:pay_app/services/db/app/user_operations.dart';
import 'package:pay_app/services/db/db.dart';
import 'package:sqflite/sqflite.dart';

class AppDBService extends DBService {
  static final AppDBService _instance = AppDBService._internal();

  factory AppDBService() {
    return _instance;
  }

  AppDBService._internal();

  late ContactsTable contacts;
  late GroupsTable groups;
  late GroupMembersTable groupMembers;
  late TransactionsTable transactions;
  late UserOperationsTable userOperations;

  @override
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        // Enable foreign key constraints for SQLite
        await db.execute('PRAGMA foreign_keys = ON');

        contacts = ContactsTable(db);
        groups = GroupsTable(db);
        groupMembers = GroupMembersTable(db);
        transactions = TransactionsTable(db);
        userOperations = UserOperationsTable(db);
      },
      onCreate: (db, version) async {
        await contacts.create(db);
        await groups.create(db);
        await groupMembers.create(db);
        await transactions.create(db);
        await userOperations.create(db);
        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await contacts.migrate(db, oldVersion, newVersion);
        await groups.migrate(db, oldVersion, newVersion);
        await groupMembers.migrate(db, oldVersion, newVersion);
        await transactions.migrate(db, oldVersion, newVersion);
        await userOperations.migrate(db, oldVersion, newVersion);
        return;
      },
      version: 3,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }
}
