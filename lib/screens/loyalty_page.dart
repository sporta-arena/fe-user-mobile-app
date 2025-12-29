import 'package:flutter/material.dart';
import 'dart:math';
import 'redeem_page.dart'; // Pastikan import ini ada

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> with TickerProviderStateMixin {
  // --- STATE VARIABLES ---
  int _currentPoints = 150; // Poin awal (untuk redeem barang)
  int _spinTickets = 2;     // TIKET GACHA (Dapat dari booking)
  bool _isSpinning = false;
  late AnimationController _spinController;
  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _spinAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Animasi Rotasi Spin
    _spinController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    _spinAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _spinController, curve: Curves.easeInOut)
    );
    
    // Animasi Pulse (Berkedip)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut)
    );
    
    // Animasi Glow Effect
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut)
    );
    
    // Auto pulse ketika ada tiket
    if (_spinTickets > 0) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  // --- LOGIKA GACHA BARU (PAKAI TIKET) ---
  void _playGacha() async {
    // 1. Cek Tiket Cukup
    if (_spinTickets <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Tiket habis! Booking lapangan dulu untuk dapat tiket spin."),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // 2. Stop pulse animation dan mulai spin
    _pulseController.stop();
    _glowController.stop();
    
    // 3. Potong Tiket & Mulai Animasi
    setState(() {
      _spinTickets -= 1; // Kurangi 1 Tiket
      _isSpinning = true;
    });
    
    // 4. Mulai animasi spin yang dramatis
    _spinController.forward();

    // 5. Delay Animasi (Tegang...)
    await Future.delayed(const Duration(seconds: 3));
    
    // 6. Stop animasi
    _spinController.reset();

    // 7. RANDOM REWARD (Poin)
    final random = Random();
    int chance = random.nextInt(100);
    int earnedPoints = 0;
    String title = "";
    Color color = Colors.grey;
    IconData icon = Icons.star_border;

    // Logika Peluang (Sama kayak sebelumnya)
    if (chance < 1) { 
      earnedPoints = 1000; // Jackpot
      title = "JACKPOT SULTAN!";
      color = const Color(0xFFE0FF00);
      icon = Icons.emoji_events;
    } else if (chance < 10) { 
      earnedPoints = 100; // Big Win
      title = "Big Win!";
      color = Colors.purple;
      icon = Icons.military_tech;
    } else if (chance < 30) {
      earnedPoints = 50; // Medium
      title = "Lumayan!";
      color = Colors.blue;
      icon = Icons.refresh;
    } else if (chance < 60) {
      earnedPoints = 10; // Small
      title = "Dapat Receh";
      color = Colors.orange;
      icon = Icons.star_half;
    } else {
      earnedPoints = 3; // Zonk
      title = "Poin Hiburan";
      color = Colors.grey;
      icon = Icons.sentiment_dissatisfied;
    }

    // 8. Update Poin
    setState(() {
      _currentPoints += earnedPoints; // Poin nambah
      _isSpinning = false;
    });
    
    // 9. Restart pulse jika masih ada tiket
    if (_spinTickets > 0) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }

    if (mounted) {
      _showResultDialog(title, earnedPoints, color, icon);
    }
  }

  // --- NAVIGASI KE REDEEM ---
  void _goToRedeemPage() async {
    final remainingPoints = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RedeemPage(currentPoints: _currentPoints),
      ),
    );
    if (remainingPoints != null) {
      setState(() {
        _currentPoints = remainingPoints;
      });
    }
  }

  // --- SIMULASI BOOKING (HANYA UNTUK TESTING) ---
  void _simulateBooking() {
    setState(() {
      _spinTickets += 1;
    });
    
    // Start pulse animation jika baru dapat tiket pertama
    if (_spinTickets == 1) {
      _pulseController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking Sukses! Kamu dapat 1 Tiket Spin."))
    );
  }

  void _showResultDialog(String title, int points, Color color, IconData icon) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 20),
              Text(
                title, 
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
              ),
              const SizedBox(height: 10),
              Text(
                "Selamat! Poin kamu bertambah:", 
                style: TextStyle(color: Colors.grey[600])
              ),
              Text(
                "+$points Poin", 
                style: TextStyle(
                  fontSize: 32, 
                  fontWeight: FontWeight.w900, 
                  color: color
                )
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047FF)
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "KUMPULKAN POIN", 
                  style: TextStyle(color: Colors.white)
                ),
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Loyalty Program", 
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
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- HEADER POIN (DOMPET) ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0047FF), Color(0xFF002299)],
                  begin: Alignment.topLeft, 
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0047FF).withOpacity(0.4), 
                    blurRadius: 10, 
                    offset: const Offset(0, 5)
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Saldo Poin Kamu", 
                        style: TextStyle(color: Colors.white70)
                      ),
                      Text(
                        "Sporta Member", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: Color(0xFFE0FF00), size: 36),
                      const SizedBox(width: 8),
                      Text(
                        "$_currentPoints", 
                        style: const TextStyle(
                          fontSize: 32, 
                          fontWeight: FontWeight.w900, 
                          color: Colors.white
                        )
                      ),
                    ],
                  )
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- INFO TIKET & MESIN GACHA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.confirmation_number, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  "Tiket Spin: $_spinTickets", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "1 Booking = 1 Tiket Kesempatan", 
              style: TextStyle(color: Colors.grey, fontSize: 12)
            ),
            const SizedBox(height: 20),

            // KOTAK GACHA DENGAN ANIMASI MENARIK
            GestureDetector(
              onTap: _isSpinning ? null : _playGacha,
              child: AnimatedBuilder(
                animation: Listenable.merge([_spinAnimation, _pulseAnimation, _glowAnimation]),
                builder: (context, child) {
                  return Transform.scale(
                    scale: _isSpinning ? 1.0 : _pulseAnimation.value,
                    child: Transform.rotate(
                      angle: _spinAnimation.value * 2 * pi,
                      child: Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: _spinTickets > 0 
                              ? [
                                  const Color(0xFFE0FF00).withOpacity(0.3),
                                  const Color(0xFF0047FF).withOpacity(0.1),
                                  Colors.white,
                                ]
                              : [
                                  Colors.grey.shade100,
                                  Colors.white,
                                ],
                          ),
                          borderRadius: BorderRadius.circular(35),
                          border: Border.all(
                            color: _spinTickets > 0 
                              ? Color.lerp(const Color(0xFFE0FF00), const Color(0xFF0047FF), _glowAnimation.value)!
                              : Colors.grey.shade300,
                            width: _isSpinning ? 6 : 4,
                          ),
                          boxShadow: [
                            if (_spinTickets > 0) ...[
                              BoxShadow(
                                color: const Color(0xFFE0FF00).withOpacity(_glowAnimation.value * 0.6),
                                blurRadius: 30,
                                spreadRadius: _isSpinning ? 10 : 5,
                              ),
                              BoxShadow(
                                color: const Color(0xFF0047FF).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ] else ...[
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ]
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Background Pattern
                            if (_spinTickets > 0)
                              Positioned.fill(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(30),
                                    gradient: SweepGradient(
                                      colors: [
                                        Colors.transparent,
                                        const Color(0xFFE0FF00).withOpacity(0.1),
                                        Colors.transparent,
                                        const Color(0xFF0047FF).withOpacity(0.1),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Main Content
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Animated Icon
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child: _isSpinning
                                      ? const SizedBox(
                                          width: 80,
                                          height: 80,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 6,
                                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0047FF)),
                                          ),
                                        )
                                      : Icon(
                                          Icons.casino,
                                          key: ValueKey(_spinTickets),
                                          size: 80,
                                          color: _spinTickets > 0 
                                            ? const Color(0xFF0047FF) 
                                            : Colors.grey,
                                        ),
                                  ),
                                  
                                  const SizedBox(height: 16),
                                  
                                  // Animated Text
                                  AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 300),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: _isSpinning ? 16 : 20,
                                      color: _isSpinning 
                                        ? const Color(0xFF0047FF)
                                        : _spinTickets > 0 
                                          ? const Color(0xFF0047FF) 
                                          : Colors.grey,
                                    ),
                                    child: Text(
                                      _isSpinning 
                                        ? "SPINNING..." 
                                        : _spinTickets > 0 
                                          ? "TAP TO SPIN!" 
                                          : "NO TICKETS",
                                    ),
                                  ),
                                  
                                  // Sparkle Effects
                                  if (_spinTickets > 0 && !_isSpinning) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.auto_awesome, 
                                          size: 16, 
                                          color: const Color(0xFFE0FF00).withOpacity(_glowAnimation.value)
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.auto_awesome, 
                                          size: 12, 
                                          color: const Color(0xFFE0FF00).withOpacity(_glowAnimation.value * 0.7)
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.auto_awesome, 
                                          size: 16, 
                                          color: const Color(0xFFE0FF00).withOpacity(_glowAnimation.value)
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 30),

            // --- TOMBOL AKSI UTAMA ---
            // 1. Tombol Spin
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_isSpinning || _spinTickets <= 0) ? null : _playGacha,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: Text(
                  _spinTickets > 0 ? "Gunakan 1 Tiket" : "Tiket Habis", 
                  style: const TextStyle(
                    color: Colors.white, 
                    fontWeight: FontWeight.bold, 
                    fontSize: 16
                  )
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. Tombol Tukar Merchandise
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _isSpinning ? null : _goToRedeemPage,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF0047FF), width: 2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.storefront, color: Color(0xFF0047FF)),
                    SizedBox(width: 8),
                    Text(
                      "TUKAR HADIAH", 
                      style: TextStyle(
                        color: Color(0xFF0047FF), 
                        fontWeight: FontWeight.bold
                      )
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 40),

            // --- DEV TOOLS (SIMULASI BOOKING) ---
            // Ini tombol rahasia buat testing nambah tiket tanpa booking beneran
            const Divider(),
            const Text(
              "Developer Mode (Test Only)", 
              style: TextStyle(fontSize: 10, color: Colors.grey)
            ),
            TextButton.icon(
              onPressed: _simulateBooking,
              icon: const Icon(Icons.add_circle_outline, size: 16, color: Colors.green),
              label: const Text(
                "Simulasi Booking Selesai (+1 Tiket)", 
                style: TextStyle(color: Colors.green)
              ),
            ),
          ],
        ),
      ),
    );
  }
}