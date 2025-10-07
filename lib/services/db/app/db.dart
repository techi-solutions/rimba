import 'package:rimba/services/db/app/cards.dart';
import 'package:rimba/services/db/app/contacts.dart';
import 'package:rimba/services/db/app/interactions.dart';
import 'package:rimba/services/db/app/otps.dart';
import 'package:rimba/services/db/app/transactions.dart';
import 'package:rimba/services/db/db.dart';
import 'package:sqflite/sqflite.dart';

class AppDBService extends DBService {
  static final AppDBService _instance = AppDBService._internal();

  factory AppDBService() {
    return _instance;
  }

  AppDBService._internal();

  late ContactsTable contacts;
  late CardsTable cards;
  late InteractionsTable interactions;
  late TransactionsTable transactions;
  late OTPsTable otps;

  @override
  Future<Database> openDB(String path) async {
    final options = OpenDatabaseOptions(
      onConfigure: (db) async {
        contacts = ContactsTable(db);
        cards = CardsTable(db);
        interactions = InteractionsTable(db);
        transactions = TransactionsTable(db);
        otps = OTPsTable(db);
      },
      onCreate: (db, version) async {
        await contacts.create(db);
        await cards.create(db);
        await interactions.create(db);
        await transactions.create(db);
        await otps.create(db);
        return;
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await contacts.migrate(db, oldVersion, newVersion);
        await cards.migrate(db, oldVersion, newVersion);
        await interactions.migrate(db, oldVersion, newVersion);
        await transactions.migrate(db, oldVersion, newVersion);
        await otps.migrate(db, oldVersion, newVersion);
        return;
      },
      version: 1,
    );

    final db = await databaseFactory.openDatabase(
      path,
      options: options,
    );

    return db;
  }
}
