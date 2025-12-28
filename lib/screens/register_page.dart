import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Untuk membatasi input hanya angka
import 'otp_page.dart'; // Pastikan file ini sudah ada (sesuai langkah sebelumnya)

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- 1. CONTROLLERS (Penyimpan Input) ---
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- 2. STATE VARIABLES (Status UI) ---
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreedToTerms = false; // Status Checkbox

  // --- 3. ERROR VARIABLES (Pesan Validasi Merah) ---
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _termsError = false;

  // --- 4. LOGIKA VALIDASI (Strict Mode) ---
  bool _validateInputs() {
    bool isValid = true;
    
    // Reset semua error sebelum cek ulang
    setState(() {
      _nameError = null;
      _emailError = null;
      _phoneError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _termsError = false;
    });

    // A. Validasi Nama
    if (_nameController.text.trim().isEmpty) {
      setState(() => _nameError = "Nama lengkap wajib diisi");
      isValid = false;
    }

    // B. Validasi Email (Regex Domain)
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (email.isEmpty) {
      setState(() => _emailError = "Email wajib diisi");
      isValid = false;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid (contoh: user@mail.com)");
      isValid = false;
    }

    // C. Validasi No HP (Indonesia Format)
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

    // D. Validasi Password (Complexity)
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

    // E. Validasi Konfirmasi Password
    if (_confirmPasswordController.text != password) {
      setState(() => _confirmPasswordError = "Password tidak sama");
      isValid = false;
    }

    // F. Validasi Checkbox Terms
    if (!_agreedToTerms) {
      setState(() => _termsError = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Harap setujui Syarat & Ketentuan")),
      );
      isValid = false;
    }

    return isValid;
  }

  // --- 5. LOGIKA REGISTER & NAVIGASI ---
  void _handleRegister() async {
    // 1. Cek Validasi
    if (!_validateInputs()) return;

    // 2. Loading State
    setState(() => _isLoading = true);

    // 3. Simulasi Request API (2 detik)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      
      // 4. Navigasi ke OTP Page (Membawa No HP)
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpVerificationPage(
            phoneNumber: _phoneController.text, // Kirim data HP ke OTP Page
          ),
        ),
      ); 
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar dengan tombol Back Custom
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context), // Balik ke Login
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // HEADER TEXT
                const Text(
                  "Buat Akun Baru",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0047FF),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  "Lengkapi data diri untuk bergabung di Sporta",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 30),

                // --- FORM INPUTS ---
                
                // 1. Nama
                _buildLabel("Nama Lengkap"),
                _buildTextField(
                  controller: _nameController,
                  hint: "John Doe",
                  icon: Icons.person_outline,
                  errorText: _nameError,
                ),
                const SizedBox(height: 16),

                // 2. Email
                _buildLabel("Email Address"),
                _buildTextField(
                  controller: _emailController,
                  hint: "nama@domain.com",
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress,
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),

                // 3. No HP (Khusus Angka)
                _buildLabel("Nomor Handphone (WhatsApp)"),
                _buildTextField(
                  controller: _phoneController,
                  hint: "0812xxxxxxxx",
                  icon: Icons.phone_android_outlined,
                  inputType: TextInputType.phone,
                  errorText: _phoneError,
                  isNumberOnly: true, // Helper untuk hanya angka
                ),
                const SizedBox(height: 16),

                // 4. Password
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

                // 5. Confirm Password
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

                // --- CHECKBOX TERMS & CONDITIONS ---
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
                          color: _termsError ? Colors.red : Colors.grey, // Merah jika error
                          width: 2,
                        ),
                        onChanged: (value) {
                          setState(() {
                            _agreedToTerms = value ?? false;
                            _termsError = false; // Hapus error saat diklik
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                           // TODO: Navigasi ke halaman Syarat & Ketentuan Webview
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
                // Pesan Error Text Kecil di bawah Checkbox
                if (_termsError)
                  const Padding(
                    padding: EdgeInsets.only(left: 34, top: 4),
                    child: Text(
                      "Wajib disetujui untuk melanjutkan",
                      style: TextStyle(color: Colors.red, fontSize: 11),
                    ),
                  ),

                const SizedBox(height: 30),

                // --- TOMBOL SUBMIT ---
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0047FF),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                          )
                        : const Text(
                            "DAFTAR SEKARANG",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- HELPER WIDGETS (Supaya kode bersih) ---
  
  // 1. Label Text
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  // 2. Reusable TextField
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
      // Filter input jika hanya angka (untuk No HP)
      inputFormatters: isNumberOnly 
          ? [FilteringTextInputFormatter.digitsOnly] 
          : [],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[400]),
        filled: true,
        fillColor: const Color(0xFFF5F7FA),
        
        // Error Styling
        errorText: errorText,
        errorMaxLines: 2,
        
        // Borders
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0047FF), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.0)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
        
        // Icons
        prefixIcon: Icon(icon, color: Colors.grey[500]),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(isVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey[500]),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }
}