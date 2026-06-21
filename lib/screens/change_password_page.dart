import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // --- CONTROLLERS ---
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // --- STATE VISIBILITY (Mata) ---
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- FUNGSI LUPA PASSWORD ---
  void _showForgotPasswordSheet() {
    final TextEditingController emailController = TextEditingController(text: "okta@test.com");
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBorder,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Icon
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.brandYellow.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset,
                        color: AppColors.brandYellow,
                        size: 40,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  const Center(
                    child: Text(
                      "Reset Password",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Center(
                    child: Text(
                      "Kami akan mengirimkan link reset password ke email terdaftar",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.onDarkMuted,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Email field
                  const Text(
                    "Email Terdaftar",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: AppColors.onDark),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.email_outlined,
                        color: AppColors.brandYellow,
                      ),
                      hintText: "Masukkan email",
                      hintStyle: const TextStyle(color: AppColors.onDarkMuted),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.brandYellow),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              if (emailController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Email tidak boleh kosong"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              setSheetState(() => isLoading = true);
                              await Future.delayed(const Duration(seconds: 2));

                              if (context.mounted) {
                                Navigator.pop(context);
                                _showResetSuccessDialog(emailController.text);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandYellow,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: AppColors.ink,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              "Kirim Link Reset",
                              style: TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showResetSuccessDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mark_email_read_outlined,
                  color: Colors.green.shade400,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Email Terkirim!",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onDark,
                ),
              ),
              const SizedBox(height: 12),

              // Description
              const Text(
                "Link reset password telah dikirim ke:",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onDarkMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Silakan cek inbox atau folder spam email kamu.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.onDarkMuted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandYellow,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Mengerti",
                    style: TextStyle(
                      color: AppColors.ink,
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

  // --- FUNGSI GANTI PASSWORD ---
  void _changePassword() async {
    // 1. Validasi Input Kosong
    if (_currentPassController.text.isEmpty || 
        _newPassController.text.isEmpty || 
        _confirmPassController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Semua kolom wajib diisi!"), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // 2. Validasi Kesamaan Password Baru
    if (_newPassController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password baru tidak cocok!"), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // 3. Validasi Panjang Password (Opsional)
    if (_newPassController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password minimal 6 karakter"), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // 4. Validasi Password Lama vs Baru (tidak boleh sama)
    if (_currentPassController.text == _newPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password baru harus berbeda dari password lama!"), 
          backgroundColor: Colors.red
        ),
      );
      return;
    }

    // 5. Proses Simpan (Simulasi)
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2)); // Simulasi API
    
    if (mounted) {
      setState(() => _isLoading = false);
      
      // Sukses
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password berhasil diubah!"), 
          backgroundColor: Colors.green
        ),
      );
      Navigator.pop(context); // Kembali ke Edit Profile
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          "Ganti Password",
          style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.surfaceBorder,
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: AppColors.brandYellow,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Buat password baru yang kuat dan sulit ditebak agar akunmu tetap aman.",
                      style: TextStyle(
                        color: AppColors.onDark,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // 1. Password Lama
            _buildPasswordField(
              label: "Password Lama",
              controller: _currentPassController,
              isObscure: _obscureCurrent,
              onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
              icon: Icons.lock_outline,
            ),
            
            const SizedBox(height: 20),

            // 2. Password Baru
            _buildPasswordField(
              label: "Password Baru",
              controller: _newPassController,
              isObscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
              icon: Icons.lock,
            ),
            
            const SizedBox(height: 20),

            // 3. Konfirmasi Password Baru
            _buildPasswordField(
              label: "Konfirmasi Password Baru",
              controller: _confirmPassController,
              isObscure: _obscureConfirm,
              onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
              icon: Icons.lock_reset,
            ),

            const SizedBox(height: 30),

            // Password Requirements
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Syarat Password:",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.onDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRequirement("Minimal 6 karakter", _newPassController.text.length >= 6),
                  _buildRequirement("Berbeda dari password lama", _currentPassController.text != _newPassController.text && _newPassController.text.isNotEmpty),
                  _buildRequirement("Konfirmasi password cocok", _newPassController.text == _confirmPassController.text && _confirmPassController.text.isNotEmpty),
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // Tombol Simpan
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandYellow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999)
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.ink,
                        strokeWidth: 2
                      )
                    )
                  : const Text(
                      "UBAH PASSWORD",
                      style: TextStyle(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                        fontSize: 16
                      )
                    ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            Center(
              child: TextButton(
                onPressed: () => _showForgotPasswordSheet(),
                child: const Text(
                  "Lupa Password Lama?",
                  style: TextStyle(
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- WIDGET INPUT PASSWORD (Reusable) ---
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool isObscure,
    required VoidCallback onToggle,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onDark
          )
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            obscureText: isObscure,
            onChanged: (value) => setState(() {}), // Trigger rebuild for requirements
            style: const TextStyle(color: AppColors.onDark),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.brandYellow),
              suffixIcon: IconButton(
                icon: Icon(
                  isObscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.onDarkMuted,
                ),
                onPressed: onToggle,
              ),
              hintText: "••••••••",
              hintStyle: const TextStyle(fontSize: 12, letterSpacing: 2, color: AppColors.onDarkMuted),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.brandYellow),
              ),
              filled: true,
              fillColor: AppColors.surface,
            ),
          ),
        ),
      ],
    );
  }

  // --- WIDGET REQUIREMENT CHECKER ---
  Widget _buildRequirement(String text, bool isValid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            isValid ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: isValid ? Colors.green : AppColors.onDarkMuted,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? Colors.green : AppColors.onDarkMuted,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}