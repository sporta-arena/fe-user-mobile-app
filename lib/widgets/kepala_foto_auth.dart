import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';
import 'sportago_mark.dart';

/// Kepala berfoto untuk layar Masuk dan Daftar.
///
/// Foto pemain siang yang terang (bukan foto lapangan malam milik app
/// mitra), sudut bawah membulat, ujung bawahnya memudar ke permukaan
/// tema. Judulnya duduk di permukaan di bawah foto dengan tinta biasa,
/// jadi form langsung menyambung tanpa kartu yang menumpang.
class KepalaFotoAuth extends StatelessWidget {
  const KepalaFotoAuth({
    super.key,
    required this.judul,
    this.foto = 'assets/images/hero/masuk.jpg',
    this.onKembali,
  });

  final String judul;
  final String foto;

  /// Tombol kembali di pojok kiri atas. Kosong berarti tidak ada tombol.
  final VoidCallback? onKembali;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final size = MediaQuery.of(context).size;
    final tinggi = (size.height * 0.3).clamp(220.0, 280.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: tinggi,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(32),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  foto,
                  fit: BoxFit.cover,
                  excludeFromSemantics: true,
                ),
                // Bayangan tipis di atas untuk bilah status, pudar ke
                // permukaan di bawah.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.3, 0.7, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.black.withValues(alpha: 0.0),
                        c.surface.withValues(alpha: 0.0),
                        c.surface.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 12,
                    left: 20,
                    right: 20,
                  ),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Row(
                      children: [
                        if (onKembali != null) ...[
                          Material(
                            color: c.raised,
                            shape: const CircleBorder(),
                            child: IconButton(
                              onPressed: onKembali,
                              tooltip: 'Kembali',
                              icon: Icon(
                                Icons.arrow_back_rounded,
                                color: c.ink,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: c.raised,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const SportagoWordmark(
                            markHeight: 20,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          child: Text(
            judul,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              height: 1.15,
              color: c.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Gaya bilah sistem untuk layar berkepala foto: ikon bilah status
/// terang di atas bayangan tipis ujung foto, bilah navigasi ikut
/// permukaan tema.
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
