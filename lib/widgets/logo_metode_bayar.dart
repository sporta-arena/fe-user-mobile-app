import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Logo metode bayar: QRIS resmi, lainnya wordmark berwarna merek.
///
/// Sama dengan PaymentMethodLogo di web. Bank dan e-wallet sengaja
/// digambar sebagai teks berwarna, bukan berkas logo asli, supaya tidak
/// perlu lisensi merek; yang dikenali pelanggan adalah warnanya. Kode
/// yang belum dikenal jatuh ke ikon kategori, bukan kotak kosong.
class LogoMetodeBayar extends StatelessWidget {
  final String kode;
  final String? kategori;
  final double lebar;
  final double tinggi;

  const LogoMetodeBayar({
    super.key,
    required this.kode,
    this.kategori,
    this.lebar = 52,
    this.tinggi = 34,
  });

  static const _merek = <String, (Color, Color, String)>{
    'ovo': (Color(0xFF4C2A86), Colors.white, 'OVO'),
    'gopay': (Colors.white, Color(0xFF00AED6), 'gopay'),
    'dana': (Color(0xFF118EEA), Colors.white, 'DANA'),
    'shopeepay': (Color(0xFFEE4D2D), Colors.white, 'ShopeePay'),
    'va_bca': (Color(0xFF005BAA), Colors.white, 'BCA'),
    'va_bni': (Color(0xFFF26522), Colors.white, 'BNI'),
    'va_bri': (Color(0xFF00529C), Colors.white, 'BRI'),
    'va_mandiri': (Color(0xFF003D79), Color(0xFFFFD800), 'mandiri'),
    'va_permata': (Color(0xFFE11D2A), Colors.white, 'Permata'),
    'va_cimb': (Color(0xFFED1C24), Colors.white, 'CIMB'),
    'va_bsi': (Color(0xFF00A39D), Colors.white, 'BSI'),
    'va_bnc': (Color(0xFFF9D100), Color(0xFF1A1A1A), 'neo'),
    'va_maybank': (Color(0xFFFFC709), Color(0xFF1A1A1A), 'Maybank'),
    'va_artha_graha': (Color(0xFF8A6D3B), Colors.white, 'AG'),
    'va_sampoerna': (Color(0xFFC8102E), Colors.white, 'Sampoerna'),
    'doku_checkout': (Color(0xFFE1251B), Colors.white, 'DOKU'),
  };

  @override
  Widget build(BuildContext context) {
    final k = kode.toLowerCase();
    final radius = BorderRadius.circular(10);

    if (k == 'qris') {
      return Container(
        width: lebar,
        height: tinggi,
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: Colors.black12),
        ),
        child: Image.asset(
          'assets/qris_logo.png',
          fit: BoxFit.contain,
          semanticLabel: 'QRIS',
        ),
      );
    }

    final merek = _merek[k];
    if (merek == null) {
      return Container(
        width: lebar,
        height: tinggi,
        decoration: BoxDecoration(
          color: context.c.sunken,
          borderRadius: radius,
        ),
        child: Icon(
          switch (kategori) {
            'ewallet' => Icons.account_balance_wallet,
            'va' => Icons.account_balance,
            _ => Icons.payment,
          },
          size: 20,
          color: context.c.inkSoft,
        ),
      );
    }

    final (latar, tulisan, teks) = merek;
    return Container(
      width: lebar,
      height: tinggi,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: latar,
        borderRadius: radius,
        border: latar == Colors.white
            ? Border.all(color: Colors.black12)
            : null,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          teks,
          semanticsLabel: teks,
          style: TextStyle(
            color: tulisan,
            fontWeight: FontWeight.w900,
            fontSize: 13,
            letterSpacing: -0.3,
          ),
        ),
      ),
    );
  }
}
