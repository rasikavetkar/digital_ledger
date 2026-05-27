import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/party.dart';
import '../models/vehicle.dart';
import '../models/transaction.dart' as model_transaction;

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'digital_ledger.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create Party table
    await db.execute('''
      CREATE TABLE parties(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create Vehicle table with foreign key constraint
    await db.execute('''
      CREATE TABLE vehicles(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT NOT NULL UNIQUE,
        partyId INTEGER NOT NULL,
        type TEXT NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (partyId) REFERENCES parties (id) ON DELETE CASCADE
      )
    ''');

    // Create Transaction table with foreign key constraint
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        vehicleId INTEGER NOT NULL,
        date TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        remarks TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (vehicleId) REFERENCES vehicles (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better query performance
    await db.execute('CREATE INDEX idx_vehicle_party ON vehicles(partyId)');
    await db.execute('CREATE INDEX idx_transaction_vehicle ON transactions(vehicleId)');
    await db.execute('CREATE INDEX idx_transaction_date ON transactions(date)');
  }

  // ==================== PARTY CRUD ====================

  Future<int> insertParty(Party party) async {
    final db = await database;
    return db.insert('parties', {
      'name': party.name,
      'phone': party.phone,
      'createdAt': party.createdAt.toIso8601String(),
    });
  }

  Future<List<Party>> getParties() async {
    final db = await database;
    final maps = await db.query('parties', orderBy: 'name ASC');
    return maps.map((map) => Party.fromJson({...map, 'id': map['id']})).toList();
  }

  Future<Party?> getPartyById(int id) async {
    final db = await database;
    final maps = await db.query('parties', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Party.fromJson({...maps[0], 'id': maps[0]['id']});
  }

  Future<int> updateParty(Party party) async {
    final db = await database;
    return db.update(
      'parties',
      {
        'name': party.name,
        'phone': party.phone,
        'createdAt': party.createdAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [party.id],
    );
  }

  Future<int> deleteParty(int id) async {
    final db = await database;
    // Cascade delete will handle vehicles and transactions
    return db.delete('parties', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== VEHICLE CRUD ====================

  Future<int> insertVehicle(Vehicle vehicle) async {
    final db = await database;
    return db.insert('vehicles', {
      'number': vehicle.number.toUpperCase(),
      'partyId': vehicle.partyId,
      'type': vehicle.type,
      'createdAt': vehicle.createdAt.toIso8601String(),
    });
  }

  Future<List<Vehicle>> getVehiclesByParty(int partyId) async {
    final db = await database;
    final maps = await db.query(
      'vehicles',
      where: 'partyId = ?',
      whereArgs: [partyId],
      orderBy: 'number ASC',
    );
    return maps.map((map) => Vehicle.fromJson({...map, 'id': map['id']})).toList();
  }

  Future<List<Vehicle>> getAllVehicles() async {
    final db = await database;
    final maps = await db.query('vehicles', orderBy: 'number ASC');
    return maps.map((map) => Vehicle.fromJson({...map, 'id': map['id']})).toList();
  }

  Future<Vehicle?> getVehicleById(int id) async {
    final db = await database;
    final maps = await db.query('vehicles', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Vehicle.fromJson({...maps[0], 'id': maps[0]['id']});
  }

  Future<int> updateVehicle(Vehicle vehicle) async {
    final db = await database;
    return db.update(
      'vehicles',
      {
        'number': vehicle.number.toUpperCase(),
        'type': vehicle.type,
      },
      where: 'id = ?',
      whereArgs: [vehicle.id],
    );
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    // Cascade delete will handle transactions
    return db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== TRANSACTION CRUD ====================

  Future<int> insertTransaction(model_transaction.Transaction transaction) async {
    final db = await database;
    return db.insert('transactions', {
      'vehicleId': transaction.vehicleId,
      'date': transaction.date.toIso8601String(),
      'quantity': transaction.quantity,
      'amount': transaction.amount,
      'type': transaction.type,
      'remarks': transaction.remarks,
      'createdAt': transaction.createdAt.toIso8601String(),
    });
  }

  Future<List<model_transaction.Transaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map((map) => model_transaction.Transaction.fromJson({...map, 'id': map['id']})).toList();
  }

  Future<List<model_transaction.Transaction>> getTransactionsByVehicle(int vehicleId) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: 'vehicleId = ?',
      whereArgs: [vehicleId],
      orderBy: 'date DESC',
    );
    return maps.map((map) => model_transaction.Transaction.fromJson({...map, 'id': map['id']})).toList();
  }

  Future<List<model_transaction.Transaction>> getTransactionsByParty(int partyId) async {
    final db = await database;
    final maps = await db.rawQuery('''
      SELECT t.* FROM transactions t
      JOIN vehicles v ON t.vehicleId = v.id
      WHERE v.partyId = ?
      ORDER BY t.date DESC
    ''', [partyId]);
    return maps.map((map) => model_transaction.Transaction.fromJson({...map, 'id': map['id']})).toList();
  }

  Future<model_transaction.Transaction?> getTransactionById(int id) async {
    final db = await database;
    final maps = await db.query('transactions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return model_transaction.Transaction.fromJson({...maps[0], 'id': maps[0]['id']});
  }

  Future<int> updateTransaction(model_transaction.Transaction transaction) async {
    final db = await database;
    return db.update(
      'transactions',
      {
        'vehicleId': transaction.vehicleId,
        'date': transaction.date.toIso8601String(),
        'quantity': transaction.quantity,
        'amount': transaction.amount,
        'type': transaction.type,
        'remarks': transaction.remarks,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // ==================== AGGREGATE QUERIES ====================

  Future<double> getCreditTotalByParty(int partyId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions
      WHERE type = 'credit' AND vehicleId IN (
        SELECT id FROM vehicles WHERE partyId = ?
      )
    ''', [partyId]);
    return (result.isNotEmpty && result[0]['total'] != null) 
        ? (result[0]['total'] as num).toDouble() 
        : 0.0;
  }

  Future<double> getDebitTotalByParty(int partyId) async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT SUM(amount) as total FROM transactions
      WHERE type = 'debit' AND vehicleId IN (
        SELECT id FROM vehicles WHERE partyId = ?
      )
    ''', [partyId]);
    return (result.isNotEmpty && result[0]['total'] != null)
        ? (result[0]['total'] as num).toDouble()
        : 0.0;
  }

  Future<double> getTotalLoads() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(quantity) as total FROM transactions'
    );
    return (result.isNotEmpty && result[0]['total'] != null)
        ? (result[0]['total'] as num).toDouble()
        : 0.0;
  }

  Future<double> getTotalCredit() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "credit"'
    );
    return (result.isNotEmpty && result[0]['total'] != null)
        ? (result[0]['total'] as num).toDouble()
        : 0.0;
  }

  Future<double> getTotalDebit() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE type = "debit"'
    );
    return (result.isNotEmpty && result[0]['total'] != null)
        ? (result[0]['total'] as num).toDouble()
        : 0.0;
  }

  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('transactions');
    await db.delete('vehicles');
    await db.delete('parties');
  }

  Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
