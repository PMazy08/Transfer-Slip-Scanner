import 'dart:io';
import 'package:flutter/material.dart';
import 'package:transfer_slip_scanner/database/database_helper.dart';
import 'package:transfer_slip_scanner/model/transfer_data.dart';
import 'edit_text.dart';

class ShowImage extends StatefulWidget {
  final List<String> imagePaths;
  final List<TransferData> transferDataList;

  ShowImage({required this.imagePaths, required this.transferDataList});

  @override
  _ShowImageState createState() => _ShowImageState();
}

class _ShowImageState extends State<ShowImage> {
  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3bcb55),
        title: Text(
          'Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // กำหนดสีของไอคอนเป็นสีขาว
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: widget.imagePaths.length,
              itemBuilder: (context, index) {
                TransferData data = widget.transferDataList[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () async {
                      // Navigate to the text editing screen and await the result
                      final updatedData = await Navigator.push<TransferData>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditTextScreen(
                            data: data,
                            imagePath: widget.imagePaths[index],
                          ),
                        ),
                      );
                      // Update the state if data is returned
                      if (updatedData != null) {
                        setState(() {
                          widget.transferDataList[index] = updatedData;
                        });
                      }
                    },
                    child: Container(
                      height: 300,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          // Image on the left side
                          Container(
                            width: 125,
                            margin: EdgeInsets.all(8),
                            child: Image.file(
                              File(widget.imagePaths[index]),
                              width: 125,
                              fit: BoxFit.cover,
                            ),
                          ),
                          // Text on the right side
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text.rich(
                                TextSpan(
                                  children: [
                                    TextSpan(
                                      text: "ผู้โอน: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.senderName}\n"),
                                    TextSpan(
                                      text: "เลขที่บัญชี: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.senderAccount}\n"),
                                    TextSpan(
                                      text: "ธนาคาร: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.senderBank}\n\n"),
                                    TextSpan(
                                      text: "ผู้รับ: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.receiverName}\n"),
                                    TextSpan(
                                      text: "เลขที่บัญชี: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.receiverAccount}\n"),
                                    TextSpan(
                                      text: "ธนาคาร: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.receiverBank}\n\n"),
                                    TextSpan(
                                      text: "วันที่: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.date}\n"),
                                    TextSpan(
                                      text: "รหัสอ้างอิง: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(text: "${data.referenceCode}\n"),
                                    TextSpan(
                                      text: "จำนวนเงิน: ",
                                      style: TextStyle(
                                          fontWeight:
                                              FontWeight.bold), // ทำให้ตัวหนา
                                    ),
                                    TextSpan(
                                        text:
                                            "${data.amount.toStringAsFixed(2)} ฿\n"),
                                  ],
                                ),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 80),
        ],
      ),
      floatingActionButton: Padding(
        padding:
            EdgeInsets.only(bottom: 15), // Padding for the FloatingActionButton
        child: FloatingActionButton.extended(
          onPressed: () async {
            // Insert all data into the database
            for (TransferData data in widget.transferDataList) {
              await DatabaseHelper.instance.insert(data);
            }
            // Optionally navigate back or show a success message
            Navigator.popUntil(context, ModalRoute.withName('/'));
          },
          backgroundColor: Color(0xFFFFBA00),
          label: Text('Save'),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
