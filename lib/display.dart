import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:chuyen_de_cong_nghe/hex_color.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';

import 'camera.dart';

class Painting {
  final String title;
  final String description;
  final Uint8List imagePath;

  Painting({
    required this.title,
    required this.description,
    required this.imagePath,
  });
}

class DisplayInformation extends StatefulWidget {
  const DisplayInformation(
      {Key? key, required this.painting, required this.imagePath})
      : super(key: key);
  final Painting painting;
  final String imagePath;

  @override
  State<DisplayInformation> createState() => _DisplayInformationState();
}

class _DisplayInformationState extends State<DisplayInformation> {
  late Painting painting;
  final TextEditingController _textFieldController = TextEditingController();
  late String imagePath;

  @override
  void initState() {
    super.initState();
    painting = widget.painting;
    imagePath = widget.imagePath;
  }

  Future<void> sendImageReport(BuildContext context) async {
    List<int> imageBytes = File(imagePath).readAsBytesSync();
    String imageBase64 = base64Encode(imageBytes);
    String apiURL = "http://222.252.25.37:9088/api/img/faulty";
    Uri url = Uri.parse(apiURL);
    var body = jsonEncode({
      "img": "data:image/jpeg;base64,$imageBase64",
      "userLabel": _textFieldController.text
    });
    Response response = await post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: body,
    );

    print(response.body);
  }

  Future<void> showSuccessDialog(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // To make the card compact
            children: <Widget>[
              const SizedBox(height: 10),
              const Text(
                "Thành công",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black),
              ),
              const SizedBox(height: 40),
              const Icon(
                Icons.check,
                // to keep the icon checked state
                size: 80,
                color: Colors.green,
              ),
              const SizedBox(height: 24),
              const SizedBox(height: 24),
              OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK", style: TextStyle(color: Colors.black)),
              )
            ],
          ),
        );
      },
    );
  }

  void displayTextInputDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          backgroundColor: HexColor("415a77"),
          title: const Text('Báo cáo hình ảnh'),
          content: TextField(
            controller: _textFieldController,
            decoration: const InputDecoration(
                hintText: "Gợi ý tên ảnh", hintStyle: TextStyle(fontSize: 12)),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Huỷ bỏ',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text(
                'Báo cáo',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                await sendImageReport(context);
                await showSuccessDialog(context);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          appBar: AppBar(
            backgroundColor: HexColor("2b2d42"),
            title: const Text('Kết quả'),
            automaticallyImplyLeading: false,
          ),
          body: Container(
            color: HexColor("fefae0"),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: <Widget>[
                    Text(
                      painting.title,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: HexColor("bc6c25")),
                    ),
                    const SizedBox(height: 32),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(40),
                      child: Image.memory(
                        painting.imagePath,
                        height: 250,
                      ),
                    ),
                    // Replace with Image.network() if your images are network based
                    const SizedBox(height: 53),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: HexColor("bc6c25"), width: 3),
                        color: HexColor("fdf0d5"),
                        borderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                      ),
                      margin: const EdgeInsets.only(bottom: 30),
                      padding: const EdgeInsets.all(10),
                      height: 210,
                      width: double.infinity,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: Text(
                          painting.description,
                          overflow: TextOverflow.fade,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            _textFieldController.text = "";
                            displayTextInputDialog(context);
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: const [
                                Icon(Icons.warning),
                                // Replace with your desired icon
                                Text('Báo cáo'),
                                // Replace with your desired text
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 114,
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => TakePictureScreen(
                                  camera: camera,
                                ),
                              ),
                            );
                          },
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all<Color>(Colors.red),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              children: const [
                                Icon(Icons.camera_alt),
                                // Replace with your desired icon
                                Text('Tra cứu'),
                                // Replace with your desired text
                              ],
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
