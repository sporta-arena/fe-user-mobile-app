import 'package:flutter/material.dart';
import '../widgets/sportago_mark.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'onboarding_screen.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      setState(() => _emailError = "Email tidak boleh kosong");
      isValid = false;
    } else if (email.toLowerCase() != 'demo' && !emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid");
      isValid = false;
    }

    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordError = "Password tidak boleh kosong");
      isValid = false;
    }

    return isValid;
  }

  void _handleLogin() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Login Berhasil! Selamat Datang."),
            backgroundColor: context.c.ok,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Clear the whole stack so Home is the root (can't back into auth flow)
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        if (result.errors != null) {
          setState(() {
            _emailError = result.errors!['email']?.first;
            _passwordError = result.errors!['password']?.first;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Email atau Password salah!"),
            backgroundColor: context.c.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: gayaOverlay(context),
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button — pop if possible, otherwise go back to onboarding
              // (so returning users can still reach Apple/Google options)
              IconButton(
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const OnboardingPage()),
                    );
                  }
                },
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: Icon(Icons.arrow_back_rounded,
                    color: context.c.ink, size: 26),
              ),
              const SizedBox(height: 16),

              // Brand mark
              const SportagoMark(height: 44),
              const SizedBox(height: 32),

              // Heading
              Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: context.c.ink,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "Masuk untuk mulai booking arena olahraga.",
                style: TextStyle(fontSize: 15, color: context.c.inkSoft),
              ),
              const SizedBox(height: 32),

              // Email
              _label("Email"),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: context.c.ink),
                decoration: _fieldDecoration(
                  hint: "you@email.com",
                  icon: Icons.mail_outline_rounded,
                  errorText: _emailError,
                ),
              ),
              const SizedBox(height: 18),

              // Password
              _label("Password"),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                style: TextStyle(color: context.c.ink),
                decoration: _fieldDecoration(
                  hint: "Masukkan password",
                  icon: Icons.lock_outline_rounded,
                  errorText: _passwordError,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: context.c.inkSoft,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _isPasswordVisible = !_isPasswordVisible),
                  ),
                ),
              ),

              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage()),
                    );
                  },
                  child: Text(
                    "Lupa password?",
                    style: TextStyle(
                      color: context.c.inkSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Login button (brand yellow pill)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.accent,
                    disabledBackgroundColor:
                        context.c.accent.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: context.c.onAccent, strokeWidth: 2),
                        )
                      : Text(
                          "Masuk",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.c.onAccent,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 28),

              // Register link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("Belum punya akun? ",
                        style:
                            TextStyle(color: context.c.inkSoft, fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterPage()),
                        );
                      },
                      child: Text(
                        "Daftar",
                        style: TextStyle(
                          color: context.c.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: context.c.ink,
        ),
      );

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: context.c.inkSoft),
      filled: true,
      fillColor: context.c.raised,
      errorText: errorText,
      errorMaxLines: 2,
      prefixIcon: Icon(icon, color: context.c.inkSoft, size: 20),
      suffixIcon: suffix,
      border: border(context.c.line, 1),
      enabledBorder: border(context.c.line, 1),
      focusedBorder: border(context.c.accent, 1.6),
      errorBorder: border(context.c.danger, 1),
      focusedErrorBorder: border(context.c.danger, 1.6),
    );
  }
}
