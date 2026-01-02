import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _termsError = false;

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _termsError = false;
    });

    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Nama lengkap wajib diisi");
      isValid = false;
    }

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      setState(() => _emailError = "Email wajib diisi");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid (contoh: user@mail.com)");
      isValid = false;
    }

    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _phoneError = "Nomor HP wajib diisi");
      isValid = false;
    } else if (phone.length < 10 || phone.length > 14) {
      setState(() => _phoneError = "Nomor tidak valid (10-14 digit)");
      isValid = false;
    } else if (!phone.startsWith('08') && !phone.startsWith('62')) {
       setState(() => _phoneError = "Awali dengan 08 atau 62");
       isValid = false;
    }

    final password = _passwordController.text;
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigit = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));

    if (password.isEmpty) {
      setState(() => _passwordError = "Password wajib diisi");
      isValid = false;
    } else if (password.length < 8) {
      setState(() => _passwordError = "Minimal 8 karakter");
      isValid = false;
    } else if (!hasUpper || !hasLower || !hasDigit || !hasSpecial) {
      setState(() => _passwordError = "Wajib ada: Huruf Besar, Kecil, Angka, & Simbol");
      isValid = false;
    }

    if (_confirmPasswordController.text != password) {
      setState(() => _confirmPasswordError = "Password tidak sama");
      isValid = false;
    }

    if (!_agreedToTerms) {
      setState(() => _termsError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap setujui Syarat & Ketentuan")),
      );
      isValid = false;
    }

    return isValid;
  }

  void _handleRegister() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Registrasi Berhasil!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      } else {
        if (result.errors != null) {
          setState(() {
            _nameError = result.errors!['name']?.first;
            _emailError = result.errors!['email']?.first;
            _phoneError = result.errors!['phone']?.first;
            _passwordError = result.errors!['password']?.first;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Registrasi gagal!"),
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
      body: Stack(
        children: [
          // Background gradient header
          Container(
            height: MediaQuery.of(context).size.height * 0.30,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0047FF), Color(0xFF002299)],
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.05,
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // Icon
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_add_alt_1,
                      size: 45,
                      color: Color(0xFF0047FF),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Form Card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Buat Akun Baru",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0047FF),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Lengkapi data diri untuk bergabung di Sporta",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // Name Input
                        _buildLabel("Nama Lengkap"),
                        _buildTextField(
                          controller: _nameController,
                          hint: "John Doe",
                          icon: Icons.person_outline,
                          errorText: _nameError,
                        ),
                        const SizedBox(height: 16),

                        // Email Input
                        _buildLabel("Email Address"),
                        _buildTextField(
                          controller: _emailController,
                          hint: "nama@domain.com",
                          icon: Icons.email_outlined,
                          inputType: TextInputType.emailAddress,
                          errorText: _emailError,
                        ),
                        const SizedBox(height: 16),

                        // Phone Input
                        _buildLabel("Nomor Handphone (WhatsApp)"),
                        _buildTextField(
                          controller: _phoneController,
                          hint: "0812xxxxxxxx",
                          icon: Icons.phone_android_outlined,
                          inputType: TextInputType.phone,
                          errorText: _phoneError,
                          isNumberOnly: true,
                        ),
                        const SizedBox(height: 16),

                        // Password Input
                        _buildLabel("Password"),
                        _buildTextField(
                          controller: _passwordController,
                          hint: "Kombinasi kuat (Min. 8 char)",
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isVisible: _isPasswordVisible,
                          onVisibilityToggle: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                          errorText: _passwordError,
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password Input
                        _buildLabel("Konfirmasi Password"),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          hint: "Ulangi password",
                          icon: Icons.lock_reset,
                          isPassword: true,
                          isVisible: _isConfirmPasswordVisible,
                          onVisibilityToggle: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                          errorText: _confirmPasswordError,
                        ),
                        const SizedBox(height: 20),

                        // Terms & Conditions Checkbox
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                activeColor: const Color(0xFF0047FF),
                                side: BorderSide(
                                  color: _termsError ? Colors.red : Colors.grey,
                                  width: 2,
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    _agreedToTerms = value ?? false;
                                    _termsError = false;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                   // TODO: Navigate to Terms & Conditions
                                },
                                child: RichText(
                                  text: TextSpan(
                                    text: 'Saya menyetujui ',
                                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                                    children: const [
                                      TextSpan(
                                        text: 'Syarat & Ketentuan',
                                        style: TextStyle(
                                          color: Color(0xFF0047FF),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' dan '),
                                      TextSpan(
                                        text: 'Kebijakan Privasi',
                                        style: TextStyle(
                                          color: Color(0xFF0047FF),
                                          fontWeight: FontWeight.bold,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      TextSpan(text: ' Sporta.'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_termsError)
                          const Padding(
                            padding: EdgeInsets.only(left: 34, top: 4),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                "Wajib disetujui untuk melanjutkan",
                                style: TextStyle(color: Colors.red, fontSize: 11),
                              ),
                            ),
                          ),

                        const SizedBox(height: 28),

                        // Register Button
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleRegister,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0047FF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.app_registration, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        "DAFTAR SEKARANG",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("Sudah punya akun? ", style: TextStyle(color: Colors.grey[600])),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          "Masuk",
                          style: TextStyle(
                            color: Color(0xFF0047FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? errorText,
    bool isPassword = false,
    bool isVisible = false,
    VoidCallback? onVisibilityToggle,
    TextInputType inputType = TextInputType.text,
    bool isNumberOnly = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      inputFormatters: isNumberOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : [],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        errorText: errorText,
        errorMaxLines: 2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF0047FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        prefixIcon: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF0047FF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF0047FF), size: 20),
        ),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey[500],
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }
}
