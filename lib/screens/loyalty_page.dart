import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'redeem_page.dart';

class LoyaltyPage extends StatefulWidget {
  const LoyaltyPage({super.key});

  @override
  State<LoyaltyPage> createState() => _LoyaltyPageState();
}

class _LoyaltyPageState extends State<LoyaltyPage> with TickerProviderStateMixin {
  // App theme colors
  static const Color primaryBlue = Color(0xFF0047FF);
  static const Color secondaryBlue = Color(0xFF00C6FF);
  static const Color darkBlue = Color(0xFF0A1628);
  static const Color accentGold = Color(0xFFFFD700);

  // --- STATE VARIABLES ---
  int _currentPoints = 150;
  int _spinTickets = 2;
  bool _isKicking = false;
  String _kickResult = '';
  bool _showResultOverlay = false;
  bool _playerKicking = false;

  // Ball animation values (0 to 1 progress)
  double _ballProgress = 0;
  double _ballTargetX = 0; // -1 left, 0 center, 1 right
  double _ballTargetY = 0; // 0 = low, 1 = high
  bool _ballHit = false;

  // Keeper position
  double _keeperX = 0;
  double _keeperTargetX = 0;
  bool _keeperDiving = false;

  // Animation Controllers
  late AnimationController _ballController;
  late AnimationController _pulseController;
  late AnimationController _keeperController;
  late AnimationController _playerController;
  late AnimationController _ambientController;

