import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Tentang Sporta", 
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER LOGO & VERSI ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              color: Colors.white,
              child: Column(
                children: [
                  // Logo App
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0047FF).withOpacity(0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.asset(
                        'assets/app_icon.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Sporta",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0047FF)
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Version 1.0.0 (Beta)",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. DESKRIPSI APLIKASI ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Solusi Olahraga Masa Kini",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Text(
                    "Sporta adalah platform digital yang menghubungkan pecinta olahraga dengan penyedia lapangan terbaik. Kami memudahkan proses pencarian, jadwal, booking, hingga pembayaran secara real-time.",
                    style: TextStyle(color: Colors.grey[600], height: 1.5),
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- 3. FITUR UNGGULAN (Grid) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFeatureItem(Icons.calendar_month, "Real-time\nBooking"),
                  _buildFeatureItem(Icons.qr_code_scanner, "Payment\nGateway"),
                  _buildFeatureItem(Icons.stars, "Loyalty\nRewards"),
                  _buildFeatureItem(Icons.support_agent, "24/7\nSupport"),
                ],
              ),
            ),

            const SizedBox(height: 30),
            const Divider(thickness: 1),

            // --- 4. MENU KONTAK & LEGAL ---
            _buildListTile(
              icon: Icons.language,
              title: "Website Resmi",
              subtitle: "www.sporta.id",
              onTap: () {
                _showComingSoonDialog(context, "Website");
              },
            ),
            
            _buildListTile(
              icon: Icons.email_outlined,
              title: "Email Support",
              subtitle: "support@sporta.id",
              onTap: () {
                _copyToClipboard(context, "support@sporta.id", "Email");
              },
            ),
            
            _buildListTile(
              icon: Icons.camera_alt_outlined,
              title: "Instagram",
              subtitle: "@sporta.app",
              onTap: () {
                _showComingSoonDialog(context, "Instagram");
              },
            ),

            const Divider(thickness: 1),

            _buildListTile(
              icon: Icons.privacy_tip_outlined,
              title: "Kebijakan Privasi",
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
            
            _buildListTile(
              icon: Icons.description_outlined,
              title: "Syarat & Ketentuan",
              onTap: () {
                _showTermsDialog(context);
              },
            ),

            _buildListTile(
              icon: Icons.info_outline,
              title: "Lisensi Open Source",
              onTap: () {
                _showLicenseDialog(context);
              },
            ),

            const SizedBox(height: 40),

            // --- 5. FOOTER ---
            Column(
              children: [
                Text(
                  "Made with ❤️ by Sporta Team",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "© 2025 Sporta Indonesia",
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // Widget Kecil untuk Fitur Icon
  Widget _buildFeatureItem(IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F5FF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF0047FF), size: 24),
        ),
        
        const SizedBox(height: 8),
        
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10, 
            fontWeight: FontWeight.bold, 
            color: Colors.black87
          ),
        ),
      ],
    );
  }

  // Widget List Menu
  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(
        title, 
        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)
      ),
      subtitle: subtitle != null 
        ? Text(
            subtitle, 
            style: TextStyle(color: Colors.blue[700], fontSize: 12)
          ) 
        : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }

  // Helper Functions
  void _copyToClipboard(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$type berhasil disalin ke clipboard"),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Coming Soon"),
        content: Text("$feature akan segera tersedia dalam update mendatang."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Kebijakan Privasi"),
        content: const SingleChildScrollView(
          child: Text(
            "Sporta berkomitmen untuk melindungi privasi pengguna. Kami mengumpulkan data yang diperlukan untuk memberikan layanan terbaik, termasuk:\n\n"
            "• Informasi akun (nama, email, nomor telepon)\n"
            "• Data booking dan transaksi\n"
            "• Lokasi untuk rekomendasi venue terdekat\n"
            "• Data penggunaan aplikasi untuk peningkatan layanan\n\n"
            "Data Anda tidak akan dibagikan kepada pihak ketiga tanpa persetujuan, kecuali untuk keperluan operasional layanan.",
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Syarat & Ketentuan"),
        content: const SingleChildScrollView(
          child: Text(
            "Dengan menggunakan aplikasi Sporta, Anda menyetujui:\n\n"
            "1. Memberikan informasi yang akurat saat registrasi\n"
            "2. Bertanggung jawab atas keamanan akun Anda\n"
            "3. Menggunakan layanan sesuai dengan ketentuan yang berlaku\n"
            "4. Melakukan pembayaran tepat waktu untuk booking yang dibuat\n"
            "5. Mematuhi aturan venue yang telah ditetapkan\n\n"
            "Sporta berhak untuk menangguhkan atau menutup akun yang melanggar ketentuan ini.",
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Lisensi Open Source"),
        content: const SingleChildScrollView(
          child: Text(
            "Sporta menggunakan berbagai library open source:\n\n"
            "• Flutter Framework (BSD License)\n"
            "• Material Design Icons (Apache 2.0)\n"
            "• HTTP Package (BSD License)\n"
            "• Geolocator (MIT License)\n"
            "• UUID Generator (MIT License)\n\n"
            "Terima kasih kepada komunitas open source yang telah berkontribusi dalam pengembangan aplikasi ini.",
            style: TextStyle(height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tutup"),
          ),
        ],
      ),
    );
  }
}