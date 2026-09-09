import 'package:flutter/material.dart';
import '../widgets/sportago_mark.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'otp_page.dart';
import '../services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() => _emailError = null);

    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      setState(() => _emailError = "Email wajib diisi");
      return;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid");
      return;
    }

    setState(() => _isLoading = true);

    final result = await AuthService.forgotPassword(email: email);

    if (mounted) {
      setState(() => _isLoading = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Kode OTP telah dikirim ke email Anda"),
            backgroundColor: context.c.ok,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Navigate to OTP verification page for password reset
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => OtpVerificationPage(
              email: email,
              otpType: OtpType.passwordReset,
            ),
          ),
        );
      } else {
        if (result.errors != null && result.errors!['email'] != null) {
          setState(() => _emailError = result.errors!['email']!.first);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Gagal mengirim kode OTP"),
            backgroundColor: context.c.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, double w) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: c, width: w),
        );

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
                  "Lupa password?",
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: context.c.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Masukkan email yang terdaftar, kami kirim kode OTP untuk verifikasi.",
                  style: TextStyle(
                      fontSize: 15, color: context.c.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 32),

                // Email
                Text(
                  "Email",
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: context.c.ink),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: context.c.ink),
                  decoration: InputDecoration(
                    hintText: "nama@domain.com",
                    hintStyle: TextStyle(color: context.c.inkSoft),
                    filled: true,
                    fillColor: context.c.raised,
                    errorText: _emailError,
                    prefixIcon: Icon(Icons.mail_outline_rounded,
                        color: context.c.inkSoft, size: 20),
                    border: border(context.c.line, 1),
                    enabledBorder: border(context.c.line, 1),
                    focusedBorder: border(context.c.accent, 1.6),
                    errorBorder: border(context.c.danger, 1),
                    focusedErrorBorder: border(context.c.danger, 1.6),
                  ),
                ),
                const SizedBox(height: 28),

                // Submit button (brand yellow pill)
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
                            "Kirim kode OTP",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.c.onAccent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 20),

                // Info text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: context.c.inkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Kode OTP dikirim ke email kamu dan berlaku selama 10 menit.",
                        style: TextStyle(
                          fontSize: 12,
                          color: context.c.inkSoft.withValues(alpha: 0.8),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Back to login
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Kembali ke Login",
                      style: TextStyle(
                        color: context.c.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
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
}