  // Animations
  late Animation<double> _ballAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _keeperAnimation;
  late Animation<double> _playerAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startIdleAnimations();
  }

  void _initializeAnimations() {
    // Ball trajectory animation - smooth curve
    _ballController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _ballAnimation = CurvedAnimation(
      parent: _ballController,
      curve: Curves.easeOutQuart,
    );
    _ballController.addListener(_onBallAnimationUpdate);

    // Pulse animation for ball glow
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Keeper dive animation
    _keeperController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _keeperAnimation = CurvedAnimation(
      parent: _keeperController,
      curve: Curves.easeOutCubic,
    );
    _keeperController.addListener(_onKeeperAnimationUpdate);

    // Player kick animation
    _playerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _playerAnimation = CurvedAnimation(
      parent: _playerController,
      curve: Curves.easeOutBack,
    );

    // Ambient animation for stadium
    _ambientController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  void _onBallAnimationUpdate() {
    if (!mounted) return;
    setState(() {
      _ballProgress = _ballAnimation.value;
    });
  }

  void _onKeeperAnimationUpdate() {
    if (!mounted) return;
    setState(() {
      _keeperX = _keeperTargetX * _keeperAnimation.value;
    });
  }

  void _startIdleAnimations() {
    if (_spinTickets > 0 && !_isKicking) {
      _pulseController.repeat(reverse: true);
    }
  }

  void _stopIdleAnimations() {
    _pulseController.stop();
    _pulseController.value = 0.5;
  }

  @override
  void dispose() {
    _ballController.removeListener(_onBallAnimationUpdate);
    _keeperController.removeListener(_onKeeperAnimationUpdate);
    _ballController.dispose();
    _pulseController.dispose();
    _keeperController.dispose();
    _playerController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  // --- PENALTY KICK LOGIC ---
  void _playGacha() async {
    if (_spinTickets <= 0) {
      _showNoTicketsDialog();
      return;
    }

    HapticFeedback.heavyImpact();
    _stopIdleAnimations();

    setState(() {
      _spinTickets -= 1;
      _isKicking = true;
      _kickResult = '';
      _showResultOverlay = false;
      _ballProgress = 0;
      _ballHit = false;
      _keeperDiving = false;
    });

    // Generate result
    final reward = _generateReward();
    final result = reward['result'] as String;

    // Determine ball target based on result
    final random = Random();

    switch (result) {
      case 'goal':
        // Ball goes to corner where keeper won't reach
        _ballTargetX = random.nextBool() ? -0.8 : 0.8;
        _ballTargetY = random.nextDouble() * 0.3 + 0.4; // mid to high
        _keeperTargetX = -_ballTargetX * 0.5; // Keeper dives wrong way
        break;
      case 'post':
        // Ball hits the post
        _ballTargetX = random.nextBool() ? -1.0 : 1.0;
        _ballTargetY = random.nextDouble() * 0.5 + 0.3;
        _keeperTargetX = _ballTargetX * 0.3;
        break;
      case 'saved':
        // Keeper saves it
        _ballTargetX = random.nextDouble() * 1.2 - 0.6;
        _ballTargetY = random.nextDouble() * 0.4 + 0.2;
        _keeperTargetX = _ballTargetX * 0.9; // Keeper guesses right
        break;
      case 'miss':
        // Ball goes over/wide
        _ballTargetX = random.nextBool() ? -1.3 : 1.3;
        _ballTargetY = random.nextDouble() * 0.3 + 0.8; // High
        _keeperTargetX = _ballTargetX * 0.5;
        break;
    }

    // Start player kick animation
    setState(() => _playerKicking = true);
    _playerController.forward();

    await Future.delayed(const Duration(milliseconds: 200));

    // Start ball animation
    HapticFeedback.mediumImpact();
    _ballController.forward();

    // Keeper starts diving after short delay
    await Future.delayed(const Duration(milliseconds: 250));
    setState(() => _keeperDiving = true);
    _keeperController.forward();

    // Wait for ball to reach goal
    await Future.delayed(const Duration(milliseconds: 900));

    setState(() {
      _ballHit = true;
      _kickResult = result;
    });

    HapticFeedback.heavyImpact();

    // Show result overlay
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showResultOverlay = true);

    await Future.delayed(const Duration(milliseconds: 800));

    // Reset everything
    _ballController.reset();
    _keeperController.reset();
    _playerController.reset();

    setState(() {
      _currentPoints += reward['points'] as int;
      _ballProgress = 0;
      _keeperX = 0;
      _keeperTargetX = 0;
      _keeperDiving = false;
      _isKicking = false;
      _kickResult = '';
      _showResultOverlay = false;
      _playerKicking = false;
      _ballHit = false;
    });

    if (_spinTickets > 0) {
      _startIdleAnimations();
    }

    if (mounted) {
      _showRewardDialog(reward);
    }
  }

  Map<String, dynamic> _generateReward() {
    final random = Random();
    int chance = random.nextInt(100);

    if (chance < 5) {
      return {
        'points': 1000,
        'title': 'GOOOL!',
        'subtitle': 'Tendangan sempurna!',
        'color': accentGold,
        'result': 'goal',
      };
    } else if (chance < 15) {
      return {
        'points': 500,
        'title': 'KENA TIANG!',
        'subtitle': 'Hampir masuk!',
        'color': const Color(0xFF9C27B0),
        'result': 'post',
      };
    } else if (chance < 40) {
      return {
        'points': 100,
        'title': 'DITEPIS!',
        'subtitle': 'Kiper berhasil menangkap',
        'color': primaryBlue,
        'result': 'saved',
      };
    } else {
      return {
        'points': 10,
        'title': 'MELESET!',
        'subtitle': 'Bola keluar gawang',
        'color': const Color(0xFF78909C),
        'result': 'miss',
      };
    }
  }

  void _showNoTicketsDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryBlue.withValues(alpha: 0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue.withValues(alpha: 0.1), secondaryBlue.withValues(alpha: 0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.confirmation_number_outlined,
                  size: 48,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Tiket Habis!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: darkBlue),
              ),
              const SizedBox(height: 12),
              Text(
                "Booking lapangan untuk mendapatkan tiket gacha gratis!",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Mengerti",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRewardDialog(Map<String, dynamic> reward) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GachaRewardDialog(reward: reward),
    );
  }

  void _goToRedeemPage() async {
    final remainingPoints = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RedeemPage(currentPoints: _currentPoints)),
    );
    if (remainingPoints != null) {
      setState(() {
        _currentPoints = remainingPoints;
      });
    }
  }

  void _simulateBooking() {
    setState(() {
      _spinTickets += 1;
    });

    if (_spinTickets == 1) {
      _startIdleAnimations();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text("Booking berhasil! +1 Tiket Gacha"),
          ],
        ),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  String _formatPoints(int points) {
    return points.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBlue,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: GestureDetector(
                onTap: (_isKicking || _spinTickets <= 0) ? null : _playGacha,
                child: Stack(
                  children: [
                    // Stadium scene
                    CustomPaint(
                      painter: StadiumPainter(
                        ambientProgress: _ambientController.value,
                      ),
                      size: Size.infinite,
                    ),

                    // Goal and goalkeeper
                    AnimatedBuilder(
                      animation: _ambientController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: GoalPainter(
                            keeperX: _keeperX,
                            keeperDiving: _keeperDiving,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),

                    // Ball
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: BallPainter(
                            progress: _ballProgress,
                            targetX: _ballTargetX,
                            targetY: _ballTargetY,
                            isKicking: _isKicking,
                            pulseValue: _pulseAnimation.value,
                            hasTickets: _spinTickets > 0,
                            ballHit: _ballHit,
                            kickResult: _kickResult,
                          ),
                          size: Size.infinite,
                        );
                      },
                    ),

                    // Player (from behind)
                    CustomPaint(
                      painter: PlayerPainter(
                        isKicking: _playerKicking,
                        kickProgress: _playerAnimation.value,
                      ),
                      size: Size.infinite,
                    ),

                    // Result overlay
                    if (_showResultOverlay)
                      _buildResultOverlay(),

                    // Bottom UI
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildBottomUI(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            ),
          ),
          const Spacer(),
          const Text(
            "Penalty Kick",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _goToRedeemPage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accentGold.withValues(alpha: 0.2), accentGold.withValues(alpha: 0.1)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: accentGold.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.stars_rounded, color: accentGold, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    _formatPoints(_currentPoints),
                    style: const TextStyle(
                      color: accentGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultOverlay() {
    Color resultColor;
    IconData resultIcon;
    String resultText;

    switch (_kickResult) {
      case 'goal':
        resultColor = accentGold;
        resultIcon = Icons.emoji_events;
        resultText = 'GOOOL!';
        break;
      case 'post':
        resultColor = const Color(0xFF9C27B0);
        resultIcon = Icons.sports_soccer;
        resultText = 'KENA TIANG!';
        break;
      case 'saved':
        resultColor = primaryBlue;
        resultIcon = Icons.sports_handball;
        resultText = 'DITEPIS!';
        break;
      default:
        resultColor = const Color(0xFF78909C);
        resultIcon = Icons.close;
        resultText = 'MELESET!';
    }

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.5),
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.elasticOut,
            builder: (context, scale, child) {
              return Transform.scale(
                scale: scale,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: resultColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: resultColor, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: resultColor.withValues(alpha: 0.5),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(resultIcon, size: 60, color: resultColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      resultText,
                      style: TextStyle(
                        color: resultColor,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: resultColor.withValues(alpha: 0.5),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBottomUI() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            darkBlue.withValues(alpha: 0.8),
            darkBlue,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ticket indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _spinTickets > 0
                    ? [primaryBlue.withValues(alpha: 0.3), secondaryBlue.withValues(alpha: 0.2)]
                    : [Colors.red.withValues(alpha: 0.3), Colors.red.withValues(alpha: 0.2)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: _spinTickets > 0 ? primaryBlue.withValues(alpha: 0.5) : Colors.red.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.confirmation_number_rounded,
                  color: _spinTickets > 0 ? secondaryBlue : Colors.red,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _spinTickets > 0 ? "$_spinTickets Tiket Tersedia" : "Tiket Habis",
                  style: TextStyle(
                    color: _spinTickets > 0 ? Colors.white : Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Instruction
          Text(
            _isKicking
                ? "Menendang..."
                : _spinTickets > 0
                    ? "TAP LAYAR UNTUK TENDANG"
                    : "Booking lapangan untuk dapat tiket",
            style: TextStyle(
              color: _spinTickets > 0 ? Colors.white : Colors.white54,
              fontSize: _spinTickets > 0 ? 16 : 14,
              fontWeight: FontWeight.bold,
              letterSpacing: _spinTickets > 0 ? 1.5 : 0,
            ),
          ),
          const SizedBox(height: 16),
          // Bottom buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildBottomButton(
                icon: Icons.emoji_events,
                label: "Hadiah",
                onTap: _showPrizesSheet,
                isPrimary: true,
              ),
              const SizedBox(width: 12),
              _buildBottomButton(
                icon: Icons.add,
                label: "Tiket",
                onTap: _simulateBooking,
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isPrimary,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? LinearGradient(colors: [primaryBlue.withValues(alpha: 0.3), secondaryBlue.withValues(alpha: 0.2)])
              : null,
          color: isPrimary ? null : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
          border: isPrimary ? Border.all(color: primaryBlue.withValues(alpha: 0.4)) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isPrimary ? secondaryBlue : Colors.white54, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isPrimary ? Colors.white : Colors.white54,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPrizesSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        decoration: const BoxDecoration(
          color: Color(0xFF1A2744),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: accentGold, size: 24),
                const SizedBox(width: 10),
                const Text(
                  "Hadiah Tendangan",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  _buildPrizeItem('GOAL', Icons.emoji_events, '1000', accentGold, 'Bola masuk ke gawang!'),
                  _buildPrizeItem('Kena Tiang', Icons.sports_soccer, '500', const Color(0xFF9C27B0), 'Hampir masuk!'),
                  _buildPrizeItem('Ditepis', Icons.sports_handball, '100', primaryBlue, 'Kiper berhasil menangkap'),
                  _buildPrizeItem('Meleset', Icons.close, '10', const Color(0xFF78909C), 'Bola keluar gawang'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeItem(String label, IconData icon, String points, Color color, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(desc, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
            child: Text("+$points", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// STADIUM PAINTER - Background with perspective
// ==========================================
class StadiumPainter extends CustomPainter {
  final double ambientProgress;

  StadiumPainter({required this.ambientProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Sky gradient
    final skyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1a365d),
          const Color(0xFF2d5a87),
          const Color(0xFF4a7c9b),
        ],
      ).createShader(Rect.fromLTWH(0, 0, width, height * 0.4));
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height * 0.45), skyPaint);

    // Stadium stands (behind goal)
    final standsPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF3d5a80),
          const Color(0xFF293241),
        ],
      ).createShader(Rect.fromLTWH(0, height * 0.1, width, height * 0.35));

    final standsPath = Path()
      ..moveTo(0, height * 0.15)
      ..lineTo(width, height * 0.15)
      ..lineTo(width, height * 0.45)
      ..lineTo(0, height * 0.45)
      ..close();
    canvas.drawPath(standsPath, standsPaint);

    // Crowd dots (simplified)
    final crowdPaint = Paint()..color = Colors.white.withValues(alpha: 0.15);
    final random = Random(42);
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * width;
      final y = height * 0.18 + random.nextDouble() * height * 0.22;
      canvas.drawCircle(Offset(x, y), 2, crowdPaint);
    }

    // Grass field with perspective
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF1B5E20),
          const Color(0xFF2E7D32),
          const Color(0xFF388E3C),
          const Color(0xFF43A047),
        ],
      ).createShader(Rect.fromLTWH(0, height * 0.4, width, height * 0.6));

    final grassPath = Path()
      ..moveTo(0, height * 0.42)
      ..lineTo(width, height * 0.42)
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(grassPath, grassPaint);

    // Grass stripes
    final stripePaint = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (int i = 0; i < 8; i++) {
      if (i.isEven) {
        final y1 = height * 0.42 + (height * 0.58 / 8) * i;
        final y2 = y1 + (height * 0.58 / 8);
        canvas.drawRect(Rect.fromLTWH(0, y1, width, y2 - y1), stripePaint);
      }
    }

    // Field lines (perspective)
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Penalty box (trapezoid for perspective)
    final penaltyPath = Path()
      ..moveTo(width * 0.15, height * 0.42)
      ..lineTo(width * 0.85, height * 0.42)
      ..lineTo(width * 0.75, height * 0.65)
      ..lineTo(width * 0.25, height * 0.65)
      ..close();
    canvas.drawPath(penaltyPath, linePaint);

    // Small penalty box
    final smallBoxPath = Path()
      ..moveTo(width * 0.3, height * 0.42)
      ..lineTo(width * 0.7, height * 0.42)
      ..lineTo(width * 0.65, height * 0.52)
      ..lineTo(width * 0.35, height * 0.52)
      ..close();
    canvas.drawPath(smallBoxPath, linePaint);

    // Center line from player
    final centerLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 3;
    canvas.drawLine(
      Offset(width * 0.5, height * 0.65),
      Offset(width * 0.5, height * 0.95),
      centerLinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant StadiumPainter oldDelegate) => false;
}

// ==========================================
// GOAL PAINTER - Goal and Goalkeeper
// ==========================================
class GoalPainter extends CustomPainter {
  final double keeperX;
  final bool keeperDiving;

  GoalPainter({required this.keeperX, required this.keeperDiving});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Goal dimensions (perspective - wider at back)
    final goalLeft = width * 0.2;
    final goalRight = width * 0.8;
    final goalTop = height * 0.2;
    final goalBottom = height * 0.42;
    final goalWidth = goalRight - goalLeft;

    // Goal posts
    final postPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    // Left post
    canvas.drawLine(
      Offset(goalLeft, goalTop),
      Offset(goalLeft + 10, goalBottom),
      postPaint,
    );

    // Right post
    canvas.drawLine(
      Offset(goalRight, goalTop),
      Offset(goalRight - 10, goalBottom),
      postPaint,
    );

    // Crossbar
    canvas.drawLine(
      Offset(goalLeft, goalTop),
      Offset(goalRight, goalTop),
      postPaint,
    );

    // Net (back of goal)
    final netPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Net background
    final netBgPaint = Paint()
      ..color = const Color(0xFF1a365d).withValues(alpha: 0.5);

    final netPath = Path()
      ..moveTo(goalLeft, goalTop)
      ..lineTo(goalRight, goalTop)
      ..lineTo(goalRight - 10, goalBottom)
      ..lineTo(goalLeft + 10, goalBottom)
      ..close();
    canvas.drawPath(netPath, netBgPaint);

    // Net lines
    final netSpacing = goalWidth / 15;
    for (double i = goalLeft; i < goalRight; i += netSpacing) {
      final progress = (i - goalLeft) / goalWidth;
      final bottomX = goalLeft + 10 + progress * (goalWidth - 20);
      canvas.drawLine(
        Offset(i, goalTop),
        Offset(bottomX, goalBottom),
        netPaint,
      );
    }

    final netHeightSpacing = (goalBottom - goalTop) / 6;
    for (double i = goalTop; i < goalBottom; i += netHeightSpacing) {
      final progress = (i - goalTop) / (goalBottom - goalTop);
      final leftX = goalLeft + progress * 10;
      final rightX = goalRight - progress * 10;
      canvas.drawLine(
        Offset(leftX, i),
        Offset(rightX, i),
        netPaint,
      );
    }

    // Goalkeeper
    final keeperCenterX = width * 0.5 + (keeperX * goalWidth * 0.35);
    final keeperY = goalBottom - 60;

    // Keeper body
    final keeperPaint = Paint()..color = const Color(0xFF7CB342); // Green jersey
    final keeperShadow = Paint()..color = Colors.black.withValues(alpha: 0.3);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(keeperCenterX, goalBottom - 5),
        width: 40,
        height: 15,
      ),
      keeperShadow,
    );

    if (keeperDiving && keeperX.abs() > 0.3) {
      // Diving pose
      final diveAngle = keeperX > 0 ? 0.5 : -0.5;
      canvas.save();
      canvas.translate(keeperCenterX, keeperY + 20);
      canvas.rotate(diveAngle);

      // Body (horizontal when diving)
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: 50, height: 25),
          const Radius.circular(8),
        ),
        keeperPaint,
      );

      // Head
      canvas.drawCircle(
        Offset(keeperX > 0 ? 30 : -30, -5),
        12,
        Paint()..color = const Color(0xFFFFDBB4),
      );

      // Arms stretched
      final armPaint = Paint()
        ..color = const Color(0xFF7CB342)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset.zero,
        Offset(keeperX > 0 ? 45 : -45, -20),
        armPaint,
      );

      // Gloves
      canvas.drawCircle(
        Offset(keeperX > 0 ? 50 : -50, -25),
        10,
        Paint()..color = Colors.orange,
      );

      canvas.restore();
    } else {
      // Standing pose
      // Legs
      final legPaint = Paint()
        ..color = Colors.black
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(keeperCenterX - 8, keeperY + 30),
        Offset(keeperCenterX - 10, keeperY + 55),
        legPaint,
      );
      canvas.drawLine(
        Offset(keeperCenterX + 8, keeperY + 30),
        Offset(keeperCenterX + 10, keeperY + 55),
        legPaint,
      );

      // Body
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(keeperCenterX, keeperY + 15), width: 30, height: 40),
          const Radius.circular(8),
        ),
        keeperPaint,
      );

      // Head
      canvas.drawCircle(
        Offset(keeperCenterX, keeperY - 10),
        14,
        Paint()..color = const Color(0xFFFFDBB4),
      );

      // Hair
      canvas.drawArc(
        Rect.fromCenter(center: Offset(keeperCenterX, keeperY - 15), width: 28, height: 20),
        3.14,
        3.14,
        true,
        Paint()..color = const Color(0xFF3E2723),
      );

      // Arms ready position
      final armPaint = Paint()
        ..color = const Color(0xFF7CB342)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(keeperCenterX - 15, keeperY + 5),
        Offset(keeperCenterX - 35, keeperY - 10),
        armPaint,
      );
      canvas.drawLine(
        Offset(keeperCenterX + 15, keeperY + 5),
        Offset(keeperCenterX + 35, keeperY - 10),
        armPaint,
      );

      // Gloves
      canvas.drawCircle(
        Offset(keeperCenterX - 38, keeperY - 12),
        9,
        Paint()..color = Colors.orange,
      );
      canvas.drawCircle(
        Offset(keeperCenterX + 38, keeperY - 12),
        9,
        Paint()..color = Colors.orange,
      );
    }
  }

  @override
  bool shouldRepaint(covariant GoalPainter oldDelegate) {
    return oldDelegate.keeperX != keeperX || oldDelegate.keeperDiving != keeperDiving;
  }
}

