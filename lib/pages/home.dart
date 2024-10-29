import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_v2/tflite_v2.dart';
import 'package:transfer_slip_scanner/model/transfer_data.dart';
import 'package:transfer_slip_scanner/pages/show_db.dart';
import 'show_image.dart';
import '../futures/text_detection.dart';

List<String> bankItem = [];

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  File? _image;
  List<File> _images = [];

  List<TransferData> transferDataList = [];

  // List<dynamic>? _recognitions; // Updated type for recognitions
  String v = "";
  String recognizedText = '';
  bool _isLoading = false; // Added variable to track loading state

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {
      setState(() {});
    });
  }

  // Load TensorFlow Lite model
  Future<void> loadModel() async {
    await Tflite.loadModel(
      model: "assets/MBNv2G.tflite",
      labels: "assets/labels.txt",
    );
  }

//=========================================================================

  // Get Image or Images
  Future<void> getImageOrImages(ImageSource source) async {
    final picker = ImagePicker();
    try {
      if (source == ImageSource.camera) {
        final pickedImage = await picker.pickImage(source: source);
        if (pickedImage != null) {
          setState(() {
            _image = File(pickedImage.path);
            // clear data
            bankItem.clear();
            transferDataList.clear();
          });

          setState(() {
            _isLoading =
                true; // Set loading to true before starting text extraction
          });
          int i = 0;
          await detectImage(_image!, i); // Wait for image detection
          setState(() {
            _isLoading = false; // Set loading to false after detection is done
          });

          // bankItem.add(v);
          print(bankItem);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShowImage(
                imagePaths: _image != null ? [_image!.path] : [],
                transferDataList: transferDataList,
              ),
            ),
          );
        } else {}
      } else if (source == ImageSource.gallery) {
        final pickedImages = await picker.pickMultiImage();
        if (pickedImages.isNotEmpty) {
          // ตรวจสอบว่ามีการเลือกภาพ
          if (_images.length + pickedImages.length <= 20) {
            setState(() {
              _images.addAll(
                  pickedImages.map((pickedImage) => File(pickedImage.path)));
              // Clear data
              bankItem.clear();
              transferDataList.clear();
            });

            // int startTime = DateTime.now().millisecondsSinceEpoch;

            for (int i = 0; i < _images.length; i++) {
              setState(() {
                _isLoading = true;
              });
              await detectImage(_images[i], i);
              setState(() {
                _isLoading = false;
              });
            }

            print('-----------------------------------');
            print(bankItem);
            // int endTime = DateTime.now().millisecondsSinceEpoch;
            // print(">>>> Inference took ${endTime - startTime}ms");

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShowImage(
                  imagePaths: _images.map((image) => image.path).toList(),
                  transferDataList: transferDataList,
                ),
              ),
            );
          } else {
            // แสดง Snackbar หากจำนวนภาพเกิน 20
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cannot select more than 20 images.'),
                backgroundColor: Color(0xFFFFBA00),
              ),
            );
          }
        } else {
          // ไม่มีการเลือกภาพ, คงอยู่ที่หน้าเดิม
          // ไม่มีการนำทางหรือการกระทำใด ๆ
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

//=========================================================================

  // Detect objects in image using TensorFlow Lite
  Future detectImage(File image, int index) async {
    try {
      var recognitions = await Tflite.runModelOnImage(
        path: image.path,
        numResults: 6,
        threshold: 0.05,
        imageMean: 127.5,
        imageStd: 127.5,
      );
      // Find the label with highest confidence
      dynamic highestRecognition;
      if (recognitions != null && recognitions.isNotEmpty) {
        highestRecognition = recognitions.reduce((curr, next) =>
            curr["confidence"] > next["confidence"] ? curr : next);
      }
      setState(() {
        // _recognitions = recognitions;
        v = highestRecognition != null ? highestRecognition["label"] : "";
        bankItem.add(v);
      });
      print('-----------------------------------');
      print("Image processed successfully: $v");
      print('-----------------------------------');
      await _extractText(image.path, index);
    } catch (e) {
      print('Error running model on image: $e');
    }
  }

//=========================================================================
  // Detect text

  // old
  // Future<void> _extractText(String imagePath, int index) async {
  //   String cleanedText = await TextExtraction.extractText(imagePath);
  //   // setState(() {
  //   //   recognizedText = cleanedText;
  //   // });
  //   print(cleanedText);
  //   TransferData data = TextExtraction.parseTextToTransferData(cleanedText, index);
  //   setState(() {
  //     transferDataList.add(data);
  //   });
  // }

  Future<void> _extractText(String imagePath, int index) async {
    // Create an instance of TextExtraction
    TextExtraction extractor = TextExtraction();

    try {
      String cleanedText = await extractor.extractText(imagePath);
      print(cleanedText);

      // Access instance method through the object
      TransferData data = extractor.parseTextToTransferData(cleanedText, index);
      setState(() {
        transferDataList.add(data);
      });
    } catch (e) {
      print("Error extracting text: $e");
      setState(() {
        recognizedText = "Failed to extract text.";
      });
    }
  }

//=========================================================================

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show loading indicator if _isLoading is true
            : Center(
                // Add a Center widget here
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          getImageOrImages(ImageSource.camera);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(
                              0xFF3bcb55), // Set the background color of the button
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_camera,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Camera',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Second button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          _images = [];
                          getImageOrImages(ImageSource.gallery);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(
                              0xFF6D9773), // Set the background color of the button
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.photo_library,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    // Third button
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShowDb(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(
                              0xFFB46617), // Set the background color of the button
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.storage,
                              size: 40,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Storage',
                              style: TextStyle(
                                fontSize: 20,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}
