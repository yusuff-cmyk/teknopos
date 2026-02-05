import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/voucher.dart';
import '../models/transaction.dart' as model;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('teknopos.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE packets (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE vouchers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL NOT NULL,
        isSold INTEGER NOT NULL,
        soldAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        voucherIds TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        timestamp TEXT NOT NULL,
        paymentMethod TEXT NOT NULL
      )
    ''');
  }

  // Packets
  Future<void> insertPacket(Packet packet) async {
    final db = await instance.database;
    await db.insert(
      'packets',
      packet.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<Packet>> getPackets() async {
    final db = await instance.database;
    final result = await db.query('packets');
    return result.map((json) => Packet.fromJson(json)).toList();
  }

  Future<void> deletePacket(String id) async {
    final db = await instance.database;
    await db.delete('packets', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updatePacket(Packet packet) async {
    final db = await instance.database;
    await db.update(
      'packets',
      packet.toJson(),
      where: 'id = ?',
      whereArgs: [packet.id],
    );
  }

  // Vouchers
  Future<void> insertVoucher(Voucher voucher) async {
    final db = await instance.database;
    final json = voucher.toJson();
    json['isSold'] = voucher.isSold ? 1 : 0;
    await db.insert(
      'vouchers',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> insertVouchersBulk(List<Voucher> vouchers) async {
    final db = await instance.database;
    final batch = db.batch();
    for (var voucher in vouchers) {
      final json = voucher.toJson();
      json['isSold'] = voucher.isSold ? 1 : 0;
      batch.insert(
        'vouchers',
        json,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<List<Voucher>> getVouchers() async {
    final db = await instance.database;
    final result = await db.query('vouchers');
    return result.map((json) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(json);
      map['isSold'] = (map['isSold'] == 1);
      return Voucher.fromJson(map);
    }).toList();
  }

  Future<void> updateVoucher(Voucher voucher) async {
    final db = await instance.database;
    final json = voucher.toJson();
    json['isSold'] = voucher.isSold ? 1 : 0;
    await db.update('vouchers', json, where: 'id = ?', whereArgs: [voucher.id]);
  }

  // Transactions
  Future<void> insertTransaction(model.Transaction transaction) async {
    final db = await instance.database;
    final json = transaction.toJson();
    json['voucherIds'] = jsonEncode(transaction.voucherIds);
    await db.insert(
      'transactions',
      json,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<model.Transaction>> getTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions');
    return result.map((json) {
      final Map<String, dynamic> map = Map<String, dynamic>.from(json);
      map['voucherIds'] = List<String>.from(jsonDecode(map['voucherIds']));
      return model.Transaction.fromJson(map);
    }).toList();
  }

  Future<void> deleteTransaction(String id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
