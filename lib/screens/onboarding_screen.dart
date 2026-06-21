import 'package:flutter/material.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  Future<void> _continueWithEmail() async {
    // Mark onboarding as seen so it won't show again
    await AuthService.setOnboardingSeen();

    if (mounted) {
      // push (not replace) so Login can back out to this onboarding screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  void _comingSoon(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Continue with $provider belum tersedia'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. HERO BACKGROUND PHOTO ---
          Image.asset(
            'assets/onboarding_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),

          // --- 2. GRADIENT FADE TO BLACK ---
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 0.62, 1.0],
                colors: [
                  Colors.transparent,
                  Colors.transparent,
                  Color(0xCC000000),
                  Colors.black,
                ],
              ),
            ),
          ),

          // --- 3. CONTENT ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Sportago "S" mark
                  Image.asset(
                    'assets/sportago_mark.png',
                    height: 48,
                  ),
                  const SizedBox(height: 16),

                  // Tagline
                  const Text(
                    'Premium sports venue at your fingertips. '
                    'Book futsal, Badminton, Basketball courts in seconds.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Continue with Apple
                  _AuthButton(
                    label: 'Continue with Apple',
                    background: const Color(0xFF141414),
                    foreground: Colors.white,
                    leading: const Icon(Icons.apple,
                        color: Colors.white, size: 22),
                    onPressed: () => _comingSoon('Apple'),
                  ),
                  const SizedBox(height: 8),

                  // Continue with Google
                  _AuthButton(
                    label: 'Continue with Google',
                    background: Colors.white,
                    foreground: const Color(0xFF141414),
                    leading: Image.asset('assets/google_logo.png', height: 20),
                    onPressed: () => _comingSoon('Google'),
                  ),
                  const SizedBox(height: 8),

                  // Continue with email
                  _AuthButton(
                    label: 'Continue with email',
                    background: Colors.white.withValues(alpha: 0.14),
                    foreground: Colors.white,
                    onPressed: _continueWithEmail,
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final Widget? leading;
  final VoidCallback onPressed;

  const _AuthButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: 10),
            ],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
