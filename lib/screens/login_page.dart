import 'package:flutter/material.dart';
import 'register_page.dart';
import 'forgot_password_page.dart';
import 'home_page.dart'; // <--- PASTIKAN SUDAH ADA FILE home_page.dart

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // --- CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;

  // --- LOGIKA VALIDASI ---
  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    // Validasi Email
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      setState(() => _emailError = "Email tidak boleh kosong");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid");
      isValid = false;
    }

    // Validasi Password
    final password = _passwordController.text;
    bool hasMinLength = password.length >= 8;
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasLowercase = password.contains(RegExp(r'[a-z]'));
    bool hasDigits    = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial   = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    if (password.isEmpty) {
      setState(() => _passwordError = "Password tidak boleh kosong");
      isValid = false;
    } else if (!hasMinLength) {
      setState(() => _passwordError = "Minimal 8 karakter");
      isValid = false;
    } else {
      List<String> missing = [];
      if (!hasUppercase) missing.add("Huruf Besar");
      if (!hasLowercase) missing.add("Huruf Kecil");
      if (!hasDigits) missing.add("Angka");
      if (!hasSpecial) missing.add("Simbol");

      if (missing.isNotEmpty) {
        setState(() {
          _passwordError = "Kurang: ${missing.join(', ')}";
        });
        isValid = false;
      }
    }

    return isValid;
  }

  // --- FUNGSI LOGIN (HARDCODED) ---
  void _handleLogin() async {
    // 1. Cek Validasi Input dulu
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    // 2. Simulasi Loading (2 detik)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      // --- 3. CEK KREDENSIAL (HARDCODE) ---
      // Kita tentukan akun rahasia untuk testing
      String inputEmail = _emailController.text.trim();
      String inputPassword = _passwordController.text;

      if (inputEmail == "okta@test.com" && inputPassword == "Okta1234#") {
        
        // --- A. JIKA BENAR ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Login Berhasil! Selamat Datang."),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Pindah ke Dashboard (User tidak bisa back ke login)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );

      } else {
        
        // --- B. JIKA SALAH ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email atau Password salah!"),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                // HEADER LOGO
                Container(
                  height: 80,
                  width: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF0F5FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(Icons.sports_soccer, size: 40, color: Color(0xFF0047FF)),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Selamat Datang!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0047FF),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Masuk untuk mulai booking arena",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                
                const SizedBox(height: 40),

                // INPUT EMAIL
                const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: "user@sporta.com", // Hint biar gampang inget
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    errorText: _emailError,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0047FF), width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                  ),
                ),

                const SizedBox(height: 20),

                // INPUT PASSWORD
                const Text("Password", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Sporta123!", // Hint biar gampang inget
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    filled: true,
                    fillColor: const Color(0xFFF5F7FA),
                    errorText: _passwordError,
                    errorMaxLines: 2,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0047FF), width: 1.5)),
                    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
                    focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
                    prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[500]),
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500]),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),

                // TOMBOL LUPA PASSWORD
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordPage()),
                      );
                    },
                    child: const Text(
                      "Lupa Password?",
                      style: TextStyle(
                        color: Color(0xFF0047FF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // TOMBOL LOGIN
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            "MASUK",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 30),

                // FOOTER DAFTAR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Belum punya akun? ", style: TextStyle(color: Colors.grey[600])),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterPage()),
                        );
                      },
                      child: const Text(
                        "Daftar Sekarang",
                        style: TextStyle(
                          color: Color(0xFF0047FF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}