import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/sportago_mark.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'home_page.dart';
import 'reset_password_page.dart';
import '../services/auth_service.dart';

enum OtpType {
  registration,
  passwordReset,
}

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final OtpType otpType;

  const OtpVerificationPage({
    super.key,
    required this.email,
    this.otpType = OtpType.registration,
  });

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isResending = false;
  int _resendCountdown = 0;
  Timer? _countdownTimer;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    setState(() => _resendCountdown = 60);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    final inputCode = _pinController.text;

    if (inputCode.length != 6) {
      setState(() => _errorMessage = "Masukkan 6 digit kode OTP");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (widget.otpType == OtpType.registration) {
      // Verify registration OTP
      final result = await AuthService.verifyOtp(
        email: widget.email,
        code: inputCode,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? "Verifikasi berhasil!"),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to Home, clear all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomePage()),
            (route) => false,
          );
        } else {
          setState(() => _errorMessage = result.message ?? "Kode OTP salah");
          _pinController.clear();
        }
      }
    } else {
      // Verify password reset OTP
      final result = await AuthService.verifyResetOtp(
        email: widget.email,
        code: inputCode,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success) {
          final resetToken = result.data?['reset_token'];

          // Navigate to Reset Password page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ResetPasswordPage(
                email: widget.email,
                resetToken: resetToken,
              ),
            ),
          );
        } else {
          setState(() => _errorMessage = result.message ?? "Kode OTP salah");
          _pinController.clear();
        }
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0 || _isResending) return;

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    final result = widget.otpType == OtpType.registration
        ? await AuthService.resendOtp(email: widget.email)
        : await AuthService.forgotPassword(email: widget.email);

    if (mounted) {
      setState(() => _isResending = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Kode OTP baru telah dikirim"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _startResendCountdown();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Gagal mengirim ulang kode"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultPinTheme = PinTheme(
      width: 48,
      height: 56,
      textStyle: TextStyle(
        fontSize: 22,
        color: context.c.ink,
        fontWeight: FontWeight.w700,
      ),
      decoration: BoxDecoration(
        color: context.c.raised,
        border: Border.all(color: context.c.line),
        borderRadius: BorderRadius.circular(14),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: context.c.accent, width: 1.6),
      borderRadius: BorderRadius.circular(14),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.red.shade400, width: 1.6),
      borderRadius: BorderRadius.circular(14),
    );

    final submittedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: context.c.line),
      borderRadius: BorderRadius.circular(14),
    );

    final isPasswordReset = widget.otpType == OtpType.passwordReset;
    final title = isPasswordReset ? "Reset Password" : "Verifikasi Email";
    final subtitle = isPasswordReset
        ? "Masukkan kode 6 digit yang dikirim ke email kamu untuk mereset password."
        : "Masukkan kode 6 digit yang dikirim ke email kamu untuk verifikasi akun.";

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
                // Back button (only when there's somewhere to go back to)
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
                  title,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: context.c.ink,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(
                      fontSize: 15, color: context.c.inkSoft, height: 1.4),
                ),
                const SizedBox(height: 6),

                // Email
                Text(
                  widget.email,
                  style: TextStyle(
                    fontSize: 15,
                    color: context.c.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 32),

                // OTP Input
                Pinput(
                  length: 6,
                  controller: _pinController,
                  defaultPinTheme: defaultPinTheme,
                  focusedPinTheme: focusedPinTheme,
                  submittedPinTheme: submittedPinTheme,
                  errorPinTheme: errorPinTheme,
                  pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                  showCursor: true,
                  cursor: Center(
                    child: Container(
                      width: 2,
                      height: 24,
                      color: context.c.accent,
                    ),
                  ),
                  onCompleted: (pin) => _verifyOtp(),
                  onChanged: (_) {
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                ),

                // Error message
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],

                const SizedBox(height: 32),

                // Verify button (brand yellow pill)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
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
                            "Verifikasi",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: context.c.onAccent,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Resend OTP
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Tidak menerima kode? ",
                        style:
                            TextStyle(color: context.c.inkSoft, fontSize: 14),
                      ),
                      if (_resendCountdown > 0)
                        Text(
                          "Tunggu ${_resendCountdown}s",
                          style: TextStyle(
                            color: context.c.inkSoft,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        )
                      else
                        GestureDetector(
                          onTap: _isResending ? null : _resendOtp,
                          child: _isResending
                              ? SizedBox(
                                  height: 16,
                                  width: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: context.c.accent),
                                )
                              : Text(
                                  "Kirim Ulang",
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
                const SizedBox(height: 28),

                // Info text
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: context.c.inkSoft),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Kode OTP kadaluarsa dalam 10 menit. Cek folder spam jika email tidak ditemukan.",
                        style: TextStyle(
                          fontSize: 12,
                          color: context.c.inkSoft.withValues(alpha: 0.8),
                          height: 1.4,
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
