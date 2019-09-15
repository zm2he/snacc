import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_camera_ml_vision/flutter_camera_ml_vision.dart';
import 'package:url_launcher/url_launcher.dart';

Future main() async {
  SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  await SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  return runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Home(),
  ));
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<bool> _expanded;
  String _query;
  List<Map<String, dynamic>> _recipes;

  @override
  void initState() {
    super.initState();
    _expanded = [];
    _query = '';
    _recipes = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        builder: (context, recipesSnapshot) {
          if (recipesSnapshot.hasData &&
              recipesSnapshot.data.length > _expanded.length) {
            _expanded.addAll(List<bool>.filled(
                recipesSnapshot.data.length - _expanded.length, false));
          }
          return CustomScrollView(slivers: [
            SliverAppBar(
              expandedHeight: 5 * MediaQuery.of(context).size.height / 6,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('snacc'.toUpperCase()),
                background: StreamBuilder<QuerySnapshot>(
                    builder: (context, inventoryQuerySnapshot) {
                      List<DocumentSnapshot> inventorySnapshots;
                      if (inventoryQuerySnapshot.hasData) {
                        inventorySnapshots =
                            inventoryQuerySnapshot.data.documents;
                      } else {
                        return LinearProgressIndicator();
                      }
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            for (var inventorySnapshot in inventorySnapshots)
                              ListTile(
                                title: Wrap(
                                  children: [
                                    for (var key in [
                                      'calories',
                                      'carbs',
                                      'fat',
                                      'fiber',
                                      'protein'
                                    ])
                                      Chip(
                                        backgroundColor: Colors.white,
                                        label: Text(
                                            '$key ${inventorySnapshot.data[key]}'),
                                      ),
                                  ],
                                  spacing: 6,
                                ),
                                subtitle: Text(
                                  inventorySnapshot.data['label'],
                                  style: Theme.of(context)
                                      .primaryTextTheme
                                      .body1
                                      .copyWith(color: Colors.white),
                                ),
                              ),
                          ],
                        ),
                        padding: EdgeInsets.all(56).copyWith(right: 12),
                      );
                    },
                    stream:
                        Firestore.instance.collection('inventory').snapshots()),
              ),
            ),
            if (recipesSnapshot.hasData)
              SliverList(
                  delegate: SliverChildListDelegate([
                ExpansionPanelList(
                  children: [
                    for (int index = 0;
                        index < recipesSnapshot.data.length;
                        index++)
                      ExpansionPanel(
                        body: Column(
                          children: [
                            Wrap(
                              children: [
                                for (var caution in recipesSnapshot.data[index]
                                    ['cautions'])
                                  Chip(
                                    backgroundColor: Colors.deepOrangeAccent
                                        .withOpacity(.33),
                                    label: Text(caution),
                                  ),
                                for (var dietLabel in recipesSnapshot
                                    .data[index]['dietLabels'])
                                  Chip(
                                      backgroundColor:
                                          Colors.red.withOpacity(.25),
                                      label: Text(dietLabel)),
                                for (var healthLabel in recipesSnapshot
                                    .data[index]['healthLabels'])
                                  Chip(
                                    backgroundColor: Colors.lightGreenAccent
                                        .withOpacity(.33),
                                    label: Text(healthLabel),
                                  ),
                              ],
                              spacing: 6,
                            ),
                            ListTile(
                              leading: Icon(Icons.whatshot),
                              title: Text((recipesSnapshot.data[index]
                                      ['calories'] as double)
                                  .toInt()
                                  .toString()),
                              subtitle: Text('Calories'),
                            ),
                            ExpansionTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('Nutrition Facts'),
                              children: [
                                for (var totalNutrient in (recipesSnapshot
                                        .data[index]['totalNutrients'] as Map)
                                    .values)
                                  ListTile(
                                    dense: true,
                                    subtitle: Text(totalNutrient['label']),
                                    title: Text(
                                        '${(totalNutrient['quantity'] as double).toInt().toString()} ${totalNutrient['unit']}'),
                                  ),
                              ],
                            ),
                            ExpansionTile(
                              leading: Icon(Icons.info_outline),
                              title: Text('Daily Values'),
                              children: [
                                for (var totalDaily in (recipesSnapshot
                                        .data[index]['totalDaily'] as Map)
                                    .values)
                                  ListTile(
                                    dense: true,
                                    subtitle: Text(totalDaily['label']),
                                    title: Text(
                                        '${(totalDaily['quantity'] as double).toInt().toString()} ${totalDaily['unit']}'),
                                  ),
                              ],
                            ),
                            Divider(),
                            ListTile(
                              leading: Icon(Icons.link),
                              onTap: () async {
                                final url = recipesSnapshot.data[index]['url'];
                                if (await canLaunch(url)) {
                                  await launch(url);
                                } else {
                                  throw 'Failed to launch $url';
                                }
                              },
                              subtitle: Text('Source'),
                              title:
                                  Text(recipesSnapshot.data[index]['source']),
                            ),
                            ExpansionTile(
                              leading: Icon(Icons.view_list),
                              title: Text('Ingredients'),
                              children: [
                                for (var ingredientLine in recipesSnapshot
                                    .data[index]['ingredientLines'])
                                  ListTile(
                                    dense: true,
                                    leading: Icon(Icons.add_circle_outline),
                                    title: Text(ingredientLine),
                                  ),
                                // TODO: add order button to order missing ingredients
                              ],
                            ),
                            Dismissible(
                              key: ValueKey(
                                  recipesSnapshot.data[index]['label']),
                              background: Container(color: Colors.red),
                              child: ListTile(
                                dense: true,
                                leading: Icon(Icons.thumb_down),
                                trailing: Icon(Icons.thumb_up),
                              ),
                              onDismissed: (direction) {
                                switch (direction) {
                                  case DismissDirection.startToEnd:
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                        content:
                                            Text('We will adjust your feed')));
                                    break;
                                  case DismissDirection.endToStart:
                                    Scaffold.of(context).showSnackBar(SnackBar(
                                        content: Text(
                                            'You will see more of ${recipesSnapshot.data[index]['label']}')));
                                    break;
                                  default:
                                    break;
                                }
                              },
                              secondaryBackground:
                                  Container(color: Colors.green),
                            ),
                          ],
                          mainAxisSize: MainAxisSize.min,
                        ),
                        canTapOnHeader: true,
                        headerBuilder: (context, expanded) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                  recipesSnapshot.data[index]['image']),
                            ),
                            title: Text(recipesSnapshot.data[index]['label']),
                          );
                        },
                        isExpanded: _expanded[index],
                      ),
                  ],
                  expansionCallback: (index, expanded) {
                    setState(() {
                      _expanded[index] = !expanded;
                    });
                  },
                )
              ])),
          ]);
        },
        future: Future.sync(() async {
          final documents =
              (await Firestore.instance.collection('inventory').getDocuments())
                  .documents;
          final query = documents.map((document) {
            return document.data['item'];
          }).join(' ');
          if (_query == query) {
            return _recipes;
          } else {
            _query = query;
          }
          final response = await Dio()
              .get('https://api.edamam.com/search', queryParameters: {
            'app_id': '1ff9eda8',
            'app_key': '97ff66091c23d2f620d8dddfad2ca8f2',
            'q': query,
          });
          _recipes = (response.data['hits'] as List)
              .map((hit) {
                return hit['recipe'];
              })
              .toList()
              .cast<Map<String, dynamic>>();
          print(_recipes);
          return _recipes;
        }),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.add),
        label: Text('add to inventory'.toUpperCase()),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
            return Camera();
          }));
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}

