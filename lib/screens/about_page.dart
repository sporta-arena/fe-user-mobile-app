import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: Text(
          "Tentang Sportago",
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold)
        ),
        backgroundColor: context.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
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
              color: context.c.surface,
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
                          color: context.c.accent.withValues(alpha: 0.2),
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

                  Text(
                    "Sportago",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: context.c.accent
                    ),
                  ),

                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.c.raised,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Version 1.0.0 (Beta)",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.c.inkSoft,
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
                  Text(
                    "Solusi Olahraga Masa Kini",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: context.c.ink),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "Sportago adalah platform digital yang menghubungkan pecinta olahraga dengan penyedia lapangan terbaik. Kami memudahkan proses pencarian, jadwal, booking, hingga pembayaran secara real-time.",
                    style: TextStyle(color: context.c.inkSoft, height: 1.5),
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
                  _buildFeatureItem(context, Icons.calendar_month, "Real-time\nBooking"),
                  _buildFeatureItem(context, Icons.qr_code_scanner, "Payment\nGateway"),
                  _buildFeatureItem(context, Icons.stars, "Loyalty\nRewards"),
                  _buildFeatureItem(context, Icons.support_agent, "24/7\nSupport"),
                ],
              ),
            ),

            const SizedBox(height: 30),
            Divider(thickness: 1, color: context.c.line),

            // --- 4. MENU KONTAK & LEGAL ---
            _buildListTile(
              context,
              icon: Icons.language,
              title: "Website Resmi",
              subtitle: "www.sporta.id",
              onTap: () {
                _showComingSoonDialog(context, "Website");
              },
            ),
            
            _buildListTile(
              context,
              icon: Icons.email_outlined,
              title: "Email Support",
              subtitle: "support@sporta.id",
              onTap: () {
                _copyToClipboard(context, "support@sporta.id", "Email");
              },
            ),
            
            _buildListTile(
              context,
              icon: Icons.camera_alt_outlined,
              title: "Instagram",
              subtitle: "@sporta.app",
              onTap: () {
                _showComingSoonDialog(context, "Instagram");
              },
            ),

            Divider(thickness: 1, color: context.c.line),

            _buildListTile(
              context,
              icon: Icons.privacy_tip_outlined,
              title: "Kebijakan Privasi",
              onTap: () {
                _showPrivacyPolicyDialog(context);
              },
            ),
            
            _buildListTile(
              context,
              icon: Icons.description_outlined,
              title: "Syarat & Ketentuan",
              onTap: () {
                _showTermsDialog(context);
              },
            ),

            _buildListTile(
              context,
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
                  "Made with ❤️ by Sportago Team",
                  style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  "© 2025 Sportago Indonesia",
                  style: TextStyle(color: context.c.inkSoft, fontSize: 12),
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
  Widget _buildFeatureItem(BuildContext context, IconData icon, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.c.accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: context.c.accent, size: 24),
        ),

        const SizedBox(height: 8),

        Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: context.c.ink
          ),
        ),
      ],
    );
  }

  // Widget List Menu
  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
      leading: Icon(icon, color: context.c.inkSoft),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: context.c.ink)
      ),
      subtitle: subtitle != null
        ? Text(
            subtitle,
            style: TextStyle(color: context.c.accent, fontSize: 12)
          )
        : null,
      trailing: Icon(Icons.arrow_forward_ios, size: 14, color: context.c.inkSoft),
      onTap: onTap,
    );
  }

  // Helper Functions
  void _copyToClipboard(BuildContext context, String text, String type) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$type berhasil disalin ke clipboard"),
        backgroundColor: context.c.ok,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showComingSoonDialog(BuildContext context, String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Coming Soon", style: TextStyle(color: context.c.ink)),
        content: Text("$feature akan segera tersedia dalam update mendatang.", style: TextStyle(color: context.c.inkSoft)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK", style: TextStyle(color: context.c.accent)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Kebijakan Privasi", style: TextStyle(color: context.c.ink)),
        content: SingleChildScrollView(
          child: Text(
            "Sportago berkomitmen untuk melindungi privasi pengguna. Kami mengumpulkan data yang diperlukan untuk memberikan layanan terbaik, termasuk:\n\n"
            "• Informasi akun (nama, email, nomor telepon)\n"
            "• Data booking dan transaksi\n"
            "• Lokasi untuk rekomendasi venue terdekat\n"
            "• Data penggunaan aplikasi untuk peningkatan layanan\n\n"
            "Data Anda tidak akan dibagikan kepada pihak ketiga tanpa persetujuan, kecuali untuk keperluan operasional layanan.",
            style: TextStyle(height: 1.5, color: context.c.inkSoft),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup", style: TextStyle(color: context.c.accent)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Syarat & Ketentuan", style: TextStyle(color: context.c.ink)),
        content: SingleChildScrollView(
          child: Text(
            "Dengan menggunakan aplikasi Sportago, Anda menyetujui:\n\n"
            "1. Memberikan informasi yang akurat saat registrasi\n"
            "2. Bertanggung jawab atas keamanan akun Anda\n"
            "3. Menggunakan layanan sesuai dengan ketentuan yang berlaku\n"
            "4. Melakukan pembayaran tepat waktu untuk booking yang dibuat\n"
            "5. Mematuhi aturan venue yang telah ditetapkan\n\n"
            "Sportago berhak untuk menangguhkan atau menutup akun yang melanggar ketentuan ini.",
            style: TextStyle(height: 1.5, color: context.c.inkSoft),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup", style: TextStyle(color: context.c.accent)),
          ),
        ],
      ),
    );
  }

  void _showLicenseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Lisensi Open Source", style: TextStyle(color: context.c.ink)),
        content: SingleChildScrollView(
          child: Text(
            "Sportago menggunakan berbagai library open source:\n\n"
            "• Flutter Framework (BSD License)\n"
            "• Material Design Icons (Apache 2.0)\n"
            "• HTTP Package (BSD License)\n"
            "• Geolocator (MIT License)\n"
            "• UUID Generator (MIT License)\n\n"
            "Terima kasih kepada komunitas open source yang telah berkontribusi dalam pengembangan aplikasi ini.",
            style: TextStyle(height: 1.5, color: context.c.inkSoft),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Tutup", style: TextStyle(color: context.c.accent)),
          ),
        ],
      ),
    );
  }
}