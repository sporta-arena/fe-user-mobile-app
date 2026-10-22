import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import 'hero_backdrop.dart';
import 'sportago_mark.dart';

/// Kepala berfoto untuk layar Masuk dan Daftar.
///
/// Fotonya dari keluarga yang sama dengan onboarding (dan dengan layar
/// Masuk aplikasi mitra), jadi pindah dari slide terakhir ke form terasa
/// satu alur. Bawahnya pekat supaya kartu form yang menumpang punya
/// tepi yang jelas.
class KepalaFotoAuth extends StatelessWidget {
  const KepalaFotoAuth({
    super.key,
    required this.judul,
    this.foto = 'assets/images/hero/login.jpg',
    this.onKembali,
  });

  final String judul;
  final String foto;

  /// Tombol kembali di pojok kiri atas. Kosong berarti tidak ada tombol.
  final VoidCallback? onKembali;

  @override
  Widget build(BuildContext context) {
    final media = context.c.onMedia;
    final size = MediaQuery.of(context).size;
    final tinggi = (size.height * 0.34).clamp(240.0, 320.0);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: SizedBox(
        height: tinggi,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(foto, fit: BoxFit.cover, excludeFromSemantics: true),
            // Atas gelap untuk bilah status, bawah pekat untuk tulisan.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    HeroBackdrop.base.withValues(alpha: 0.15),
                    HeroBackdrop.base.withValues(alpha: 0.9),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                bottom: 48,
                left: 24,
                right: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (onKembali != null) ...[
                        Material(
                          color: SportagoColors.pure.withValues(alpha: 0.14),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: onKembali,
                            tooltip: 'Kembali',
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: media.ink,
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const SportagoWordmark(
                        markHeight: 26,
                        fontSize: 15,
                        onMedia: true,
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    judul,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      height: 1.15,
                      color: media.ink,
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

/// Gaya bilah sistem untuk layar yang kepalanya foto gelap tapi badannya
/// permukaan tema: ikon bilah status selalu terang, bilah navigasi ikut
/// permukaan supaya warna pekat onboarding tidak terbawa ke bawah form.
SystemUiOverlayStyle gayaOverlayKepalaFoto(BuildContext context) {
  final gelap = Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: context.c.surface,
    systemNavigationBarIconBrightness: gelap
        ? Brightness.light
        : Brightness.dark,
  );
}
