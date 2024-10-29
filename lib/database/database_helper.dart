import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:transfer_slip_scanner/model/transfer_data.dart';

class DatabaseHelper {
  static final _databaseName = "transferDatabase.db";
  static final _databaseVersion = 1;

  static final table = 'transfers';

  static final columnId = 'id';
  static final columnSenderName = 'senderName';
  static final columnSenderAccount = 'senderAccount';
  static final columnSenderBank = 'senderBank';
  static final columnReceiverName = 'receiverName';
  static final columnReceiverAccount = 'receiverAccount';
  static final columnReceiverBank = 'receiverBank';
  static final columnDate = 'date';
  static final columnReferenceCode = 'referenceCode';
  static final columnAmount = 'amount';

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    return await openDatabase(
      join(await getDatabasesPath(), _databaseName),
      version: _databaseVersion,
      onCreate: _onCreate, // สร้างฐานข้อมูลใหม่
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnSenderName TEXT NOT NULL,
        $columnSenderAccount TEXT NOT NULL,
        $columnSenderBank TEXT NOT NULL,
        $columnReceiverName TEXT NOT NULL,
        $columnReceiverAccount TEXT NOT NULL,
        $columnReceiverBank TEXT NOT NULL,
        $columnDate TEXT NOT NULL,
        $columnReferenceCode TEXT NOT NULL,
        $columnAmount FLOAT NOT NULL
      )
    ''');
  }

  Future<int> insert(TransferData data) async {
    Database db = await instance.database; // เรียกใช้ฐานข้อมูล
    return await db.insert(table, data.toMap()); // เพิ่มข้อมูลใหม่เข้าไปในตาราง
  }

  Future<List<TransferData>> queryAllRows() async {
    Database db = await instance.database;
    final List<Map<String, dynamic>> maps =
        await db.query(table); // ดึงข้อมูลจากตาราง

    return List.generate(maps.length, (i) {
      return TransferData.fromMap(
          maps[i]); // แปลงข้อมูลแต่ละแถวกลับไปเป็น TransferData
    });
  }

  // Method to delete the entire database and create a new one
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);

    // Close the existing database
    if (_database != null) {
      await _database!.close();
    }

    await deleteDatabase(path); //ลบไฟล์ฐานข้อมูล

    _database = await _initDatabase(); // สร้างฐานข้อมูลใหม่
  }
}
