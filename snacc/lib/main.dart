import 'package:flutter/material.dart';
import 'package:snacc/root.dart';

void main() => runApp(MaterialApp(
  debugShowCheckedModeBanner: false,
  routes: {
    '/': (context) => Root(),
  },
));

