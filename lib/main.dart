import 'package:flutter/material.dart';

import 'package:flutter/services.dart';

import 'login_screen.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: const Color.fromARGB(255, 225, 220, 220),
      ),
      home: LoginScreen(),
    );
  }
}
