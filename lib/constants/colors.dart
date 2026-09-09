import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Jembatan ke sistem tema.
/// ───────────────────────────────────────────────────────────────────
/// Berkas ini dulu memuat TIGA palet yang saling tumpang tindih: kuning
/// merek dari Figma, palet gelap dasbor, dan palet "design" berisi biru
/// `#0047FF`. Nama-namanya dipertahankan karena dipakai di 31 berkas,
/// tapi NILAINYA sekarang diarahkan ke token di [SportagoColors].
/// Efeknya: biru bawaan hilang dari seluruh aplikasi tanpa menyunting
/// satu pun layar.
///
/// Untuk kode baru, JANGAN pakai kelas ini — pakai `context.c`, yang
/// nilainya ikut tema aktif:
///
///   Text('...', style: TextStyle(color: context.c.inkSoft))
///
/// Di Dart, `const Color` tidak bisa ikut tema seperti CSS variable.
/// Jadi nilai di bawah adalah nilai tema TERANG, dan layar yang masih
/// memakainya belum benar-benar mengikuti tema gelap. Daftar layar yang
/// masih perlu disisir ada di README bagian "Sisa migrasi tema".
/// ═══════════════════════════════════════════════════════════════════
class AppColors {
  const AppColors._();

  // ── Merek: tidak ikut tema ───────────────────────────────────────

  /// Warna aksi merek di permukaan gelap.
  ///
  /// Dulu kuning murni `#FFFF21`. Sekarang volt `#C5F400` — nilai yang
  /// sama dengan aksen gelap di fe-web, supaya tombol di app dan di web
  /// benar-benar sewarna. Dipakai di 329 tempat, jadi satu baris ini
  /// menyelaraskan seluruh aplikasi sekaligus.
  ///
  /// Namanya sengaja tidak diubah supaya 31 berkas yang memakainya tidak
  /// perlu disunting. Untuk kode baru pakai `context.c.accent`.
  static const Color brandYellow = SportagoColors.volt;

  /// Kuning splash — TETAP `#FFFF21`. Logo mobile hitam di atas kuning
  /// ini; menggantinya ke volt membuat logonya sedikit meleset dari
  /// asetnya sendiri. Momen splash memang tidak ikut tema.
  static const Color splashYellow = Color(0xFFFFFF21);

  /// Volt — aksen merek waktu tema gelap.
  static const Color accentGreen = SportagoColors.volt;

  static const Color black = Color(0xFF000000);
  static const Color white = SportagoColors.pure;

  /// Tirai di atas foto. Selalu gelap, apa pun temanya.
  static const Color scrim = SportagoColors.scrim;

  // ── Aksi & aksen ─────────────────────────────────────────────────
  // Dulu biru. Sekarang hijau lapangan, sama dengan fe-web.

  static const Color primaryBlue = Color(0xFF00733F);
  static const Color darkBlue = Color(0xFF005730);
  static const Color lightBlue = Color(0xFFEAF4EE);

  // ── Permukaan & teks (nilai tema terang) ─────────────────────────

  static const Color backgroundColor = Color(0xFFFBFCFB);
  static const Color inputBackground = Color(0xFFFFFFFF);
  static const Color fieldFill = Color(0xFFF2F5F3);
  static const Color fieldBorder = Color(0xFFC3D2C9);

  static const Color ink = Color(0xFF101E17);
  static const Color textDark = Color(0xFF101E17);
  static const Color textGray = Color(0xFF4A5C52);
  static const Color textMuted = Color(0xFF7B8A82);
  static const Color textLight = Color(0xFF7B8A82);

  static const Color borderGray = Color(0xFFDEE7E1);
  static const Color dividerGray = Color(0xFFDEE7E1);

  // ── Permukaan gelap ──────────────────────────────────────────────

  static const Color bg = Color(0xFF0A0B0E);
  static const Color surface = Color(0xFF131519);
  static const Color surfaceBorder = Color(0xFF262A31);
  static const Color onDark = Color(0xFFE9ECEF);
  static const Color onDarkMuted = Color(0xFF98A1AB);
}
