import 'package:flutter/material.dart';
import '../widgets/sportago_mark.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'login_page.dart';
import '../services/auth_service.dart';

class ResetPasswordPage extends StatefulWidget {
  final String email;
  final String resetToken;

  const ResetPasswordPage({
    super.key,
    required this.email,
    required this.resetToken,
  });

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;

    setState(() {
      _passwordError = null;
      _confirmPasswordError = null;
    });

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

    return isValid;
  }

  Future<void> _handleResetPassword() async {
    if (!_validateInputs()) return;

    setState(() => _isLoading = true);

    final result = await AuthService.resetPassword(
      email: widget.email,
      resetToken: widget.resetToken,
      password: _passwordController.text,
      passwordConfirmation: _confirmPasswordController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        _showSuccessDialog();
      } else {
        if (result.errors != null) {
          setState(() {
            _passwordError = result.errors!['password']?.first;
          });
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Gagal mereset password"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.c.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: context.c.accent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Password berhasil direset!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: context.c.ink,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Password kamu sudah diperbarui. Silakan login dengan password baru.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.inkSoft,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    // Navigate to login and clear all routes
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    "Masuk sekarang",
                    style: TextStyle(
                      color: context.c.onAccent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: gayaOverlay(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button
                if (Navigator.canPop(context)) ...[
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                    icon: Icon(Icons.arrow_back_rounded,
                        color: context.c.ink, size: 26),
                  ),
                  const SizedBox(height: 16),
                ],

                // Brand mark
                const SportagoMark(height: 40),
                const SizedBox(height: 24),

                // Heading
                Text(
                  "Buat password baru",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: context.c.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Buat password baru yang kuat. Password lama akan dinonaktifkan.",
                  style: TextStyle(
                      fontSize: 15, color: context.c.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 28),

                // Password
                _buildLabel("Password Baru"),
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
                  hint: "Ulangi password baru",
                  icon: Icons.lock_reset_rounded,
                  isPassword: true,
                  isVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () => setState(
                      () => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
                  errorText: _confirmPasswordError,
                ),
                const SizedBox(height: 16),

                // Password requirements
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.c.raised,
                    border: Border.all(color: context.c.line),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Password harus mengandung:",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: context.c.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildRequirement("Minimal 8 karakter"),
                      _buildRequirement("Huruf besar (A-Z)"),
                      _buildRequirement("Huruf kecil (a-z)"),
                      _buildRequirement("Angka (0-9)"),
                      _buildRequirement("Simbol (!@#\$%^&*)"),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Reset button (brand yellow pill)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
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
                            "Simpan password",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.c.onAccent,
                            ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 13,
          color: context.c.ink,
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
  }) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );
    return TextField(
      controller: controller,
      obscureText: isPassword && !isVisible,
      style: TextStyle(color: context.c.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: context.c.inkSoft),
        filled: true,
        fillColor: context.c.raised,
        errorText: errorText,
        errorMaxLines: 2,
        prefixIcon: Icon(icon, color: context.c.inkSoft, size: 20),
        border: border(context.c.line, 1),
        enabledBorder: border(context.c.line, 1),
        focusedBorder: border(context.c.accent, 1.6),
        errorBorder: border(Colors.red.shade400, 1),
        focusedErrorBorder: border(Colors.red.shade400, 1.6),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: context.c.inkSoft,
                  size: 20,
                ),
                onPressed: onVisibilityToggle,
              )
            : null,
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: Row(
        children: [
          Icon(Icons.check_circle,
              size: 14, color: context.c.accent),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: context.c.inkSoft),
          ),
        ],
      ),
    );
  }
}
