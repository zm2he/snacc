import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:snacc/Inventory.dart';
import 'package:snacc/Recipes.dart';
import 'package:snacc/cart.dart';
import 'package:snacc/home.dart';

class Root extends StatelessWidget {
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
              return Scaffold(
                body: IndexedStack(
                  children: [
                    Home(),
                    Inventory(),
                    Recipes(),
                    Cart(),
                  ],
                  index: sessionSnapshot.data['navIndex'],
                ),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: sessionSnapshot.data['navIndex'],
                  items: [
                    for (var content in [
                      {'iconData': Icons.home, 'text': 'Home'},
                      {'iconData': Icons.list, 'text': 'Inventory'},
                      {'iconData': Icons.receipt, 'text': 'Recipes'},
                      {'iconData': Icons.shopping_cart, 'text': 'Cart'},
                    ])
                      BottomNavigationBarItem(
                        icon: Icon(
                          content['iconData'],
                          color: Theme.of(context).cardColor,
                        ),
                        title: Text(content['text'],
                            style: Theme.of(context)
                                .textTheme
                                .button
                                .copyWith(color: Theme.of(context).cardColor)),
                      ),
                  ],
                  onTap: (index) async {
                    await sink.setData({'navIndex': index}, merge: true);
                  },
                ),
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
