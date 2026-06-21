import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'onboarding_screen.dart';
import 'home_page.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';

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
            backgroundColor: Colors.green,
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
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
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
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onDark, size: 26),
              ),
              const SizedBox(height: 16),

              // Brand mark
              Image.asset('assets/sportago_mark.png', height: 44),
              const SizedBox(height: 32),

              // Heading
              const Text(
                "Welcome back",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Masuk untuk mulai booking arena olahraga.",
                style: TextStyle(fontSize: 15, color: AppColors.onDarkMuted),
              ),
              const SizedBox(height: 32),

              // Email
              _label("Email"),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.onDark),
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
                style: const TextStyle(color: AppColors.onDark),
                decoration: _fieldDecoration(
                  hint: "Masukkan password",
                  icon: Icons.lock_outline_rounded,
                  errorText: _passwordError,
                  suffix: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.onDarkMuted,
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
                  child: const Text(
                    "Lupa password?",
                    style: TextStyle(
                      color: AppColors.onDarkMuted,
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
                    backgroundColor: AppColors.brandYellow,
                    disabledBackgroundColor:
                        AppColors.brandYellow.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              color: AppColors.ink, strokeWidth: 2),
                        )
                      : const Text(
                          "Masuk",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
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
                    const Text("Belum punya akun? ",
                        style:
                            TextStyle(color: AppColors.onDarkMuted, fontSize: 14)),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        "Daftar",
                        style: TextStyle(
                          color: AppColors.brandYellow,
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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.onDark,
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
      hintStyle: const TextStyle(color: AppColors.onDarkMuted),
      filled: true,
      fillColor: AppColors.surface,
      errorText: errorText,
      errorMaxLines: 2,
      prefixIcon: Icon(icon, color: AppColors.onDarkMuted, size: 20),
      suffixIcon: suffix,
      border: border(AppColors.surfaceBorder, 1),
      enabledBorder: border(AppColors.surfaceBorder, 1),
      focusedBorder: border(AppColors.brandYellow, 1.6),
      errorBorder: border(Colors.red.shade400, 1),
      focusedErrorBorder: border(Colors.red.shade400, 1.6),
    );
  }
}