// ==========================================
// BALL PAINTER - Ball with trajectory
// ==========================================
class BallPainter extends CustomPainter {
  final double progress;
  final double targetX;
  final double targetY;
  final bool isKicking;
  final double pulseValue;
  final bool hasTickets;
  final bool ballHit;
  final String kickResult;

  BallPainter({
    required this.progress,
    required this.targetX,
    required this.targetY,
    required this.isKicking,
    required this.pulseValue,
    required this.hasTickets,
    required this.ballHit,
    required this.kickResult,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // Ball starting position (at player's feet)
    final startX = width * 0.5;
    final startY = height * 0.82;

    // Ball end position (at goal)
    final goalCenterX = width * 0.5;
    final goalCenterY = height * 0.35;
    final goalWidth = width * 0.5;
    final goalHeight = height * 0.15;

    double ballX, ballY, ballSize;

    if (isKicking && progress > 0) {
      // Calculate ball position along trajectory
      final endX = goalCenterX + (targetX * goalWidth * 0.45);
      final endY = goalCenterY + ((1 - targetY) * goalHeight * 0.8);

      // Bezier curve for realistic trajectory
      final controlY = min(startY, endY) - height * 0.2 * (1 + targetY * 0.5);

      // Quadratic bezier
      final t = progress;
      ballX = pow(1 - t, 2) * startX + 2 * (1 - t) * t * startX + pow(t, 2) * endX;
      ballY = pow(1 - t, 2) * startY + 2 * (1 - t) * t * controlY + pow(t, 2) * endY;

      // Ball gets smaller as it goes further (perspective)
      ballSize = 28 - (progress * 16);
    } else {
      // Ball at starting position
      ballX = startX;
      ballY = startY;
      ballSize = 28 * (hasTickets ? pulseValue : 1.0);
    }

    // Ball shadow
    if (!isKicking || progress < 0.8) {
      final shadowY = isKicking ? ballY + (ballSize * 0.5) : startY + 5;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(ballX, shadowY),
          width: ballSize * 1.2,
          height: ballSize * 0.4,
        ),
        Paint()..color = Colors.black.withValues(alpha: 0.3),
      );
    }

