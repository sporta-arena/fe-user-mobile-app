import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/sportago_ui.dart';
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

  // Dulu satu foto statis dengan satu kalimat. Sekarang tiga slide
  // berfoto dari keluarga yang sama dengan aplikasi mitra (ComfyUI,
  // lihat assets/images/hero/), urut sesuai perjalanan pemain.
  static const List<_Slide> _slides = [
    _Slide(
      image: 'assets/images/hero/venue.jpg',
      title: 'Cari lapangan\nyang dekat',
      description:
          'Futsal, badminton, basket, mini soccer. Lihat venue di '
          'sekitarmu lengkap dengan jam yang masih kosong.',
    ),
    _Slide(
      image: 'assets/images/hero/main.jpg',
      title: 'Booking dan bayar\ndalam semenit',
      description:
          'Pilih jam, bayar pakai QRIS atau virtual account. '
          'Nggak perlu telepon atau chat admin dulu.',
    ),
    _Slide(
      image: 'assets/images/hero/tiket.jpg',
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
    final pendek = MediaQuery.of(context).size.height < 700;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: KepalaTab.redupFoto,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: KepalaTab.redupFoto,
        body: Stack(
          fit: StackFit.expand,
          children: [
            _buildPhoto(),
            _buildScrim(),
            SafeArea(
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SportagoWordmark(
                        markHeight: 26,
                        fontSize: 15,
                        onMedia: true,
                      ),
                    ),
                  ),
                  Expanded(
                    // Hanya teksnya yang digeser; fotonya berganti lewat
                    // crossfade di belakang, jadi tidak ada jahitan dua
                    // foto yang terlihat di tengah geseran.
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: _slides.length,
                      onPageChanged: _onPageChanged,
                      itemBuilder: (context, i) =>
                          _buildPage(_slides[i], i, pendek),
                    ),
                  ),
                  _buildBottomSection(pendek),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final slide = _slides[_currentPage];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: AnimatedBuilder(
        key: ValueKey(slide.image),
        animation: _zoomController,
        builder: (context, child) => Transform.scale(
          scale: 1.0 + 0.08 * Curves.easeOut.transform(_zoomController.value),
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
      ),
    );
  }

  /// Gelap di atas untuk bilah status dan wordmark, gelap netral di
  /// bawah untuk teks dan tombol. Ujung bawahnya sama persis dengan warna
  /// bilah navigasi supaya tidak ada garis sambungan.
  Widget _buildScrim() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: const [0.0, 0.18, 0.38, 0.62, 1.0],
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.black.withValues(alpha: 0.0),
            KepalaTab.redupFoto.withValues(alpha: 0.05),
            KepalaTab.redupFoto.withValues(alpha: 0.9),
            KepalaTab.redupFoto,
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_Slide slide, int index, bool pendek) {
    final media = context.c.onMedia;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '0${index + 1} / 0${_slides.length}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: media.inkSoft,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            slide.title,
            style: TextStyle(
              fontSize: pendek ? 28 : 34,
              fontWeight: FontWeight.w800,
              color: media.ink,
              letterSpacing: -1.0,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            slide.description,
            style: TextStyle(
              fontSize: pendek ? 14 : 15,
              color: media.inkSoft,
              height: 1.55,
            ),
          ),
          SizedBox(height: pendek ? 16 : 24),
        ],
      ),
    );
  }

  Widget _buildBottomSection(bool pendek) {
    final media = context.c.onMedia;
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
                  color: _currentPage == i
                      ? media.ink
                      : media.ink.withValues(alpha: 0.28),
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

          // Masuk lewat Google baru jalan di Android
          // (Google Sign-In di iOS belum dikonfigurasi).
          if (!Platform.isIOS) ...[
            _AuthButton(
              label: _isGoogleLoading
                  ? 'Menghubungkan…'
                  : 'Lanjut dengan Google',
              background: SportagoColors.pure,
              foreground: KepalaTab.redupFoto,
              height: pendek ? 52 : 56,
              leading: _isGoogleLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: KepalaTab.redupFoto,
                      ),
                    )
                  : Image.asset('assets/google_logo.png', height: 20),
              onPressed: _isGoogleLoading ? () {} : _continueWithGoogle,
            ),
            const SizedBox(height: 10),
          ],

          // Masuk pakai email: tombol utama aksen tema customer
          // (hijau lapangan, volt di tema gelap).
          _AuthButton(
            label: 'Lanjut pakai email',
            background: context.c.accent,
            foreground: context.c.onAccent,
            height: pendek ? 52 : 56,
            trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
            onPressed: _continueWithEmail,
          ),
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

  const _AuthButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onPressed,
    this.height = 56,
    this.leading,
    this.trailing,
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
