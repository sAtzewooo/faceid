// Automatic FlutterFlow imports
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import 'index.dart'; // Imports other custom widgets
import '/flutter_flow/custom_functions.dart'; // Imports custom functions
import 'package:flutter/material.dart';
// Begin custom widget code
// DO NOT REMOVE OR MODIFY THE CODE ABOVE!

import 'package:flutter/foundation.dart';

import 'dart:convert';
import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

class CameraPhoto extends StatefulWidget {
  const CameraPhoto({
    Key? key,
    this.width,
    this.height,
  }) : super(key: key);

  final double? width;
  final double? height;

  @override
  _CameraPhotoState createState() => _CameraPhotoState();
}

class _CameraPhotoState extends State<CameraPhoto> {
  late CameraController controller;
  late Future<void> _initializeControllerFuture;
  bool isDetecting = false;
  late FaceDetector faceDetector;

  @override
  void initState() {
    super.initState();
    controller = CameraController(
      CameraDescription(
        name:
            '0', // You might need to change this to match your device's camera.
        lensDirection: CameraLensDirection.front,
        sensorOrientation: null, // Change to back if using rear camera.
      ),
      ResolutionPreset.max,
    );
    _initializeControllerFuture = controller.initialize();
    faceDetector = FirebaseVision.instance.faceDetector(
      FaceDetectorOptions(
        enableClassification: false,
        enableTracking: true,
        minFaceSize: 0.1,
        mode: FaceDetectorMode.accurate,
      ),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    faceDetector.close();
    super.dispose();
  }

  Future<void> _detectFaces(CameraImage image) async {
    if (!isDetecting) {
      isDetecting = true;
      final FirebaseVisionImage visionImage = FirebaseVisionImage.fromBytes(
        _concatenatePlanes(image.planes),
        FirebaseVisionImageMetadata(
          rawFormat: image.format.raw,
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: ImageRotation.rotation0, // Adjust accordingly.
          planeData: image.planes
              .map(
                (plane) => FirebaseVisionImagePlaneMetadata(
                  bytesPerRow: plane.bytesPerRow,
                  height: plane.height,
                  width: plane.width,
                ),
              )
              .toList(),
        ),
      );

      final List<Face> faces = await faceDetector.processImage(visionImage);
      // Now you have the list of detected faces in the `faces` variable.
      // You can display them on the camera preview or perform any other action.
      isDetecting = false;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return CameraPreview(controller, onNewCameraImage: _detectFaces);
            }
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