    // Ball glow (when has tickets and not kicking)
    if (hasTickets && !isKicking) {
      canvas.drawCircle(
        Offset(ballX, ballY),
        ballSize + 15,
        Paint()
          ..color = const Color(0xFF0047FF).withValues(alpha: 0.3 * pulseValue)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
      );
    }

    // Main ball
    final ballPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(ballX, ballY), ballSize, ballPaint);

    // Ball pattern (pentagon patches)
    final patchPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    // Draw simplified ball pattern
    _drawBallPattern(canvas, Offset(ballX, ballY), ballSize, patchPaint, isKicking ? progress * 10 : 0);

    // Ball highlight
    canvas.drawCircle(
      Offset(ballX - ballSize * 0.3, ballY - ballSize * 0.3),
      ballSize * 0.25,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Impact effect when ball hits
    if (ballHit && kickResult == 'goal') {
      // Goal flash
      canvas.drawCircle(
        Offset(ballX, ballY),
        ballSize * 2,
        Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );
    } else if (ballHit && kickResult == 'post') {
      // Post hit effect
      canvas.drawCircle(
        Offset(ballX, ballY),
        ballSize * 1.5,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.7)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
  }

  void _drawBallPattern(Canvas canvas, Offset center, double radius, Paint paint, double rotation) {
    // Center pentagon
    _drawPentagon(canvas, center, radius * 0.4, paint, rotation);

    // Surrounding pentagons
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 + rotation * 30) * pi / 180;
      final pos = Offset(
        center.dx + cos(angle) * radius * 0.55,
        center.dy + sin(angle) * radius * 0.55,
      );
      _drawPentagon(canvas, pos, radius * 0.25, paint, rotation);
    }
  }

  void _drawPentagon(Canvas canvas, Offset center, double radius, Paint paint, double rotation) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90 + rotation * 30) * pi / 180;
      final point = Offset(
        center.dx + cos(angle) * radius,
        center.dy + sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BallPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.isKicking != isKicking ||
        oldDelegate.ballHit != ballHit;
  }
}

