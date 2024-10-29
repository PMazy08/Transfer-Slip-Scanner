import 'dart:io';
import 'package:flutter/material.dart';
import 'package:transfer_slip_scanner/model/transfer_data.dart';

class EditTextScreen extends StatefulWidget {
  final TransferData data;
  final String imagePath;

  EditTextScreen({required this.data, required this.imagePath});

  @override
  _EditTextScreenState createState() => _EditTextScreenState();
}

class _EditTextScreenState extends State<EditTextScreen> {
  late TransferData editableData;

  @override
  void initState() {
    super.initState();
    editableData = TransferData(
      senderName: widget.data.senderName,
      senderAccount: widget.data.senderAccount,
      senderBank: widget.data.senderBank,
      receiverName: widget.data.receiverName,
      receiverAccount: widget.data.receiverAccount,
      receiverBank: widget.data.receiverBank,
      date: widget.data.date,
      referenceCode: widget.data.referenceCode,
      amount: widget.data.amount,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFF3bcb55),
        title: Text(
          'Edit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white, // กำหนดสีของไอคอนเป็นสีขาว
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.check,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, editableData);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                constraints: BoxConstraints(
                  minWidth: 1,
                  minHeight: 1,
                ),
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Image.file(
                  File(widget.imagePath),
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                initialValue: editableData.senderName,
                decoration: InputDecoration(labelText: 'Sender Name'),
                onChanged: (value) {
                  editableData.senderName = value;
                },
              ),
              TextFormField(
                initialValue: editableData.senderAccount,
                decoration: InputDecoration(labelText: 'Sender Account'),
                onChanged: (value) {
                  editableData.senderAccount = value;
                },
              ),
              TextFormField(
                initialValue: editableData.senderBank,
                decoration: InputDecoration(labelText: 'Sender Bank'),
                onChanged: (value) {
                  editableData.senderBank = value;
                },
              ),
              TextFormField(
                initialValue: editableData.receiverName,
                decoration: InputDecoration(labelText: 'Receiver Name'),
                onChanged: (value) {
                  editableData.receiverName = value;
                },
              ),
              TextFormField(
                initialValue: editableData.receiverAccount,
                decoration: InputDecoration(labelText: 'Receiver Account'),
                onChanged: (value) {
                  editableData.receiverAccount = value;
                },
              ),
              TextFormField(
                initialValue: editableData.receiverBank,
                decoration: InputDecoration(labelText: 'Receiver Bank'),
                onChanged: (value) {
                  editableData.receiverBank = value;
                },
              ),
              TextFormField(
                initialValue: editableData.date,
                decoration: InputDecoration(labelText: 'Date'),
                onChanged: (value) {
                  editableData.date = value;
                },
              ),
              TextFormField(
                initialValue: editableData.referenceCode,
                decoration: InputDecoration(labelText: 'Reference Code'),
                onChanged: (value) {
                  editableData.referenceCode = value;
                },
              ),
              TextFormField(
                initialValue: editableData.amount.toStringAsFixed(2),
                decoration: InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    editableData.amount =
                        editableData.amount = double.tryParse(value) ?? 0.0;
                    // editableData.amount = double.tryParse(value) ?? editableData.amount;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
