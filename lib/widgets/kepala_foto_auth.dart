import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_tokens.dart';

/// Kepala layar Masuk dan Daftar: panel kuning merek dengan tepi bawah
/// miring, lambang + "SPORTAGO" hitam, sapaan besar, dan foto pemain
/// sebagai kartu kecil miring yang menempel di tepi panel.
///
/// Sengaja bukan "foto selebar layar di atas form": itu pola layar
/// Masuk app mitra. Customer memakai warna logonya sendiri (kuning di
/// atas hitam), dan fotonya cuma aksen.
class KepalaFotoAuth extends StatelessWidget {
  const KepalaFotoAuth({
    super.key,
    required this.judul,
    this.foto = 'assets/images/hero/masuk.jpg',
    this.onKembali,
  });

  /// Sapaan besar di panel kuning.
  final String judul;
  final String foto;

  /// Tombol kembali di pojok kiri atas. Kosong berarti tidak ada tombol.
  final VoidCallback? onKembali;

  /// Tinta di atas panel kuning. Tidak ikut tema: panelnya selalu
  /// kuning, jadi teksnya selalu hitam.
  static const Color _tinta = Color(0xFF111111);

  /// Kemiringan tepi bawah panel dan kartu foto.
  static const double _miring = 44;

  @override
  Widget build(BuildContext context) {
    final atas = MediaQuery.of(context).padding.top;
    final lebar = MediaQuery.of(context).size.width;
    final tinggiPanel = atas + 236;
    final lebarFoto = (lebar * 0.3).clamp(104.0, 136.0);
    final tinggiFoto = lebarFoto * 1.3;

    return SizedBox(
      height: tinggiPanel + 26,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: tinggiPanel,
            child: ClipPath(
              clipper: _TepiMiring(_miring),
              child: const ColoredBox(color: SportagoColors.kuning),
            ),
          ),
          Positioned(
            left: 24,
            right: lebarFoto + 36,
            top: atas + 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 44,
                  child: onKembali == null
                      ? null
                      : Material(
                          color: _tinta.withValues(alpha: 0.08),
                          shape: const CircleBorder(),
                          child: IconButton(
                            onPressed: onKembali,
                            tooltip: 'Kembali',
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: _tinta,
                              size: 22,
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Lambang berwarna penuh punya isian kuning yang
                    // lenyap di panel kuning, jadi dipakai topengnya
                    // yang diwarnai hitam.
                    Image.asset(
                      'assets/sportago_mark.png',
                      height: 30,
                      color: _tinta,
                      colorBlendMode: BlendMode.srcIn,
                      filterQuality: FilterQuality.medium,
                      excludeFromSemantics: true,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'SPORTAGO',
                      style: TextStyle(
                        fontFamily: 'Archivo',
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: -0.5,
                        color: _tinta,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  judul,
                  style: const TextStyle(
                    fontFamily: 'Archivo',
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    letterSpacing: -1,
                    height: 1.05,
                    color: _tinta,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 24,
            bottom: 0,
            child: Transform.rotate(
              angle: 6 * math.pi / 180,
              child: Container(
                width: lebarFoto,
                height: tinggiFoto,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: SportagoColors.pure,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _tinta.withValues(alpha: 0.22),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(17),
                  child: Image.asset(
                    foto,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Memotong tepi bawah jadi garis miring: kiri lebih rendah dari kanan.
class _TepiMiring extends CustomClipper<Path> {
  const _TepiMiring(this.miring);

  final double miring;

  @override
  Path getClip(Size size) => Path()
    ..lineTo(size.width, 0)
    ..lineTo(size.width, size.height - miring)
    ..lineTo(0, size.height)
    ..close();

  @override
  bool shouldReclip(_TepiMiring old) => old.miring != miring;
}

/// Gaya bilah sistem untuk layar berkepala kuning: ikon bilah status
/// gelap di atas panel kuning, bilah navigasi ikut permukaan tema.
SystemUiOverlayStyle gayaOverlayKepalaFoto(BuildContext context) {
  final gelap = Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: context.c.surface,
    systemNavigationBarIconBrightness: gelap
        ? Brightness.light
        : Brightness.dark,
  );
}
