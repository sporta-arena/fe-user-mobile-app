import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'otp_page.dart';
import '../services/auth_service.dart';
import '../constants/colors.dart';

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
            content: Text(result.message ?? "Kode OTP telah dikirim ke email Anda"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to OTP verification page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              email: _emailController.text.trim(),
              otpType: OtpType.registration,
            ),
          ),
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
      backgroundColor: AppColors.bg,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                padding: EdgeInsets.zero,
                alignment: Alignment.centerLeft,
                icon: const Icon(Icons.arrow_back_rounded,
                    color: AppColors.onDark, size: 26),
              ),
              const SizedBox(height: 16),

              // Brand mark
              Image.asset('assets/sportago_mark.png', height: 40),
              const SizedBox(height: 24),

              // Heading
              const Text(
                "Buat akun",
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: AppColors.onDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Lengkapi data diri untuk bergabung di Sportago.",
                style: TextStyle(fontSize: 15, color: AppColors.onDarkMuted),
              ),
              const SizedBox(height: 28),

              // Name
              _buildLabel("Nama Lengkap"),
              _buildTextField(
                controller: _nameController,
                hint: "John Doe",
                icon: Icons.person_outline_rounded,
                errorText: _nameError,
              ),
              const SizedBox(height: 16),

              // Email
              _buildLabel("Email"),
              _buildTextField(
                controller: _emailController,
                hint: "nama@domain.com",
                icon: Icons.mail_outline_rounded,
                inputType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              const SizedBox(height: 16),

              // Phone
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

              // Password
              _buildLabel("Password"),
              _buildTextField(
                controller: _passwordController,
                hint: "Kombinasi kuat (Min. 8 char)",
                icon: Icons.lock_outline_rounded,
                isPassword: true,
                isVisible: _isPasswordVisible,
                onVisibilityToggle: () =>
                    setState(() => _isPasswordVisible = !_isPasswordVisible),
                errorText: _passwordError,
              ),
              const SizedBox(height: 16),

              // Confirm Password
              _buildLabel("Konfirmasi Password"),
              _buildTextField(
                controller: _confirmPasswordController,
                hint: "Ulangi password",
                icon: Icons.lock_reset_rounded,
                isPassword: true,
                isVisible: _isConfirmPasswordVisible,
                onVisibilityToggle: () => setState(
                    () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                errorText: _confirmPasswordError,
              ),
              const SizedBox(height: 20),

              // Terms & Conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.brandYellow,
                      checkColor: AppColors.ink,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      side: BorderSide(
                        color: _termsError ? Colors.red : AppColors.surfaceBorder,
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
                        text: const TextSpan(
                          text: 'Saya menyetujui ',
                          style: TextStyle(
                              color: AppColors.onDarkMuted, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Syarat & Ketentuan',
                              style: TextStyle(
                                color: AppColors.brandYellow,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' dan '),
                            TextSpan(
                              text: 'Kebijakan Privasi',
                              style: TextStyle(
                                color: AppColors.brandYellow,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: ' Sportago.'),
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
                  child: Text(
                    "Wajib disetujui untuk melanjutkan",
                    style: TextStyle(color: Colors.red, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 28),

              // Register button (brand yellow pill)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                          "Daftar sekarang",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Login link
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Sudah punya akun? ",
                        style: TextStyle(
                            color: AppColors.onDarkMuted, fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        "Masuk",
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: AppColors.onDark,
        ),
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
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      keyboardType: inputType,
      style: const TextStyle(color: AppColors.onDark),
      inputFormatters:
          isNumberOnly ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.onDarkMuted),
        filled: true,
        fillColor: AppColors.surface,
        errorText: errorText,
        errorMaxLines: 2,
        prefixIcon: Icon(icon, color: AppColors.onDarkMuted, size: 20),
        border: border(AppColors.surfaceBorder, 1),
        enabledBorder: border(AppColors.surfaceBorder, 1),
        focusedBorder: border(AppColors.brandYellow, 1.6),
        errorBorder: border(Colors.red.shade400, 1),
        focusedErrorBorder: border(Colors.red.shade400, 1.6),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.onDarkMuted,
                  size: 20,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }
}
