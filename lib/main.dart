import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_page.dart';
import 'screens/home_page.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sportago',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Archivo',
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // Add a small delay for splash screen visibility
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    // Check if user has seen onboarding
    final hasSeenOnboarding = await AuthService.hasSeenOnboarding();

    if (!hasSeenOnboarding) {
      // First time user - show onboarding
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
      return;
    }

    // Check if user is logged in (token exists and valid)
    final isLoggedIn = await AuthService.initializeAuth();

    if (!mounted) return;

    if (isLoggedIn) {
      // User is logged in - go to home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      // User not logged in - go to login
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      // Sportago brand yellow (from Figma splash design)
      backgroundColor: const Color(0xFFFFFF21),
      body: Center(
        child: Image.asset(
          'assets/sportago_logo.png',
          width: screenWidth * 0.6,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
