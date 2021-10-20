import 'package:flutter/material.dart';

import './pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  final String title = "Sub Zero";
  final String bleDeviceName = "SubZero-D2";
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: title,
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(title: title),
      debugShowCheckedModeBanner: false,
    );
  }
}
