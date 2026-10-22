import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /// Zoom pelan foto slide. Begitu selesai, slide maju sendiri, jadi
  /// ketiga cerita tetap terlihat walau pengguna tidak menggeser.
  late final AnimationController _zoomController;

  // Tiga slide, masing-masing dengan latar dan bentuk foto sendiri:
  // kuning merek, hitam, lalu permukaan tema. Warnanya diambil dari logo
  // customer (kuning di atas hitam); hijau pekat dan foto lapangan malam
  // itu milik app mitra. Foto pemain dari ComfyUI, lihat
  // assets/images/hero/.
  static const List<_Slide> _slides = [
    _Slide(
      gaya: _GayaSlide.kuning,
      image: 'assets/images/hero/onboarding-1.jpg',
      title: 'Cari lapangan\nyang dekat',
      description:
          'Futsal, badminton, basket, mini soccer. Lihat venue di '
          'sekitarmu lengkap dengan jam yang masih kosong.',
    ),
    _Slide(
      gaya: _GayaSlide.hitam,
      image: 'assets/images/hero/onboarding-2.jpg',
      title: 'Booking dan bayar\ndalam semenit',
      description:
          'Pilih jam, bayar pakai QRIS atau virtual account. '
          'Nggak perlu telepon atau chat admin dulu.',
    ),
    _Slide(
      gaya: _GayaSlide.terang,
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
    // Foto slide berikutnya dimuat lebih dulu supaya tidak sempat
    // tampil kosong saat digeser.
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

  /// Warna satu slide. Slide kuning dan hitam tidak ikut tema (warnanya
  /// warna logo); slide terang ikut permukaan tema.
  _WarnaSlide _warna(_GayaSlide gaya) {
    final c = context.c;
    switch (gaya) {
      case _GayaSlide.kuning:
        return const _WarnaSlide(
          latar: SportagoColors.kuning,
          tinta: _hitam,
          tintaLembut: Color(0xFF3D3A12),
          aksen: _hitam,
          onAksen: SportagoColors.kuning,
          titikMati: Color(0x33111111),
          latarTerang: true,
        );
      case _GayaSlide.hitam:
        return const _WarnaSlide(
          latar: _hitam,
          tinta: SportagoColors.pure,
          tintaLembut: Color(0xFFB5B5B0),
          aksen: SportagoColors.kuning,
          onAksen: _hitam,
          titikMati: Color(0x40FFFFFF),
          latarTerang: false,
        );
      case _GayaSlide.terang:
        final gelap = Theme.of(context).brightness == Brightness.dark;
        return _WarnaSlide(
          latar: c.surface,
          tinta: c.ink,
          tintaLembut: c.inkSoft,
          aksen: c.accent,
          onAksen: c.onAccent,
          titikMati: c.lineStrong,
          latarTerang: !gelap,
        );
    }
  }

  static const Color _hitam = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    final pendek = MediaQuery.of(context).size.height < 700;
    final w = _warna(_slides[_currentPage].gaya);

    // Latar seluruh layar ikut slide yang aktif, jadi tombol di bawah
    // selalu duduk di warna slidenya.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: w.latarTerang
            ? Brightness.dark
            : Brightness.light,
        statusBarBrightness: w.latarTerang ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: w.latar,
        systemNavigationBarIconBrightness: w.latarTerang
            ? Brightness.dark
            : Brightness.light,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        color: w.latar,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: _onPageChanged,
                  itemBuilder: (context, i) =>
                      _buildPage(_slides[i], i, pendek),
                ),
              ),
              SafeArea(top: false, child: _buildBottomSection(w, pendek)),
            ],
          ),
        ),
      ),
    );
  }

  /// Foto dengan zoom pelan saat slidenya aktif.
  Widget _foto(_Slide slide, int index) {
    final aktif = index == _currentPage;
    return AnimatedBuilder(
      animation: _zoomController,
      builder: (context, child) => Transform.scale(
        scale: aktif
            ? 1.0 + 0.06 * Curves.easeOut.transform(_zoomController.value)
            : 1.0,
        child: child,
      ),
      child: Image.asset(
        slide.image,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        // Foto hiasan; isinya sudah dijelaskan judul slide.
        excludeFromSemantics: true,
      ),
    );
  }

  /// Bentuk foto per slide: lingkaran besar, kartu miring, kapsul tinggi.
  Widget _buildBentukFoto(_Slide slide, int index, _WarnaSlide w) {
    switch (slide.gaya) {
      case _GayaSlide.kuning:
        return LayoutBuilder(
          builder: (context, box) {
            final d = math.min(box.maxWidth * 0.82, box.maxHeight * 0.92);
            return Center(
              child: Container(
                width: d,
                height: d,
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: _hitam,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(child: _foto(slide, index)),
              ),
            );
          },
        );
      case _GayaSlide.hitam:
        return LayoutBuilder(
          builder: (context, box) {
            final lebar = math.min(box.maxWidth * 0.66, box.maxHeight * 0.66);
            return Center(
              child: Transform.rotate(
                angle: -7 * math.pi / 180,
                child: Container(
                  width: lebar,
                  height: lebar * 1.3,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: SportagoColors.pure,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: SportagoColors.kuning, width: 3),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(17),
                    child: _foto(slide, index),
                  ),
                ),
              ),
            );
          },
        );
      case _GayaSlide.terang:
        return LayoutBuilder(
          builder: (context, box) {
            final tinggi = box.maxHeight * 0.94;
            final lebar = math.min(tinggi * 0.56, box.maxWidth * 0.6);
            return Center(
              child: SizedBox(
                width: lebar + 56,
                height: tinggi,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      left: 28,
                      top: 0,
                      bottom: 0,
                      width: lebar,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: _foto(slide, index),
                      ),
                    ),
                    // Stiker QR: tiket yang tinggal discan di venue.
                    Positioned(
                      right: 0,
                      bottom: tinggi * 0.14,
                      child: Transform.rotate(
                        angle: 12 * math.pi / 180,
                        child: Container(
                          width: 92,
                          height: 92,
                          decoration: BoxDecoration(
                            color: SportagoColors.kuning,
                            shape: BoxShape.circle,
                            border: Border.all(color: _hitam, width: 3),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_2_rounded,
                                size: 40,
                                color: _hitam,
                              ),
                              Text(
                                'SCAN',
                                style: TextStyle(
                                  fontFamily: 'Archivo',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  fontStyle: FontStyle.italic,
                                  color: _hitam,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
    }
  }

  Widget _buildPage(_Slide slide, int index, bool pendek) {
    final w = _warna(slide.gaya);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 14, 28, 0),
            child: Row(
              children: [
                // Di slide kuning lambang berwarna penuh lenyap ke latar,
                // jadi semua slide memakai topeng yang diwarnai sendiri.
                Image.asset(
                  'assets/sportago_mark.png',
                  height: 24,
                  color: slide.gaya == _GayaSlide.hitam
                      ? SportagoColors.kuning
                      : w.tinta,
                  colorBlendMode: BlendMode.srcIn,
                  filterQuality: FilterQuality.medium,
                  excludeFromSemantics: true,
                ),
                const SizedBox(width: 8),
                Text(
                  'SPORTAGO',
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -0.4,
                    color: w.tinta,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: pendek ? 12 : 20,
              ),
              child: _buildBentukFoto(slide, index, w),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slide.title,
                  style: TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: pendek ? 28 : 33,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: w.tinta,
                    letterSpacing: -1,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.description,
                  style: TextStyle(
                    fontSize: pendek ? 14 : 15,
                    color: w.tintaLembut,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: pendek ? 14 : 22),
        ],
      ),
    );
  }

  Widget _buildBottomSection(_WarnaSlide w, bool pendek) {
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
                  color: _currentPage == i ? w.aksen : w.titikMati,
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

          // Masuk pakai email: tombol utama mengikuti latar slide
          // (hitam di kuning, kuning di hitam, aksen tema di terang).
          _AuthButton(
            label: 'Lanjut pakai email',
            background: w.aksen,
            foreground: w.onAksen,
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
              background: SportagoColors.pure,
              foreground: _hitam,
              garis: _hitam.withValues(alpha: 0.16),
              height: pendek ? 52 : 56,
              leading: _isGoogleLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _hitam,
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

enum _GayaSlide { kuning, hitam, terang }

/// Warna turunan satu slide.
class _WarnaSlide {
  const _WarnaSlide({
    required this.latar,
    required this.tinta,
    required this.tintaLembut,
    required this.aksen,
    required this.onAksen,
    required this.titikMati,
    required this.latarTerang,
  });

  final Color latar;
  final Color tinta;
  final Color tintaLembut;
  final Color aksen;
  final Color onAksen;
  final Color titikMati;

  /// Latar terang: ikon bilah sistem gelap.
  final bool latarTerang;
}

class _Slide {
  final _GayaSlide gaya;
  final String image;
  final String title;
  final String description;

  const _Slide({
    required this.gaya,
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
