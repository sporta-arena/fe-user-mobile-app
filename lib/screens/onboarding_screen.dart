import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/sportago_mark.dart';
import '../theme/app_tokens.dart';
import 'login_page.dart';
import 'home_page.dart';
import '../services/auth_service.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  bool _isGoogleLoading = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Zoom pelan foto latar. Begitu selesai, slide maju sendiri, jadi
  /// ketiga cerita tetap terlihat walau pengguna tidak menggeser.
  late final AnimationController _zoomController;

  // Tiga slide berfoto pemain (ComfyUI, lihat assets/images/hero/),
  // urut sesuai perjalanan pemain. Sengaja foto siang yang terang dan
  // berisi orang: foto lapangan malam yang gelap itu milik app mitra.
  static const List<_Slide> _slides = [
    _Slide(
      image: 'assets/images/hero/onboarding-1.jpg',
      title: 'Cari lapangan\nyang dekat',
      description:
          'Futsal, badminton, basket, mini soccer. Lihat venue di '
          'sekitarmu lengkap dengan jam yang masih kosong.',
    ),
    _Slide(
      image: 'assets/images/hero/onboarding-2.jpg',
      title: 'Booking dan bayar\ndalam semenit',
      description:
          'Pilih jam, bayar pakai QRIS atau virtual account. '
          'Nggak perlu telepon atau chat admin dulu.',
    ),
    _Slide(
      image: 'assets/images/hero/onboarding-3.jpg',
      title: 'Tunjukin tiket,\nlangsung main',
      description:
          'E-tiket muncul di aplikasi begitu pembayaran masuk. '
          'Sampai venue, tinggal scan.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _zoomController =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..addStatusListener(_onZoomSelesai)
          ..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Foto berikutnya dimuat lebih dulu supaya crossfade-nya tidak
    // sempat menampilkan latar kosong.
    for (final s in _slides) {
      precacheImage(AssetImage(s.image), context);
    }
  }

  @override
  void dispose() {
    _zoomController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onZoomSelesai(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_pageController.hasClients) {
      return;
    }
    final next = (_currentPage + 1) % _slides.length;
    if (next == 0) {
      _pageController.jumpToPage(0);
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _zoomController.forward(from: 0);
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isGoogleLoading = true);
    final result = await AuthService.loginWithGoogle();
    if (!mounted) return;
    setState(() => _isGoogleLoading = false);

    if (result.success) {
      await AuthService.setOnboardingSeen();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Login Google gagal'),
          backgroundColor: context.c.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _continueWithEmail() async {
    // Mark onboarding as seen so it won't show again
    await AuthService.setOnboardingSeen();

    if (mounted) {
      // push (not replace) so Login can back out to this onboarding screen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final gelap = Theme.of(context).brightness == Brightness.dark;
    final pendek = MediaQuery.of(context).size.height < 700;

    // Foto di atas memudar ke permukaan tema; teks dan tombol duduk di
    // permukaan itu. Ikon bilah status terang karena ujung atas foto
    // diberi bayangan tipis.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: c.surface,
        systemNavigationBarIconBrightness: gelap
            ? Brightness.light
            : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: c.surface,
        body: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, i) => _buildPage(_slides[i], i, pendek),
              ),
            ),
            SafeArea(top: false, child: _buildBottomSection(pendek)),
          ],
        ),
      ),
    );
  }

  /// Foto slide: mengisi ±60% layar, sudut bawah membulat besar, dan
  /// ujung bawahnya memudar ke permukaan tema supaya teks di bawahnya
  /// tidak terasa menempel di atas foto.
  Widget _buildPhoto(_Slide slide, int index) {
    final c = context.c;
    final tinggi = MediaQuery.of(context).size.height * 0.58;
    final aktif = index == _currentPage;
    return SizedBox(
      height: tinggi,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(40)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimatedBuilder(
              animation: _zoomController,
              builder: (context, child) => Transform.scale(
                scale: aktif
                    ? 1.0 +
                          0.06 * Curves.easeOut.transform(_zoomController.value)
                    : 1.0,
                child: child,
              ),
              child: Image.asset(
                slide.image,
                fit: BoxFit.cover,
                // Foto hiasan; isinya sudah dijelaskan judul slide.
                excludeFromSemantics: true,
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.2, 0.7, 1.0],
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.0),
                    c.surface.withValues(alpha: 0.0),
                    c.surface.withValues(alpha: 0.85),
                  ],
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: c.raised,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const SportagoWordmark(markHeight: 20, fontSize: 13),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_Slide slide, int index, bool pendek) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPhoto(slide, index),
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(28, pendek ? 12 : 20, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: TextStyle(
                    fontSize: pendek ? 26 : 30,
                    fontWeight: FontWeight.w800,
                    color: c.ink,
                    letterSpacing: -0.9,
                    height: 1.12,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  style: TextStyle(
                    fontSize: pendek ? 14 : 15,
                    color: c.inkSoft,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomSection(bool pendek) {
    final c = context.c;
    return Padding(
      padding: EdgeInsets.fromLTRB(28, 0, 28, pendek ? 12 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: List.generate(
              _slides.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                margin: const EdgeInsets.only(right: 6),
                width: _currentPage == i ? 28 : 8,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentPage == i ? c.accent : c.lineStrong,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          SizedBox(height: pendek ? 16 : 22),

          // Tombol "Continue with Apple" dicabut: masuk lewat Apple
          // belum digarap sama sekali, jadi tombolnya cuma
          // memunculkan snackbar "belum tersedia". Lagi pula app
          // ini baru rilis di Android.

          // Masuk pakai email: tombol utama aksen tema customer
          // (hijau lapangan, volt di tema gelap).
          _AuthButton(
            label: 'Lanjut pakai email',
            background: c.accent,
            foreground: c.onAccent,
            height: pendek ? 52 : 56,
            trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
            onPressed: _continueWithEmail,
          ),

          // Masuk lewat Google baru jalan di Android
          // (Google Sign-In di iOS belum dikonfigurasi).
          if (!Platform.isIOS) ...[
            const SizedBox(height: 10),
            _AuthButton(
              label: _isGoogleLoading
                  ? 'Menghubungkan…'
                  : 'Lanjut dengan Google',
              background: c.raised,
              foreground: c.ink,
              garis: c.lineStrong,
              height: pendek ? 52 : 56,
              leading: _isGoogleLoading
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: c.accent,
                      ),
                    )
                  : Image.asset('assets/google_logo.png', height: 20),
              onPressed: _isGoogleLoading ? () {} : _continueWithGoogle,
            ),
          ],
          SizedBox(height: pendek ? 4 : 8),
        ],
      ),
    );
  }
}

class _Slide {
  final String image;
  final String title;
  final String description;

  const _Slide({
    required this.image,
    required this.title,
    required this.description,
  });
}

class _AuthButton extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;
  final double height;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback onPressed;

  /// Garis tepi untuk tombol sekunder (Google). Null = tanpa garis.
  final Color? garis;

  const _AuthButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.height = 56,
    this.leading,
    this.trailing,
    this.garis,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: garis == null ? BorderSide.none : BorderSide(color: garis!),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 10)],
            Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              IconTheme(
                data: IconThemeData(color: foreground),
                child: trailing!,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
