import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:chuyen_de_cong_nghe/display.dart';
import 'package:chuyen_de_cong_nghe/hex_color.dart';
import 'package:image_picker/image_picker.dart';
import 'global_variable.dart' as globals;
import 'package:http/http.dart';
import 'package:image_cropper/image_cropper.dart';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

late CameraDescription camera;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  camera = cameras.first;
  globals.camera = camera;

  runApp(MaterialApp(
    theme: ThemeData.dark(),
    home: TakePictureScreen(
      camera: camera,
    ),
  ));
}

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key, required this.camera});

  final CameraDescription camera;

  @override
  State<StatefulWidget> createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  late double screenWidth;
  late double screenHeight;
  double zoom = 0.0;
  late String imagePath;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(widget.camera, ResolutionPreset.max,
        imageFormatGroup: ImageFormatGroup.yuv420);
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void pickImageFromGallery() async {
    final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 50
    );

    setState(() {
      imagePath = "";
      if (pickedFile != null) {
        imagePath = pickedFile.path;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DisplayPicture(imagePath: imagePath),
          ),
        );
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (mounted) {
      screenWidth = MediaQuery.of(context).size.width;
      screenHeight = MediaQuery.of(context).size.height;
    }
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        child: Scaffold(
          // appBar: AppBar(
          //   backgroundColor: HexColor("ccc9dc"),
          //   title: Text(
          //     'Tra cứu',
          //     style: TextStyle(
          //       color: HexColor("324a5f"),
          //     ),
          //   ),
          //   automaticallyImplyLeading: false,
          // ),
          // You must wait until the controller is initialized before displaying the
          // camera preview. Use a FutureBuilder to display a loading spinner until the
          // controller has finished initializing.
          body: Stack(
            children: [
              Container(
                height: 600,
                width: double.infinity,
                decoration:
                    BoxDecoration(borderRadius: BorderRadius.circular(30)),
                child: FutureBuilder<void>(
                  future: _initializeControllerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      // If the Future is complete, display the preview.
                      _controller.setZoomLevel(0.0);
                      return CameraPreview(_controller);
                    } else {
                      // Otherwise, display a loading indicator.
                      return const Center(child: CircularProgressIndicator());
                    }
                  },
                ),
              ),
              Container(
                margin: const EdgeInsets.only(top: 560),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30)),
                  color: HexColor("000000"),
                ),
                height: 220,
                child: Column(
                  children: [
                    const SizedBox(
                      height: 30,
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 20),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Zoom slider",
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                    Slider(
                      inactiveColor: Colors.white,
                      value: zoom,
                      onChanged: (value) {
                        value = value * 10;
                        if (value <= 8.0 && value >= 1.0) {
                          _controller.setZoomLevel(value);
                        }
                        setState(() => zoom = value / 10);
                      },
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        padding: const EdgeInsets.only(top: 45, left: 24),
                        child: IconButton(
                          onPressed: pickImageFromGallery,
                          icon: const Icon(Icons.image, size: 40,),
                        ),
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
          floatingActionButton: Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: 80,
            width: 80,
            child: FloatingActionButton(
              backgroundColor: Colors.white,
              // Provide an onPressed callback.
              onPressed: () async {
                // Take the Picture in a try / catch block. If anything goes wrong,
                // catch the error.
                try {
                  // Ensure that the camera is initialized.
                  await _initializeControllerFuture;

                  // Attempt to take a picture and get the file `image`
                  // where it was saved.
                  final image = await _controller.takePicture();

                  if (!mounted) return;

                  // If the picture was taken, display it on a new screen.
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => DisplayPicture(
                        // Pass the automatically generated path to
                        // the DisplayPictureScreen widget.
                        imagePath: image.path,
                      ),
                    ),
                  );
                } catch (e) {
                  // If an error occurs, log the error to the console.
                  print(e);
                }
              },
              child: const Icon(
                Icons.camera_alt,
                size: 40,
              ),
            ),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
        ),
      ),
    );
  }
}

class DisplayPicture extends StatefulWidget {
  final String imagePath;

  const DisplayPicture({Key? key, required this.imagePath}) : super(key: key);

  @override
  State<DisplayPicture> createState() => _DisplayPictureState();
}

class _DisplayPictureState extends State<DisplayPicture> {
  late String imagePath;
  late String tempImagePath;

