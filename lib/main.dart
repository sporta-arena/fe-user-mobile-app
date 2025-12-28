import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sporta App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Arial', // Sesuai design
      ),
      home: const OnboardingPage(),
      debugShowCheckedModeBanner: false, // Hilangkan banner debug
    );
  }
}
