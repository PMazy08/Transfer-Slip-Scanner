import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:transfer_slip_scanner/model/transfer_data.dart';
import '../pages/home.dart';

class TextExtraction {
  Future<String> extractText(String imagePath) async {
    // Extract text from the image
    String extractedText = await FlutterTesseractOcr.extractText(
      imagePath,
      language: "tha+eng",
    );

    // Split the text into lines
    List<String> lines = extractedText.split('\n');

    // Clean and filter lines
    List<String> cleanedLines = lines
        .map((line) => line.replaceAll(
            RegExp(r'\s+'), ' ')) // แทนที่ช่องว่างหลายตัวด้วยช่องว่างเดียว
        .where((line) => line.isNotEmpty && line.length >= 5)
        .toList();

    // Join the cleaned lines with newlines
    String cleanedText = cleanedLines.join('\n');
    print(cleanedLines.length);
    return cleanedText;
  }

  TransferData parseTextToTransferData(String text, int index) {
    List<String> lines = text.split('\n');
    // BBL: กรุงเทพ
    // GSB: ออมสิน
    // KBANK: กสิกรไทย
    // KMA: กรุงศรี
    // KTB: กรุงไทย
    // SCB: ไทยพาณิชย์

    switch (bankItem[index]) {
      case 'BBL':
        return parseBBL(lines);
      case 'GSB':
        return parseGSB(lines);
      case 'KBANK':
        return parseKBANK(lines);
      case 'KMA':
        return parseKMA(lines);
      case 'KTB':
        return parseKTB(lines);
      case 'SCB':
        return parseSCB(lines);
      default:
        throw Exception('');
    }
  }
  // -------------------------------------------------------------
  // -------------------------------------------------------------

  //1 fun get amount -----------------------------------------------------------
  double extAmount(List<String> lines) {
    RegExp regExp = RegExp(r'\d+\.\d+');
    for (String line in lines) {
      if (line.contains(':')) {
        continue;
      }
      Match? match = regExp.firstMatch(line);
      if (match != null) {
        String firstDecimal = match.group(0)!;
        return double.parse(firstDecimal);
      }
    }
    return 0.0;
  }

  //2 fun get referenceCode ----------------------------------------------------
  String extRefCode(List<String> lines) {
    // สร้าง RegExp สำหรับจับรหัสอ้างอิง
    RegExp referenceRegExp =
        RegExp(r'(?:\w*)?(?:รหัสอ[ฮ|ห]?้างฮิง|อ้างอิง|รหัส)[:\s]*([\w]+)');
    RegExp referenceRegExp2 = RegExp(r'(?:หมายเลข)?อ้างอิง[:\s]*([\w]+)');
    RegExp referenceRegExp3 = RegExp(r'(?:เลขที่)?รายการ[:\s]*([\w\s]+)');
    RegExp referenceRegExp4 = RegExp(r'BAYM', caseSensitive: false);

    // รวมข้อความทุกบรรทัดเข้าด้วยกัน
    String combinedText = lines.join(' ');

    // ค้นหารหัสอ้างอิงจากบรรทัดหรือข้อความรวม
    for (String line in lines) {
      Match? referenceMatch = referenceRegExp.firstMatch(line);
      if (referenceMatch != null) {
        return '${referenceMatch.group(1)}'; // คืนรหัสอ้างอิงที่พบ
      }

      // ค้นหาคำว่า "BAYM" ในบรรทัด
      if (referenceRegExp4.hasMatch(line)) {
        return line; // คืนค่าทั้งบรรทัด
      }
    }

    // ค้นหารหัสอ้างอิงจากข้อความรวม
    Match? referenceMatch2 = referenceRegExp2.firstMatch(combinedText);
    if (referenceMatch2 != null) {
      return '${referenceMatch2.group(1)}'; // คืนรหัสอ้างอิงที่พบ
    }

    // ค้นหาเลขที่รายการจากข้อความรวม
    Match? referenceMatch3 = referenceRegExp3.firstMatch(combinedText);
    if (referenceMatch3 != null) {
      return '${referenceMatch3.group(1)}'; // คืนเลขที่รายการที่พบ
    }

    return ''; // คืนค่าว่างถ้าไม่พบ
  }

