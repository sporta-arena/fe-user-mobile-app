import 'package:flutter/material.dart';
import 'login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  // Data Konten Onboarding
  final List<Map<String, dynamic>> _contents = [
    {
      "title": "Cari Lapangan Terdekat",
      "desc": "Temukan arena olahraga futsal, badminton, hingga basket di sekitarmu dengan mudah.",
      "icon": Icons.location_on_outlined,
    },
    {
      "title": "Booking Tanpa Ribet",
      "desc": "Cek jadwal kosong secara real-time dan booking langsung tanpa perlu telepon sana-sini.",
      "icon": Icons.calendar_month_outlined,
    },
    {
      "title": "Pembayaran Aman",
      "desc": "Bayar pakai QRIS, uang langsung diteruskan ke pemilik lapangan (Split Payment).",
      "icon": Icons.qr_code_scanner_rounded,
    },
  ];

  void _finishOnboarding() {
    // pushReplacement agar user tidak bisa tekan tombol 'Back' ke onboarding lagi
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. SKIP BUTTON ---
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text("LEWATI", style: TextStyle(color: Colors.grey)),
              ),
            ),

            // --- 2. SLIDER CONTENT ---
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _contents.length,
                onPageChanged: (index) {
                  setState(() => _currentIndex = index);
                },
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Circle Background Icon
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0047FF).withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _contents[index]['icon'],
                            size: 100,
                            color: const Color(0xFF0047FF),
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _contents[index]['title'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900, // Font tebal modern
                            color: Color(0xFF0047FF),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _contents[index]['desc'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // --- 3. BOTTOM SECTION (Indicators & Button) ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Dot Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _contents.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 6,
                        width: _currentIndex == index ? 24 : 6, // Efek memanjang
                        decoration: BoxDecoration(
                          color: _currentIndex == index 
                              ? const Color(0xFF0047FF) 
                              : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // MAIN BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 56, // Tinggi tombol modern
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentIndex == _contents.length - 1) {
                          _finishOnboarding();
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047FF),
                        elevation: 0, // Flat design modern
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // Rounded modern
                        ),
                      ),
                      child: Text(
                        _currentIndex == _contents.length - 1 ? "MULAI SEKARANG" : "LANJUT",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}