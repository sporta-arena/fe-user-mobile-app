import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/notifikasi.dart';
import 'auth_service.dart';

/// Daftar notifikasi dalam aplikasi.
///
/// Layar notifikasi sebelumnya tidak punya lapisan ini sama sekali:
/// `_loadNotifications()` menunggu setengah detik lalu menetapkan daftar
/// kosong, dengan `// TODO: Implement API call` di atasnya. Endpointnya
/// sudah ada sejak lama, dan ikon lonceng di beranda maupun menu
/// Notifikasi di Profil dua-duanya membuka layar itu, jadi seluruh
/// notifikasi yang kita kirim mendarat di daftar yang selamanya kosong.
class NotifikasiService {
  /// Mengambil satu halaman notifikasi, terbaru lebih dulu.
  static Future<({List<Notifikasi> daftar, int belumDibaca})?> ambil() async {
    final token = AuthService.token;
    if (token == null) return null;

    try {
      final response = await http
          .get(Uri.parse(ApiConfig.notificationsUrl),
              headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return null;

      final badan = jsonDecode(response.body);
      if (badan is! Map) return null;

      final isi = badan['data'];
      final daftar = (isi is List)
          ? isi
              .whereType<Map>()
              .map((e) => Notifikasi.dariJson(Map<String, dynamic>.from(e)))
              .toList()
          : <Notifikasi>[];

      return (
        daftar: daftar,
        belumDibaca: (badan['unread_count'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      // null berarti "gagal memuat", berbeda dari daftar kosong yang
      // berarti "memang belum ada notifikasi". Layar memakai bedanya
      // untuk memilih antara pesan galat dan keadaan kosong.
      return null;
    }
  }

  static Future<bool> tandaiDibaca(String id) =>
      _kirim('${ApiConfig.notificationsUrl}/$id/read');

  static Future<bool> tandaiSemuaDibaca() =>
      _kirim('${ApiConfig.notificationsUrl}/read-all');

  static Future<bool> _kirim(String url) async {
    final token = AuthService.token;
    if (token == null) return false;
    try {
      final response = await http
          .post(Uri.parse(url), headers: ApiConfig.authHeaders(token))
          .timeout(const Duration(seconds: 20));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