//class _HomeState extends State<Home> {
//  List<bool> _expanded;
//
//  @override
//  void initState() {
//    super.initState();
//    _expanded = [];
//  }
//
//  @override
//  Widget build(BuildContext context) {
//    return Scaffold(
//      body: StreamBuilder<QuerySnapshot>(
//        builder: (context, recipesQuerySnapshot) {
//          List<DocumentSnapshot> recipesSnapshot;
//          if (recipesQuerySnapshot.hasData) {
//            recipesSnapshot = recipesQuerySnapshot.data.documents;
//          }
//          return CustomScrollView(slivers: [
//            SliverAppBar(
//              expandedHeight: MediaQuery.of(context).size.height / 6,
//              flexibleSpace:
//                  FlexibleSpaceBar(title: Text('snacc'.toUpperCase())),
//            ),
//            if (recipesSnapshot != null)
//              SliverList(
//                  delegate: SliverChildListDelegate([
//                ExpansionPanelList(
//                  children: [
//                    for (int index = 0; index < recipesSnapshot.length; index++)
//                      ExpansionPanel(
//                        body: Container(),
//                        canTapOnHeader: true,
//                        headerBuilder: (context, expanded) {
//                          return ListTile(
//                            leading: CircleAvatar(
//                              backgroundImage: NetworkImage(
//                                  recipesSnapshot[index]['image']),
//                            ),
//                            title: Text(recipesSnapshot[index]['label']),
//                          );
//                        },
//                        isExpanded: _expanded[index],
//                      ),
//                  ],
//                  expansionCallback: (index, expanded) {
//                    setState(() {
//                      _expanded[index] = !expanded;
//                    });
//                  },
//                )
//              ])),
//          ]);
//        },
//        stream: Firestore.instance.collection('recipes').snapshots(),
//      ),
//      floatingActionButton: FloatingActionButton.extended(
//        icon: Icon(Icons.add),
//        label: Text('add to inventory'.toUpperCase()),
//        onPressed: () {
//          Navigator.of(context).push(MaterialPageRoute(builder: (context) {
//            return Camera();
//          }));
//        },
//      ),
//      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
//    );
//  }
//}

class Camera extends StatefulWidget {
  @override
  _CameraState createState() => _CameraState();
}

class _CameraState extends State<Camera> {
  List<String> _visionTextWords;

  @override
  void initState() {
    super.initState();
    _visionTextWords = [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          CameraMlVision<VisionText>(
            detector: FirebaseVision.instance.textRecognizer().processImage,
            onResult: (visionText) {
              _visionTextWords.clear();
              for (var line in visionText.text.split('\n')) {
                for (var word in line.split(' ')) {
                  _visionTextWords.add(word.toLowerCase());
                }
              }
            },
            resolution: ResolutionPreset.veryHigh,
          ),
        ],
        fit: StackFit.expand,
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: Icon(Icons.camera_alt),
        label: Text('capture'.toUpperCase()),
        onPressed: () async {
          for (var word in _visionTextWords) {
            await Firestore.instance
                .collection('inventory')
                .add({'item': word});
          }
          await Firestore.instance
              .collection('inventory')
              .add({'item': 'sentinel'});
          Navigator.of(context).pop();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