  @override
  void initState() {
    super.initState();
    imagePath = widget.imagePath;
    tempImagePath = widget.imagePath;
  }

  Future<Response> uploadImage() async {
    imagePath = tempImagePath;
    List<int> imageBytes = File(imagePath).readAsBytesSync();
    String imageBase64 = base64Encode(imageBytes);
    String apiURL = "http://192.168.0.6:5000/predict_label";
    Uri url = Uri.parse(apiURL);
    var map = <String, dynamic>{};
    map['image'] = "data:image/jpeg;base64,$imageBase64";
    return await post(url, body: map);
  }

  Future<Response?> getImageInfo() async {
    if (globals.id == null) return null;

    String apiURL = "http://222.252.25.37:9088/api/img/${globals.id}";
    Uri uri = Uri.parse(apiURL);
    return await get(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tra cứu ảnh'),
      ),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Container(
        decoration: const BoxDecoration(
          color: Colors.black
        ),
        child: Stack(
          children: <Widget>[
            Image.file(File(tempImagePath),
                fit: BoxFit.fill,
                height: 600,
                width: double.infinity),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                margin: const EdgeInsets.only(
                  left: 15,
                ),
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.white,
                  child: IconButton(
                    onPressed: () async {
                      CroppedFile? cropped = await ImageCropper()
                          .cropImage(sourcePath: imagePath, aspectRatioPresets: [
                        CropAspectRatioPreset.square,
                        CropAspectRatioPreset.ratio3x2,
                        CropAspectRatioPreset.original,
                        CropAspectRatioPreset.ratio4x3,
                        CropAspectRatioPreset.ratio16x9
                      ], uiSettings: [
                        AndroidUiSettings(
                            toolbarTitle: 'Crop',
                            cropGridColor: Colors.black,
                            initAspectRatio: CropAspectRatioPreset.original,
                            lockAspectRatio: false),
                        IOSUiSettings(title: 'Crop')
                      ]);

                      if (cropped != null) {
                        setState(
                          () {
                            tempImagePath = cropped.path;
                          },
                        );
                      }
                    },
                    icon: const Icon(Icons.crop),
                    iconSize: 30,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
      floatingActionButton: SizedBox(
        width: 75,
        height: 75,
        child: FloatingActionButton(
          backgroundColor: Colors.white,
          onPressed: () {
            showDialog(
                context: context,
                builder: (context) {
                  Widget cancelButton = TextButton(
                    onPressed: () async {
                      Navigator.pop(context);
                    },
                    child: const Text("Huỷ bỏ"),
                  );
                  Widget approveButton = TextButton(
                    onPressed: () async {
                      if (!context.mounted) return;
                      globals.id = null;
                      await uploadImage().then((response) {
                        var responseBody = jsonDecode(response.body);
                        print(responseBody['index_img']);
                        // globals.id = responseBody['index_img'];
                        globals.id = responseBody["index_img"];
                        // print(responseBody);
                      }).catchError((error) {
                        print('An error occurred: $error');
                      });

                      late String title;
                      late String imageUrl;
                      late String description;
                      late String image;
                      await getImageInfo().then((response) {
                        var responseBody = utf8.decode(response!.bodyBytes);
                        Map<String, dynamic> data = json.decode(responseBody);
                        title = data["intro"];
                        imageUrl = data["pic"];
                        description = data["description"];
                        image = imageUrl.split(",").last;
                      });
                      Uint8List bytes = base64Decode(image);
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => DisplayInformation(
                            painting: Painting(
                                title: title ??
                                    "Contact admin to add title of this image",
                                description: description ??
                                    "Contact admin to add description of this image",
                                imagePath: bytes),
                            imagePath: imagePath,
                          ),
                        ),
                      );
                    },
                    child: const Text("Đồng ý"),
                  );
                  return AlertDialog(
                    backgroundColor: Colors.white,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(20.0)),
                    ),
                    title: const Text(""),
                    content: const Text("Bạn muốn tra cứu ảnh này?",
                        style: TextStyle(
                          color: Colors.black,
                        )),
                    actions: [
                      cancelButton,
                      approveButton,
                    ],
                  );
                });
          },
          child: const Icon(Icons.arrow_forward, size: 30,),
        ),
      ),
    );
  }
}
