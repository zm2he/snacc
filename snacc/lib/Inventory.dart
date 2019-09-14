import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';

class TextRecognizer extends StatefulWidget {
  @override
  _TextRecognizerState createState() => _TextRecognizerState();
}

class _TextRecognizerState extends State<TextRecognizer> {
  VisionText _visionText;

  @override
  Widget build(BuildContext context) {
    return CameraMlVision<VisionText>(
      detector: FirebaseVision.instance.textRecognizer().processImage,
      onResult: (visionText) {
        setState(() {
          _visionText = visionText;
        });
      },
      resolution: ResolutionPreset.ultraHigh,
    );
  }
}

class Inventory extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseUser>(
        builder: (context, firebaseUserSnapshot) {
          if (!firebaseUserSnapshot.hasData)
            return Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(
                        Theme.of(context).primaryColor)));
          final sink = Firestore.instance
              .document('session/${firebaseUserSnapshot.data.uid}');
          return StreamBuilder<DocumentSnapshot>(
            builder: (context, sessionSnapshot) {
              if (!sessionSnapshot.hasData)
                return Center(
                    child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                            Theme.of(context).primaryColor)));
              return StreamBuilder(
                builder: (context, inventorySnapshot) {
                  if (!inventorySnapshot.hasData)
                    return Center(
                        child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation(
                                Theme.of(context).primaryColor)));
                  return Scaffold(
                    body: Stack(
                      children: [
                        Container(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedOpacity(
                              child: TextRecognizer(),
                              duration: Duration(milliseconds: 200),
                              opacity:
                                  sessionSnapshot.data['cameraActive'] ? 1 : 0,
                            ),
                          ),
                          margin: EdgeInsets.all(24),
                        ),
                        AnimatedAlign(
                          alignment: (inventorySnapshot.data.documents as List)
                                      .isEmpty &&
                                  !(sessionSnapshot.data['cameraActive'] ??
                                      false)
                              ? Alignment.center
                              : Alignment.bottomCenter,
                          child: Container(
                            child: Material(
                              borderRadius: BorderRadius.circular(24),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(24),
                                child: AnimatedPadding(
                                  child: Icon(
                                    Icons.camera,
                                    color: Colors.white,
                                    size: 36,
                                  ),
                                  duration: Duration(milliseconds: 200),
                                  padding: EdgeInsets.all(
                                      (inventorySnapshot.data.documents as List)
                                                  .isEmpty &&
                                              !(sessionSnapshot
                                                      .data['cameraActive'] ??
                                                  false)
                                          ? 48
                                          : 24),
                                ),
                                onTap: () async {
                                  final cameraActive =
                                      sessionSnapshot.data['cameraActive'] ??
                                          false;
                                  await sink.setData(
                                      {'cameraActive': !cameraActive},
                                      merge: true);
                                },
                              ),
                              color: Theme.of(context).accentColor,
                            ),
                            padding: EdgeInsets.all(48),
                          ),
                          duration: Duration(milliseconds: 200),
                        ),
                      ],
                      fit: StackFit.expand,
                    ),
                  );
                },
                stream: Firestore.instance
                    .collection('inventory')
                    .where('uid', isEqualTo: firebaseUserSnapshot.data.uid)
                    .snapshots(),
              );
            },
            stream: Firestore.instance
                .document('session/${firebaseUserSnapshot.data.uid}')
                .snapshots(),
          );
        },
        future: FirebaseAuth.instance.currentUser());
  }
}
