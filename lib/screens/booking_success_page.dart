import 'package:flutter/material.dart';

class BookingSuccessPage extends StatelessWidget {
  const BookingSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon Animasi Sukses (Kita pakai icon statis dulu biar simpel)
              Container(
                height: 120, 
                width: 120,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle, 
                  color: Colors.green, 
                  size: 80
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "Booking Berhasil!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              const Text(
                "Lapangan berhasil dipesan. Tiket elektronik telah dikirim ke email Anda.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 50),

              // Kartu Tiket
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Text(
                      "KODE BOOKING", 
                      style: TextStyle(
                        fontSize: 10, 
                        letterSpacing: 1.5, 
                        color: Colors.grey
                      )
                    ),
                    SizedBox(height: 8),
                    Text(
                      "SPT-882910", 
                      style: TextStyle(
                        fontSize: 24, 
                        fontWeight: FontWeight.w900, 
                        color: Color(0xFF0047FF)
                      )
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Tombol Balik ke Home
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Kembali ke halaman paling awal (Home)
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0047FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)
                    ),
                  ),
                  child: const Text(
                    "KEMBALI KE HOME", 
                    style: TextStyle(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold
                    )
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