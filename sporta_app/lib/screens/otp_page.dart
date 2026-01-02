import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart'; // Library kotak-kotak OTP
import 'home_page.dart'; // Nanti kita buat file ini (Dashboard)

class OtpVerificationPage extends StatefulWidget {
  final String phoneNumber; // Menerima data No HP dari halaman Register

  const OtpVerificationPage({super.key, required this.phoneNumber});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  // Simulasi kode OTP yang benar (Hardcode dulu untuk testing)
  final String _correctOtp = "1234"; 

  void _verifyOtp() async {
    final inputCode = _pinController.text;

    if (inputCode.length != 4) return;

    setState(() => _isLoading = true);

    // Simulasi Request ke Server
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);

      if (inputCode == _correctOtp) {
        // --- SUKSES ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Verifikasi Berhasil! Selamat Datang."), backgroundColor: Colors.green),
        );

        // Pindah ke Dashboard Utama (Hapus semua history back agar user gak bisa balik ke login)
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );

      } else {
        // --- GAGAL ---
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Kode OTP Salah! Coba lagi (1234)."), backgroundColor: Colors.red),
        );
        _pinController.clear(); // Hapus inputan
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- STYLE UNTUK PINPUT (Kotak OTP) ---
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 56,
      textStyle: const TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.w600),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: const Color(0xFF0047FF), width: 2), // Biru saat diklik
      borderRadius: BorderRadius.circular(12),
    );

    final errorPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(color: Colors.red, width: 2),
    );

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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // Icon Gembok / OTP
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0047FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_clock_outlined, size: 50, color: Color(0xFF0047FF)),
              ),
              
              const SizedBox(height: 30),
              
              const Text(
                "Verifikasi OTP",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0047FF)),
              ),
              const SizedBox(height: 10),
              
              // Text Rich untuk menampilkan No HP bold
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  text: "Kode 4 digit telah dikirim ke WhatsApp\n",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                  children: [
                    TextSpan(
                      text: widget.phoneNumber, // Data dinamis dari register
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // --- INPUT OTP (PINPUT) ---
              Pinput(
                length: 4,
                controller: _pinController,
                defaultPinTheme: defaultPinTheme,
                focusedPinTheme: focusedPinTheme,
                errorPinTheme: errorPinTheme,
                pinputAutovalidateMode: PinputAutovalidateMode.onSubmit,
                showCursor: true,
                onCompleted: (pin) {
                  // Otomatis submit saat user selesai ketik 4 digit
                  _verifyOtp();
                },
              ),

              const SizedBox(height: 40),

              // --- TOMBOL VERIFIKASI ---
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verifyOtp,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("VERIFIKASI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),

              const SizedBox(height: 20),

              // --- KIRIM ULANG (RESEND) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Tidak terima kode? ", style: TextStyle(color: Colors.grey)),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode baru dikirim!")));
                    },
                    child: const Text(
                      "Kirim Ulang",
                      style: TextStyle(color: Color(0xFF0047FF), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}