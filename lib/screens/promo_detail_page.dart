import 'package:flutter/material.dart';

class PromoDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const PromoDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Detail Promo", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Banner Besar
            Hero( // Efek animasi transisi halus dari halaman sebelumnya
              tag: title, 
              child: Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(Icons.local_offer, size: 150, color: Colors.white.withOpacity(0.2)),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // 2. Kode Promo (Copyable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid, width: 2), // Garis solid
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Kode Promo", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      const Text("SPORTA50", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kode berhasil disalin!")));
                    },
                    child: const Icon(Icons.copy, color: Color(0xFF0047FF)),
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. Syarat & Ketentuan
            const Text("Syarat & Ketentuan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 12),
            _buildSyarat("Promo berlaku untuk pengguna baru Sporta."),
            _buildSyarat("Minimum transaksi booking Rp 100.000."),
            _buildSyarat("Berlaku untuk semua venue Futsal & Badminton."),
            _buildSyarat("Tidak dapat digabung dengan promo lain."),
            _buildSyarat("Periode promo: 1 - 31 Januari 2026."),
          ],
        ),
      ),
      
      // 4. Tombol Pakai di Bawah
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                 Navigator.pop(context); // Balik ke Home
                 ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Promo terpasang! Silakan cari lapangan."), backgroundColor: Colors.green));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("PAKAI PROMO SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSyarat(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.grey[700], height: 1.4))),
        ],
      ),
    );
  }
}