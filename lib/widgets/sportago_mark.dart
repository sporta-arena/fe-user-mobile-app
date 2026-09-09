import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Lambang Sportago yang ikut warna aksen tema.
///
/// Asetnya (`assets/sportago_mark.png`) adalah topeng satu warna di atas
/// transparan, jadi bisa diwarnai ulang saat render — tidak perlu aset
/// terpisah per tema. Berkasnya sama persis dengan yang dipakai aplikasi
/// mitra, supaya kedua aplikasi benar-benar satu merek.
class SportagoMark extends StatelessWidget {
  const SportagoMark({super.key, this.height = 40, this.onMedia = false});

  final double height;

  /// Setel true kalau lambangnya duduk di atas foto atau bidang
  /// berwarna. Warnanya diambil dari palet "di atas media" — cukup
  /// terang untuk terbaca, tapi tetap sekeluarga dengan aksen halaman.
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    final warna = onMedia ? context.c.onMedia.accent : context.c.accent;
    return Image.asset(
      'assets/sportago_mark.png',
      height: height,
      color: warna,
      colorBlendMode: BlendMode.srcIn,
      // Asetnya ~341 px sementara di layar dipakai 28-96 px logis; tanpa
      // mipmap, penyusutan sebesar itu berkerut.
      filterQuality: FilterQuality.medium,
      // Lambang adalah hiasan; namanya sudah disebut wordmark di
      // sebelahnya, jadi tidak perlu diumumkan dua kali.
      excludeFromSemantics: true,
    );
  }
}

/// Lambang + tulisan "SPORTAGO", disusun mendatar.
///
/// Tulisannya dirender sebagai teks, bukan gambar — sama seperti di
/// fe-web, supaya warnanya ikut tema dan tidak ada aset yang harus
/// dibuat ulang tiap kali warnanya berubah.
class SportagoWordmark extends StatelessWidget {
  const SportagoWordmark({
    super.key,
    this.markHeight = 40,
    this.fontSize = 26,
    this.onMedia = false,
  });

  final double markHeight;
  final double fontSize;
  final bool onMedia;

  @override
  Widget build(BuildContext context) {
    final c = onMedia ? context.c.onMedia : context.c;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SportagoMark(height: markHeight, onMedia: onMedia),
        SizedBox(width: markHeight * 0.28),
        Text(
          'SPORTAGO',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
            color: c.ink,
          ),
        ),
      ],
    );
  }
}