// ==========================================
// PLAYER PAINTER - Player from behind
// ==========================================
class PlayerPainter extends CustomPainter {
  final bool isKicking;
  final double kickProgress;

  PlayerPainter({required this.isKicking, required this.kickProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final playerX = width * 0.5;
    final playerY = height * 0.92;

    // Player shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(playerX, playerY + 10),
        width: 80,
        height: 25,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    // Jersey color (red like reference)
    final jerseyPaint = Paint()..color = const Color(0xFFB71C1C);
    final shortsPaint = Paint()..color = Colors.black;
    final skinPaint = Paint()..color = const Color(0xFFFFDBB4);
    final hairPaint = Paint()..color = const Color(0xFF3E2723);
    final sockPaint = Paint()..color = Colors.white;
    final shoePaint = Paint()..color = const Color(0xFF1565C0);

    // Legs
    final legOffset = isKicking ? kickProgress * 30 : 0;

    // Left leg (support leg)
    canvas.drawLine(
      Offset(playerX - 15, playerY - 35),
      Offset(playerX - 20, playerY - 5),
      Paint()
        ..color = shortsPaint.color
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
    // Left sock
    canvas.drawLine(
      Offset(playerX - 20, playerY - 5),
      Offset(playerX - 22, playerY + 8),
      Paint()
        ..color = sockPaint.color
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    // Left shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(playerX - 25, playerY + 12), width: 25, height: 12),
        const Radius.circular(4),
      ),
      shoePaint,
    );

    // Right leg (kicking leg)
    final kickAngle = isKicking ? -kickProgress * 0.8 : 0;
    canvas.save();
    canvas.translate(playerX + 15, playerY - 35);
    canvas.rotate(kickAngle.toDouble());

    // Right thigh
    canvas.drawLine(
      Offset.zero,
      Offset(5 + legOffset * 0.3, 30),
      Paint()
        ..color = shortsPaint.color
        ..strokeWidth = 18
        ..strokeCap = StrokeCap.round,
    );
    // Right calf
    canvas.drawLine(
      Offset(5 + legOffset * 0.3, 30),
      Offset(legOffset * 0.5, 45),
      Paint()
        ..color = sockPaint.color
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round,
    );
    // Right shoe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(legOffset * 0.5 + 5, 50), width: 25, height: 12),
        const Radius.circular(4),
      ),
      shoePaint,
    );
    canvas.restore();

