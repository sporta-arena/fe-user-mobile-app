import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;

  // --- LOGIKA VALIDASI & KIRIM ---
  void _handleResetPassword() async {
    // 1. Reset Error
    setState(() => _emailError = null);

    // 2. Validasi Email
    final email = _emailController.text.trim();
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    if (email.isEmpty) {
      setState(() => _emailError = "Email wajib diisi");
      return;
    } else if (!emailRegex.hasMatch(email)) {
      setState(() => _emailError = "Format email tidak valid");
      return;
    }

    // 3. Loading State
    setState(() => _isLoading = true);

    // 4. Simulasi Request ke Backend (2 detik)
    // Backend akan mengirim email berisi link reset password
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      // 5. Tampilkan Pesan Sukses
      showDialog(
        context: context,
        barrierDismissible: false, // User wajib klik tombol OK
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Column(
            children: [
              Icon(Icons.mark_email_read_outlined, color: Colors.green, size: 50),
              SizedBox(height: 10),
              Text("Cek Email Anda", style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            "Link untuk reset password telah dikirim ke $email. Silakan cek Inbox atau Spam.",
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047FF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup Dialog
                  Navigator.pop(context); // Kembali ke Halaman Login
                },
                child: const Text("KEMBALI KE LOGIN", style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              
              // --- ICON ILLUSTRATION ---
              Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: const Color(0xFF0047FF).withOpacity(0.1), // Biru Muda Transparan
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset, // Ikon Gembok Reset
                  size: 80,
                  color: Color(0xFF0047FF),
                ),
              ),
              
              const SizedBox(height: 30),

              // --- TEXT HEADER ---
              const Text(
                "Lupa Password?",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0047FF),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Jangan khawatir! Masukkan email yang terdaftar, kami akan mengirimkan link untuk membuat password baru.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
              ),

              const SizedBox(height: 40),

              // --- INPUT EMAIL ---
              Align(
                alignment: Alignment.centerLeft,
                child: const Text("Email Address", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "nama@domain.com",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  errorText: _emailError, // Pesan error muncul di sini
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0047FF), width: 1.5)),
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[500]),
                ),
              ),

              const SizedBox(height: 40),

              // --- TOMBOL KIRIM ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "KIRIM LINK RESET",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.0,
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
}