  //3 fun get Date -------------------------------------------------------------
  String extDate(List<String> lines) {
    RegExp regExp = RegExp(r'\d{2}:\d{2}');
    RegExp regExp2 = RegExp(r'\d{2}:\d{2}:\d{2}');

    for (String line in lines) {
      // ตรวจสอบว่าบรรทัดมีเวลาในรูปแบบ HH:mm หรือ HH:mm:ss
      if (regExp.hasMatch(line) || regExp2.hasMatch(line)) {
        Match? match = regExp.firstMatch(line) ?? regExp2.firstMatch(line);
        if (match != null) {
          // ตัดบรรทัดให้มีเฉพาะส่วนที่อยู่ก่อนเวลา
          String beforeTime = line.substring(0, match.end).trim();
          // คืนค่าที่ตัด โดยรวมเวลา
          // return beforeTime;
          List<String> terms = beforeTime.split(' ');
          if (terms.isNotEmpty && !RegExp(r'\d').hasMatch(terms[0])) {
            // ถ้าคำแรกไม่ใช่ตัวเลข ตัดคำแรกออก
            return terms.skip(1).join(' ');
          }
          return beforeTime;
        }
      }
    }
    return '';
  }

  //4 fun get senderName -------------------------------------------------------
  String extSenName(List<String> lines, String type) {
    if (type == "gsb") {
      RegExp accountNumberRegExp =
          RegExp(r'^\d{1,4}xxxx\d{1,4}$', caseSensitive: false);
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (accountNumberRegExp.hasMatch(line)) {
          int start = dateLine(lines);
          return nameGKK(lines, start, i);
        }
      }
    } else if (type == "bbl" || type == "scb") {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){2,}', caseSensitive: false);
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (accountNumberRegExp.hasMatch(line)) {
          if (type == "bbl") {
            int start = amoutLine(lines);
            // print(start);
            // print(i);
            // print("---------");
            return nameBK(lines, start, i);
          } else {
            int start = refcodeLine(lines);
            print(start);
            print(i);
            return nameSCB(lines, start, i);
          }
        }
      }
    } else {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){3,}', caseSensitive: false);
      // ค้นหาบรรทัดแรกที่มี '-' อย่างน้อย 3 ตัว
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (accountNumberRegExp.hasMatch(line)) {
          if (type == "kma") {
            int start = dateLine(lines);
            print(start);
            print(i);
            return nameBK(lines, start, i);
          } else if (type == "kb") {
            int start = dateLine(lines);
            print(start);
            print(i);
            return nameGKK(lines, start, i);
          } else {
            int start = refcodeLine(lines);
            print(start);
            print(i);
            return nameGKK(lines, start, i);
          }
        }
      }
    }
    return '';
  }

  // ---------------------------------------------------
  // ###########################################################################
  // fuction for extSenName
  int dateLine(List<String> lines) {
    RegExp regExp = RegExp(r'\d{2}:\d{2}');
    RegExp regExp2 = RegExp(r'\d{2}:\d{2}:\d{2}');

    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      // ตรวจสอบว่าบรรทัดมีเวลาในรูปแบบ HH:mm หรือ HH:mm:ss
      if (regExp.hasMatch(line) || regExp2.hasMatch(line)) {
        Match? match = regExp.firstMatch(line) ?? regExp2.firstMatch(line);
        if (match != null) {
          return i;
        }
      }
    }
    return 0;
  }

  int amoutLine(List<String> lines) {
    RegExp regExp = RegExp(r'\d+\.\d+');
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      if (line.contains(':')) {
        continue;
      }
      Match? match = regExp.firstMatch(line);
      if (match != null) {
        return i;
      }
    }
    return 0;
  }

  int refcodeLine(List<String> lines) {
    //สร้าง RegExp สำหรับจับรหัสอ้างอิง
    RegExp referenceRegExp =
        RegExp(r'(?:\w*)?(?:รหัสอ[ฮ|ห]?้างฮิง|อ้างอิง|รหัส)[:\s]*([\w]+)');

    // ค้นหารหัสอ้างอิงจากบรรทัดหรือข้อความรวม
    for (int i = 0; i < lines.length; i++) {
      String line = lines[i];
      Match? referenceMatch = referenceRegExp.firstMatch(line);
      if (referenceMatch != null) {
        return i; // คืนรหัสอ้างอิงที่พบ
      }
    }
    return 0; // คืนค่าว่างถ้าไม่พบ
  }

  String nameSCB(List<String> lines, int start, int end) {
    String str = lines.sublist(start + 1, end).join(' ');
    List<String> words = str.split(' ');
    List<String> filteredWords =
        words.where((word) => word.length > 2).toList();
    List<String> filteredWords2 = filteredWords.sublist(1); // ตัดกลุ่มแรกออก
    return filteredWords2.join(' ');
  }

  String nameBK(List<String> lines, int start, int end) {
    String str = lines.sublist(start + 1, end).join(' ');
    List<String> words = str.split(' ');
    List<String> filteredWords =
        words.where((word) => word.length > 2).toList();
    return filteredWords.join(' ');
  }

  String nameGKK(List<String> lines, int start, int end) {
    String str = lines.sublist(start + 1, end - 1).join(' ');
    List<String> words = str.split(' ');
    List<String> filteredWords =
        words.where((word) => word.length > 2).toList();
    return filteredWords.join(' ');
  }
  // ###########################################################################

  //5 fun get senderAccount ----------------------------------------------------
  String extSenAcc(List<String> lines, String type) {
    if (type == "gsb") {
      RegExp accountNumberRegExp =
          RegExp(r'^\d{1,4}xxxx\d{1,4}$', caseSensitive: false);
      for (String line in lines) {
        if (accountNumberRegExp.hasMatch(line)) {
          return line; // คืนบรรทัดที่พบ
        }
      }
    } else if (type == "bbl" || type == "scb") {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){2,}', caseSensitive: false);
      for (String line in lines) {
        if (accountNumberRegExp.hasMatch(line)) {
          return line; // คืนบรรทัดที่พบ
        }
      }
    } else {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){3,}', caseSensitive: false);
      // ค้นหาบรรทัดแรกที่มี '-' อย่างน้อย 3 ตัว
      for (String line in lines) {
        if (accountNumberRegExp.hasMatch(line)) {
          return line; // คืนบรรทัดที่พบ
        }
      }
    }

    return ''; // คืนค่าว่างถ้าไม่พบ
  }

  //6 fun get receiverName -----------------------------------------------------
  String extRecName(List<String> lines, String type) {
    if (type == "gsb") {
      RegExp accountNumberRegExp =
          RegExp(r'^\d{1,4}xxxx\d{1,4}$', caseSensitive: false);
      bool foundFirst = false;
      int start = 0;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            start = i;
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            String str = lines.sublist((start + 1), (i - 2) + 1).join(' ');
            //                               start, end
            List<String> words = str.split(' ');
            List<String> filteredWords =
                words.where((word) => word.length > 2).toList();
            return filteredWords.join(' ');
          }
        }
      }
    } else if (type == "bbl") {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){2,}', caseSensitive: false);
      bool foundFirst = false;
      int start = 0;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            start = i;
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            // print(start);
            String str = lines.sublist((start + 2), (i - 1) + 1).join(' ');
            //                               start, end
            List<String> words = str.split(' ');
            List<String> filteredWords =
                words.where((word) => word.length > 2).toList();
            return filteredWords.join(' ');
          }
        }
      }
    } else if (type == "scb") {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){2,}', caseSensitive: false);
      RegExp accountNumberRegExp2 = RegExp(r'^[a-zA-Z]-\d{4}$');
      bool foundFirst = false;
      int start = 0;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];
        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            start = i;
            // print(start);
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            bool found2 = false;
            for (int i = 0; i < lines.length; i++) {
              String line = lines[i];
              if (accountNumberRegExp.hasMatch(line)) {
                // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
                if (!found2) {
                  found2 = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
                  continue; // ข้ามไปยังบรรทัดถัดไป
                } else {
                  String str = lines.sublist(start + 1, i).join(' ');
                  //                      start, end
                  List<String> words = str.split(' ');
                  // ตัดกลุ่มแรกออก (index 0) และเอาคำที่เหลือมา
                  List<String> filteredWords =
                      words.where((word) => word.length > 2).toList();

                  List<String> filteredWords2 =
                      filteredWords.sublist(1); // ตัดกลุ่มแรกออก
                  return filteredWords2.join(' ');
                }
              }
            }
          }
        }
        if (accountNumberRegExp2.hasMatch(line)) {
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            String str = lines.sublist((start + 1), (i - 1) + 1).join(' ');
            //                      start, end
            List<String> words = str.split(' ');
            // ตัดกลุ่มแรกออก (index 0) และเอาคำที่เหลือมา
            List<String> filteredWords =
                words.where((word) => word.length > 2).toList();

            List<String> filteredWords2 =
                filteredWords.sublist(1); // ตัดกลุ่มแรกออก
            return filteredWords2.join(' ');
          }
        }
      }
    } else if (type == "kma") {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){3,}', caseSensitive: false);
      bool foundFirst = false;
      int start = 0;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            start = i;
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            // print(start);
            String str = lines.sublist((start + 1), (i - 1) + 1).join(' ');
            //                               start, end
            // แยก str ออกเป็นคำ ๆ
            List<String> words = str.split(' ');

            List<String> filteredWords =
                words.where((word) => word.length > 2).toList();
            return filteredWords.join(' ');
          }
        }
      }
    } else {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){3,}', caseSensitive: false);
      bool foundFirst = false;
      int start = 0;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            start = i;
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            // print(start);
            String str = lines.sublist(start + 1, i - 1).join(' ');
            //                               start, end
            // แยก str ออกเป็นคำ ๆ
            List<String> words = str.split(' ');

            List<String> filteredWords =
                words.where((word) => word.length > 2).toList();
            return filteredWords.join(' ');
          }
        }
      }
    }

    return '';
  }

  //7 fun get receiverAccount --------------------------------------------------
  String extRecAcc(List<String> lines, String type) {
    if (type == "gsb") {
      RegExp accountNumberRegExp =
          RegExp(r'^\d{1,4}xxxx\d{1,4}$', caseSensitive: false);
      bool foundFirst = false;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            return line;
          }
        }
      }
    } else if (type == "bbl") {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){2,}', caseSensitive: false);
      bool foundFirst = false;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            return line;
          }
        }
      }
    } else if (type == "scb") {
      RegExp accountNumberRegExp = RegExp(r'^[a-zA-Z]-\d{4}$');
      for (String line in lines) {
        if (accountNumberRegExp.hasMatch(line)) {
          return line; // คืนบรรทัดที่พบ
        } else {
          RegExp accountNumberRegExp =
              RegExp(r'(-.*?){2,}', caseSensitive: false);
          bool foundFirst = false;
          for (int i = 0; i < lines.length; i++) {
            String line = lines[i];

            if (accountNumberRegExp.hasMatch(line)) {
              // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
              if (!foundFirst) {
                foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
                continue; // ข้ามไปยังบรรทัดถัดไป
              } else {
                return line;
              }
            }
          }
        }
      }
    } else {
      RegExp accountNumberRegExp = RegExp(r'(-.*?){3,}', caseSensitive: false);
      bool foundFirst = false;
      for (int i = 0; i < lines.length; i++) {
        String line = lines[i];

        if (accountNumberRegExp.hasMatch(line)) {
          // ถ้าเป็นบรรทัดแรกที่พบ ให้ข้ามไป
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            return line;
          }
        }
      }
    }

    return ''; // คืนค่าว่างถ้าไม่พบ
  }

  //8 fun get receiverBank -----------------------------------------------------
  String extRecBank(List<String> lines, String type) {
    String? findAccountNumber(RegExp accountNumberRegExp) {
      bool foundFirst = false;
      for (int i = 1; i < lines.length; i++) {
        String currentLine = lines[i];
        String previousLine = "";

        if (type == "bbl") {
          previousLine = lines[i + 1];
        } else {
          previousLine = lines[i - 1];
        }

        if (accountNumberRegExp.hasMatch(currentLine)) {
          if (!foundFirst) {
            foundFirst = true; // เปลี่ยนสถานะว่าพบบรรทัดแรกแล้ว
            continue; // ข้ามไปยังบรรทัดถัดไป
          } else {
            // แยกข้อความตามช่องว่าง
            List<String> parts = previousLine.split(' ');

            // ตรวจสอบว่ามีกลุ่มคำที่สองหรือไม่
            if (parts.length > 1) {
              return parts[1]; // คืนค่ากลุ่มคำที่สอง
            }

            // คืนค่าข้อมูลเดิมถ้าไม่มีกลุ่มคำที่สอง
            return previousLine.trim();
            // return previousLine; // คืนค่า
          }
        }
      }
      return null; // คืนค่า null ถ้าไม่พบ
    }

    if (type == "gsb") {
      return findAccountNumber(
              RegExp(r'^\d{1,4}xxxx\d{1,4}$', caseSensitive: false)) ??
          '';
    } else if (type == "bbl") {
      return findAccountNumber(RegExp(r'(-.*?){2,}', caseSensitive: false)) ??
          '';
    } else {
      return findAccountNumber(RegExp(r'(-.*?){3,}', caseSensitive: false)) ??
          '';
    }
  }

  // -------------------------------------------------------------
  // -------------------------------------------------------------
  // BBL
  TransferData parseBBL(List<String> lines) {
    String date = extDate(lines);
    double amount = extAmount(lines);
    String senderName = extSenName(lines, "bbl");
    String senderAccount = extSenAcc(lines, "bbl");
    String receiverName = extRecName(lines, "bbl");
    String receiverAccount = extRecAcc(lines, "bbl");
    String receiverBank = extRecBank(lines, "bbl");
    String referenceCode = extRefCode(lines);

    return TransferData(
      senderName: senderName,
      senderAccount: senderAccount,
      senderBank: 'ธนาคารกรุงเทพ',
      receiverName: receiverName,
      receiverAccount: receiverAccount,
      receiverBank: receiverBank,
      date: date,
      referenceCode: referenceCode,
      amount: amount,
    );
  }

  // -------------------------------------------------------------
  // GSB
  TransferData parseGSB(List<String> lines) {
    double amount = extAmount(lines);
    String referenceCode = extRefCode(lines);
    String date = extDate(lines);
    String senderName = extSenName(lines, "gsb");
    String senderAccount = extSenAcc(lines, "gsb");
    String receiverName = extRecName(lines, "gsb");
    String receiverAccount = extRecAcc(lines, "gsb");
    String receiverBank = extRecBank(lines, "gsb");

    return TransferData(
      senderName: senderName,
      senderAccount: senderAccount,
      senderBank: 'ธนาคารออมสิน',
      receiverName: receiverName,
      receiverAccount: receiverAccount,
      receiverBank: receiverBank,
      date: date,
      referenceCode: referenceCode,
      amount: amount,
    );
  }

  // -------------------------------------------------------------
  // KBANK
  TransferData parseKBANK(List<String> lines) {
    String date = extDate(lines);
    String senderName = extSenName(lines, "kb");
    String senderAccount = extSenAcc(lines, "a");
    String receiverName = extRecName(lines, "a");
    String receiverBank = extRecBank(lines, "a");
    String receiverAccount = extRecAcc(lines, "a");
    String referenceCode = extRefCode(lines);
    double amount = extAmount(lines);

    return TransferData(
      senderName: senderName,
      senderAccount: senderAccount,
      senderBank: 'ธ.กสิกรไทย',
      receiverName: receiverName,
      receiverAccount: receiverAccount,
      receiverBank: receiverBank,
      date: date,
      referenceCode: referenceCode,
      amount: amount,
    );
  }

  // -------------------------------------------------------------
  // KMA
  TransferData parseKMA(List<String> lines) {
    String date = extDate(lines);
    String senderName = extSenName(lines, "kma");
    String senderAccount = extSenAcc(lines, "a");
    String receiverName = extRecName(lines, "kma");
    String receiverAccount = extRecAcc(lines, "a");
    String receiverBank = '';
    double amount = extAmount(lines);
    String referenceCode = extRefCode(lines);

    return TransferData(
      senderName: senderName,
      senderAccount: senderAccount,
      senderBank: 'กรุงศรี',
      receiverName: receiverName,
      receiverAccount: receiverAccount,
      receiverBank: receiverBank,
      date: date,
      referenceCode: referenceCode,
      amount: amount,
    );
  }

  // -------------------------------------------------------------
  // KTB
  TransferData parseKTB(List<String> lines) {
    String referenceCode = extRefCode(lines);
    String senderName = extSenName(lines, "ktb");
    String senderAccount = extSenAcc(lines, "a");
    String receiverName = extRecName(lines, "a");
    String receiverBank = extRecBank(lines, "a");
    String receiverAccount = extRecAcc(lines, "a");
    double amount = extAmount(lines);
    String date = extDate(lines);

    return TransferData(
      senderName: senderName,
      senderAccount: senderAccount,
      senderBank: 'กรุงไทย',
      receiverName: receiverName,
      receiverAccount: receiverAccount,
      receiverBank: receiverBank,
      date: date,
      referenceCode: referenceCode,
      amount: amount,
    );
  }

  // -------------------------------------------------------------
  // SCB
  TransferData parseSCB(List<String> lines) {
    String date = extDate(lines);
    String referenceCode = extRefCode(lines);
    String senderName = extSenName(lines, "scb");
    String senderAccount = extSenAcc(lines, "scb");
    String receiverName = extRecName(lines, "scb");
    String receiverAccount = extRecAcc(lines, "scb");
    String receiverBank = '';
    double amount = extAmount(lines);

    return TransferData(
      senderName: senderName,
      senderAccount: senderAccount,
      senderBank: 'ไทยพาณิชย์',
      receiverName: receiverName,
      receiverAccount: receiverAccount,
      receiverBank: receiverBank,
      date: date,
      referenceCode: referenceCode,
      amount: amount,
    );
  }
}
