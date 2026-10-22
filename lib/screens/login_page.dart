import 'package:flutter/material.dart';
import '../utils/tanpa_spasi.dart';
import '../widgets/kepala_foto_auth.dart';
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
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

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

  void _kembali() {
    // Pop kalau bisa, kalau tidak balik ke onboarding (supaya pengguna
    // lama tetap bisa menemukan pilihan masuk lewat Google).
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Dulu: lambang kecil dan judul di atas latar putih polos. Sekarang
    // kepala berfoto yang sama dengan layar Masuk aplikasi mitra, form
    // di kartu putih yang menumpang di tepi bawahnya.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: gayaOverlayKepalaFoto(context),
      child: Scaffold(
        backgroundColor: context.c.surface,
        body: SafeArea(
          top: false,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            physics: const ClampingScrollPhysics(),
            child: Column(
              children: [
                KepalaFotoAuth(
                  judul: 'Selamat datang lagi',
                  onKembali: _kembali,
                ),
                Transform.translate(
                  offset: const Offset(0, -24),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 24),
                        _buildDaftarLink(),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Masuk",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: context.c.ink,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Masuk untuk mulai booking arena olahraga.",
            style: TextStyle(
              fontSize: 14,
              color: context.c.inkSoft,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

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
            inputFormatters: const [TanpaSpasi()],
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
                  color: context.c.inkDim,
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
                padding: const EdgeInsets.symmetric(vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ForgotPasswordPage(),
                  ),
                );
              },
              child: Text(
                "Lupa password?",
                style: TextStyle(
                  color: context.c.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Tombol Masuk: warna dari tema (pekat di terang, aksen di
          // gelap), sama dengan tombol utama di seluruh aplikasi.
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isLoading
                  ? SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        color: context.c.inkDim,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Masuk"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDaftarLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Belum punya akun? ",
          style: TextStyle(color: context.c.inkSoft, fontSize: 14),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const RegisterPage()),
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

  // Garis, isian, dan sudut kolom datang dari tema (input putih
  // bergaris tipis), jadi di sini cukup isi yang khas per kolom.
  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    String? errorText,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      errorText: errorText,
      errorMaxLines: 2,
      prefixIcon: Icon(icon, size: 20),
      suffixIcon: suffix,
    );
  }
}
