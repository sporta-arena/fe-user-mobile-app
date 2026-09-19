import 'package:package_info_plus/package_info_plus.dart';

/// Versi aplikasi, dibaca dari paketnya sendiri.
///
/// Sebelumnya nomor versi ditulis tangan di dua tempat — menu "Tentang
/// Sportago" di Profil dan halaman Tentang itu sendiri. Dua-duanya
/// berhenti di "1.0.0" sementara aplikasinya sudah 1.1.0, dan tidak ada
/// yang mengingatkan waktu pubspec naik. Nomor yang salah di layar
/// "Tentang" justru paling merepotkan: itu yang ditanyakan pertama kali
/// waktu ada laporan bug.
class VersiApp {
  const VersiApp._();

  static String _versi = '';
  static String _build = '';

  /// Dipanggil sekali saat aplikasi mulai.
  static Future<void> muat() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _versi = info.version;
      _build = info.buildNumber;
    } catch (_) {
      // Biarkan kosong; pemanggil menampilkan teks cadangan.
    }
  }

  /// "1.1.0", atau string kosong kalau belum termuat.
  static String get nomor => _versi;

  /// "Versi 1.1.0 (2)" untuk ditampilkan apa adanya.
  static String get tampil {
    if (_versi.isEmpty) return 'Versi -';
    return _build.isEmpty ? 'Versi $_versi' : 'Versi $_versi ($_build)';
  }
}