    // Body (torso from behind)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(playerX, playerY - 55), width: 50, height: 50),
        const Radius.circular(8),
      ),
      jerseyPaint,
    );

    // Number "10" on back
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '10',
        style: TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(playerX - textPainter.width / 2, playerY - 68),
    );

    // Arms
    final armAngle = isKicking ? kickProgress * 0.4 : 0;

    // Left arm (back swing when kicking)
    canvas.save();
    canvas.translate(playerX - 25, playerY - 65);
    canvas.rotate(-0.3 - armAngle);
    canvas.drawLine(
      Offset.zero,
      const Offset(-15, 25),
      Paint()
        ..color = jerseyPaint.color
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    // Left hand
    canvas.drawCircle(
      const Offset(-18, 28),
      7,
      skinPaint,
    );
    canvas.restore();

    // Right arm (forward when kicking)
    canvas.save();
    canvas.translate(playerX + 25, playerY - 65);
    canvas.rotate(0.3 + armAngle);
    canvas.drawLine(
      Offset.zero,
      const Offset(15, 25),
      Paint()
        ..color = jerseyPaint.color
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round,
    );
    // Right hand
    canvas.drawCircle(
      const Offset(18, 28),
      7,
      skinPaint,
    );
    canvas.restore();

    // Head (from behind)
    canvas.drawCircle(
      Offset(playerX, playerY - 90),
      18,
      skinPaint,
    );

    // Hair (back of head)
    canvas.drawArc(
      Rect.fromCenter(center: Offset(playerX, playerY - 92), width: 36, height: 30),
      pi,
      pi,
      true,
      hairPaint,
    );

    // Hair sides
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(playerX, playerY - 95), width: 36, height: 20),
        const Radius.circular(10),
      ),
      hairPaint,
    );
  }

  @override
  bool shouldRepaint(covariant PlayerPainter oldDelegate) {
    return oldDelegate.isKicking != isKicking || oldDelegate.kickProgress != kickProgress;
  }
}

