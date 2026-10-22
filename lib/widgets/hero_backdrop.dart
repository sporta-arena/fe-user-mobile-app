import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Latar hijau pekat untuk layar pembuka: splash, onboarding, dan kepala
/// layar Masuk.
///
/// Render 3D di `assets/images/hero/` dibuat transparan dengan bayangan
/// di kanal alfa, jadi warnanya datang dari sini, bukan dipanggang ke
/// gambar. Ketiga layar memakai widget yang sama supaya perpindahan
/// splash → onboarding → Masuk tidak berkedip ganti warna.
class HeroBackdrop extends StatelessWidget {
  const HeroBackdrop({
    super.key,
    required this.child,
    this.glowAt = const Alignment(0, -0.35),
  });

  final Widget child;

  /// Titik pusat cahaya, diletakkan di belakang render.
  final Alignment glowAt;

  /// Warna dasar latar. Juga dipakai bilah status dan sambungan ke
  /// panel lain supaya tidak ada garis beda warna.
  static const Color base = SportagoColors.pekat;
  static const Color glow = Color(0xFF17633F);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: RadialGradient(
          center: glowAt,
          radius: 0.9,
          colors: const [glow, base],
        ),
      ),
      child: child,
    );
  }
}
