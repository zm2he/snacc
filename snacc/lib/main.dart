import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:snacc/root.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await availableCameras();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    onGenerateRoute: (routeSettings) {
      if (routeSettings.isInitialRoute) {
        () async {
          // sign out for demo
          await GoogleSignIn().signOut();
          // sign in user
          final googleUser = await GoogleSignIn().signIn();
          // get auth tokens
          final googleAuth = await googleUser.authentication;
          // get credentials
          final credential = GoogleAuthProvider.getCredential(
            idToken: googleAuth.idToken,
            accessToken: googleAuth.accessToken,
          );
          // register with firebase auth
          final firebaseUser =
              (await FirebaseAuth.instance.signInWithCredential(credential))
                  .user;
          // set app state to home tab if no existing tab exists
          if (!(await Firestore.instance
                  .document('session/${firebaseUser.uid}')
                  .get())
              .data
              .containsKey('navIndex')) {
            await Firestore.instance
                .document('session/${firebaseUser.uid}')
                .setData({'navIndex': 0}, merge: true);
          }
        }();
        // disable system overlays
        SystemChrome.setSystemUIOverlayStyle(
            SystemUiOverlayStyle(statusBarColor: Colors.transparent));
        // fix screen orientation
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      }
      return MaterialPageRoute(builder: (context) {
        switch (routeSettings.name) {
          case '/':
            return Root();
          default:
            return Root();
        }
      });
    },
    theme: ThemeData(
      accentColor: Color(0x80f9be02),
      cardColor: Color(0x9d7cdbd5),
      highlightColor: Colors.transparent,
      primaryColor: Color(0xffff9696),
      splashColor: Color(0x9d7cdbd5).withOpacity(1 / 3),
      textTheme: TextTheme(
        headline: TextStyle(
          fontFamily: 'Istok Web',
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ));
}
