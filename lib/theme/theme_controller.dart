import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Pengendali tema aplikasi.
///
/// Semantiknya disamakan dengan fe-web: selama pengguna belum pernah
/// memilih, aplikasi ikut setelan sistem ([ThemeMode.system]). Begitu
/// tombolnya ditekan, pilihannya jadi eksplisit dan disimpan — sistem
/// tidak lagi menimpanya.
///
/// Sengaja pakai [ValueNotifier], bukan paket state management: yang
/// dibutuhkan cuma satu nilai global yang bisa didengarkan, dan proyek
/// ini belum memakai paket semacam itu di tempat lain.
class ThemeController extends ValueNotifier<ThemeMode> {
  ThemeController._() : super(ThemeMode.system);

  static final ThemeController instance = ThemeController._();

  /// Nama kunci sengaja sama dengan yang dipakai fe-web supaya konsep
  /// dan istilahnya tidak bercabang antar permukaan.
  static const _kunci = 'sportago-theme';

  bool _sudahDimuat = false;
  bool get sudahDimuat => _sudahDimuat;

  /// Dipanggil sekali sebelum runApp. Kalau gagal dibaca, aplikasi
  /// tetap jalan dengan mengikuti setelan sistem — preferensi tampilan
  /// tidak pernah boleh jadi alasan aplikasi gagal start.
  Future<void> muat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      switch (prefs.getString(_kunci)) {
        case 'light':
          value = ThemeMode.light;
        case 'dark':
          value = ThemeMode.dark;
        default:
          value = ThemeMode.system;
      }
    } catch (_) {
      value = ThemeMode.system;
    } finally {
      _sudahDimuat = true;
    }
  }

  Future<void> setel(ThemeMode mode) async {
    if (value == mode) return;
    value = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mode == ThemeMode.system) {
        await prefs.remove(_kunci);
      } else {
        await prefs.setString(
          _kunci,
          mode == ThemeMode.dark ? 'dark' : 'light',
        );
      }
    } catch (_) {
      // Gagal menyimpan bukan alasan membatalkan perubahan yang sudah
      // terlihat di layar; pilihannya cuma tidak bertahan setelah
      // aplikasi ditutup.
    }
  }

  /// Apakah tampilan yang SEDANG terlihat gelap — termasuk waktu
  /// modenya masih mengikuti sistem.
  bool gelapEfektif(BuildContext context) {
    switch (value) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
    }
  }

  /// Bolak-balik terang ↔ gelap. Dari mode sistem, lompatannya ke
  /// kebalikan dari yang sedang terlihat, bukan ke nilai tetap —
  /// supaya sekali tekan selalu terasa mengubah sesuatu.
  Future<void> ganti(BuildContext context) =>
      setel(gelapEfektif(context) ? ThemeMode.light : ThemeMode.dark);
}
