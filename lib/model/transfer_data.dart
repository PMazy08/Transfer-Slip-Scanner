class TransferData {
  int? id;
  String senderName;
  String senderAccount;
  String senderBank;
  String receiverName;
  String receiverAccount;
  String receiverBank;
  String date;
  String referenceCode;
  double amount;

  TransferData({
    this.id,
    required this.senderName,
    required this.senderAccount,
    required this.senderBank,
    required this.receiverName,
    required this.receiverAccount,
    required this.receiverBank,
    required this.date,
    required this.referenceCode,
    required this.amount,
  });

  // แปลงค่า ใน Map
  Map<String, dynamic> toMap() {
    return {
      'id': id, // Add this if you have an id field
      'senderName': senderName,
      'senderAccount': senderAccount,
      'senderBank': senderBank,
      'receiverName': receiverName,
      'receiverAccount': receiverAccount,
      'receiverBank': receiverBank,
      'date': date,
      'referenceCode': referenceCode,
      'amount': amount,
    };
  }

  // ดึงค่า จาก Map
  factory TransferData.fromMap(Map<String, dynamic> map) {
    return TransferData(
      id: map['id'], // Add this if you have an id field
      senderName: map['senderName'],
      senderAccount: map['senderAccount'],
      senderBank: map['senderBank'],
      receiverName: map['receiverName'],
      receiverAccount: map['receiverAccount'],
      receiverBank: map['receiverBank'],
      date: map['date'],
      referenceCode: map['referenceCode'],
      amount: map['amount'],
    );
  }
}
