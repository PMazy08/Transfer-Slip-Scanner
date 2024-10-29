import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:transfer_slip_scanner/database/database_helper.dart';
import 'package:transfer_slip_scanner/model/transfer_data.dart';
import 'package:path/path.dart' as p; // นำเข้าพร้อมอัลลิอัส
import 'dart:io';
import 'package:permission_handler/permission_handler.dart'; // นำเข้าคลาส permission_handler

class ShowDb extends StatefulWidget {
  @override
  _ShowDbState createState() => _ShowDbState();
}

class _ShowDbState extends State<ShowDb> {
  late Future<List<TransferData>> _transferDataList;

  @override
  void initState() {
    super.initState();
    _transferDataList = _fetchTransferData();
  }

  Future<List<TransferData>> _fetchTransferData() async {
    return await DatabaseHelper.instance.queryAllRows();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.storage.status;
    if (!status.isGranted) {
      final result = await Permission.storage.request();
      if (result.isDenied) {
        // แสดงการแจ้งเตือนหรือคำแนะนำ
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Storage permission is required to export the database.')),
        );
      }
    }
  }

  Future<String?> _promptForFileName(BuildContext context) async {
    TextEditingController controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter File Name'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: 'Enter file name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(controller.text.isNotEmpty ? controller.text : null),
            child: Text('OK'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red, // กำหนดสีของข้อความเป็นสีแดง
            ),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _exportDatabase() async {
    await _checkPermissions();

    // Prompt user for file name
    String? fileName = await _promptForFileName(context);
    if (fileName == null || fileName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No file name provided. Export cancelled.')),
      );
      return;
    }

    try {
      // Define the path to the Downloads directory
      final downloadsPath =
          '/storage/emulated/0/Download'; // Direct path to Downloads directory
      final databasePath = await getDatabasesPath();
      final dbPath = p.join(databasePath, 'transferDatabase.db');

      // Ensure the Downloads directory exists
      final downloadDirectory = Directory(downloadsPath);
      if (!await downloadDirectory.exists()) {
        await downloadDirectory.create(recursive: true);
      }

      final database = await openDatabase(dbPath);

      // Create the SQL file
      final sqlFile = File(p.join(
          downloadsPath, '$fileName.sql')); // Use the user-provided file name
      final sqlBuffer = StringBuffer();

      final tables = await database
          .rawQuery("SELECT name FROM sqlite_master WHERE type='table';");
      final tableNames = tables.map((t) => t['name'] as String).toList();

      for (final table in tableNames) {
        final createTableStatement = await database.rawQuery(
            '''SELECT sql FROM sqlite_master WHERE type='table' AND name='$table';''');
        if (createTableStatement.isNotEmpty) {
          sqlBuffer.writeln(createTableStatement.first['sql']);
          sqlBuffer.writeln(';');
        }

        final rows = await database.rawQuery('SELECT * FROM $table;');
        for (final row in rows) {
          final values = row.values
              .map((v) => v is String ? "'$v'" : v.toString())
              .join(', ');
          final columns = row.keys.join(', ');
          sqlBuffer.writeln('INSERT INTO $table ($columns) VALUES ($values);');
        }
      }

      await sqlFile.writeAsString(sqlBuffer.toString());

      // Notify the user
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Database exported to $downloadsPath/$fileName.sql')));
      print('Database exported to: $downloadsPath/$fileName.sql');
    } catch (e) {
      print('Error exporting database: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export database: $e')));
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3bcb55),
        title: Text(
          'Storage',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // กำหนดสีของไอคอนเป็นสีขาว
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.delete_forever,
              color: Colors.white,
            ),
            onPressed: () async {
              // ยืนยันก่อนที่จะลบข้อมูลทั้งหมด
              final shouldDelete = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Confirm Delete'),
                  content: Text(
                      'Are you sure you want to delete all records and reset the database?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.red, // กำหนดสีของข้อความเป็นสีแดง
                      ),
                      child: Text('Delete'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('Cancel'),
                    ),
                  ],
                ),
              );
              if (shouldDelete) {
                await DatabaseHelper.instance
                    .resetDatabase(); // รีเซ็ตฐานข้อมูล
                setState(() {
                  _transferDataList = _fetchTransferData();
                });
              }
            },
          ),
          IconButton(
            icon: Icon(
              Icons.drive_file_move,
              color: Colors.white,
            ),
            onPressed: () async {
              await _exportDatabase();
            },
          ),
        ],
      ),
      body: FutureBuilder<List<TransferData>>(
        future: _transferDataList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No data available.'));
          }

          final transferDataList = snapshot.data!;

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: <DataColumn>[
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Sender Name')),
                  DataColumn(label: Text('Sender Account')),
                  DataColumn(label: Text('Sender Bank')),
                  DataColumn(label: Text('Receiver Name')),
                  DataColumn(label: Text('Receiver Account')),
                  DataColumn(label: Text('Receiver Bank')),
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Reference Code')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: transferDataList.map((data) {
                  return DataRow(cells: [
                    DataCell(Text(data.id?.toString() ?? '')),
                    DataCell(Text(data.senderName)),
                    DataCell(Text(data.senderAccount)),
                    DataCell(Text(data.senderBank)),
                    DataCell(Text(data.receiverName)),
                    DataCell(Text(data.receiverAccount)),
                    DataCell(Text(data.receiverBank)),
                    DataCell(Text(data.date)),
                    DataCell(Text(data.referenceCode)),
                    DataCell(Text(data.amount.toStringAsFixed(2))),
                  ]);
                }).toList(),
              ),
            ),
          );
        },
      ),
    );
  }
}
