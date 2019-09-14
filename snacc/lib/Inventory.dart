import 'dart:convert';

import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:snacc/stopwords.dart';
import 'package:snacc/wordbank.dart';

class TextRecognizer extends StatefulWidget {
  final List<String> words = [];

  @override
  _TextRecognizerState createState() => _TextRecognizerState();
}

class _TextRecognizerState extends State<TextRecognizer> {
  VisionText _visionText;

  @override
  Widget build(BuildContext context) {
    if (_visionText != null) {
      widget.words.clear();
      for (var line in _visionText.text.split('\n')) {
        for (var word in line.split(' ')) {
          word = word.toLowerCase();
          if (word.length > 2 &&
              wordbank.contains(word) &&
              !stopwords.contains(word)) {
            widget.words.add(word);
          }
        }
      }
      print(widget.words);
    }
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
    final textRecognizer = TextRecognizer();
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
                              child: textRecognizer,
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
                                  for (var word in textRecognizer.words) {
                                    await Firestore.instance
                                        .collection('inventory')
                                        .add({
                                      'item': word,
                                      'uid': firebaseUserSnapshot.data.uid,
                                    });
                                  }
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