// ==========================================
// GACHA REWARD DIALOG
// ==========================================
class GachaRewardDialog extends StatefulWidget {
  final Map<String, dynamic> reward;

  const GachaRewardDialog({super.key, required this.reward});

  @override
  State<GachaRewardDialog> createState() => _GachaRewardDialogState();
}

class _GachaRewardDialogState extends State<GachaRewardDialog> with TickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF0047FF);
  static const Color accentGold = Color(0xFFFFD700);

  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<ConfettiParticle> _confetti = [];

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    if (widget.reward['result'] == 'goal' || widget.reward['result'] == 'post') {
      _generateConfetti();
    }

    _scaleController.forward();
    _pulseController.repeat(reverse: true);
    _confettiController.repeat();
  }

  void _generateConfetti() {
    final random = Random();
    for (int i = 0; i < 40; i++) {
      _confetti.add(ConfettiParticle(
        x: random.nextDouble(),
        y: random.nextDouble() * -0.5,
        speed: 0.3 + random.nextDouble() * 1.2,
        size: 5 + random.nextDouble() * 8,
        color: [
          accentGold,
          primaryBlue,
          const Color(0xFF00C6FF),
          Colors.white,
          const Color(0xFF9C27B0),
        ][random.nextInt(5)],
        rotation: random.nextDouble() * 3.14,
      ));
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Color _getGradientStart() {
    switch (widget.reward['result']) {
      case 'goal': return accentGold;
      case 'post': return const Color(0xFF9C27B0);
      case 'saved': return primaryBlue;
      default: return const Color(0xFF78909C);
    }
  }

  Color _getGradientEnd() {
    switch (widget.reward['result']) {
      case 'goal': return const Color(0xFFFFA500);
      case 'post': return const Color(0xFF7B1FA2);
      case 'saved': return const Color(0xFF0035CC);
      default: return const Color(0xFF546E7A);
    }
  }

  IconData _getIcon() {
    switch (widget.reward['result']) {
      case 'goal': return Icons.emoji_events;
      case 'post': return Icons.sports_soccer;
      case 'saved': return Icons.sports_handball;
      default: return Icons.close;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLegendary = widget.reward['result'] == 'goal';
    final isEpic = widget.reward['result'] == 'post';

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isLegendary || isEpic)
              AnimatedBuilder(
                animation: _confettiController,
                builder: (context, child) {
                  return Positioned.fill(
                    child: CustomPaint(
                      painter: ConfettiPainter(
                        particles: _confetti,
                        progress: _confettiController.value,
                      ),
                    ),
                  );
                },
              ),

            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 340),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: _getGradientStart().withValues(alpha: 0.4),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [_getGradientStart(), _getGradientEnd()],
                        ),
                      ),
                      child: Column(
                        children: [
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Icon(_getIcon(), size: 48, color: Colors.white),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.reward['title'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            widget.reward['subtitle'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                      color: Colors.white,
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  _getGradientStart().withValues(alpha: 0.1),
                                  _getGradientEnd().withValues(alpha: 0.1),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(50),
                              border: Border.all(color: _getGradientStart().withValues(alpha: 0.4), width: 2),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.stars_rounded, color: _getGradientStart(), size: 32),
                                const SizedBox(width: 10),
                                Text(
                                  "+${widget.reward['points']}",
                                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: _getGradientStart()),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "pts",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: _getGradientEnd()),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _getGradientStart(),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 0,
                              ),
                              child: const Text(
                                "Klaim Hadiah",
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 17, letterSpacing: 0.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (isLegendary) ...[
              Positioned(top: -20, left: 15, child: _buildStar(24, accentGold)),
              Positioned(top: 5, right: 10, child: _buildStar(18, const Color(0xFFFFA500))),
              Positioned(bottom: 70, left: 5, child: _buildStar(16, accentGold)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStar(double size, Color color) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Icon(Icons.star_rounded, size: size, color: color),
        );
      },
    );
  }
}

// ==========================================
// CONFETTI
// ==========================================
class ConfettiParticle {
  double x, y;
  final double speed, size, rotation;
  final Color color;

  ConfettiParticle({
    required this.x,
    required this.y,
    required this.speed,
    required this.size,
    required this.color,
    required this.rotation,
  });
}

class ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;

  ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      final paint = Paint()..color = particle.color;
      final y = (particle.y + progress * particle.speed * 2) % 1.5 - 0.3;
      final x = particle.x + sin(progress * 3.14 * 2 + particle.rotation) * 0.05;

      canvas.save();
      canvas.translate(x * size.width, y * size.height);
      canvas.rotate(progress * 3.14 * 2 + particle.rotation);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size * 0.5),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ConfettiPainter oldDelegate) => true;
}
