import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/banner_promo.dart';

class BannerService {
  /// Banner yang sedang tayang. Daftar kosong kalau tidak ada — dan
  /// beranda menyembunyikan seluruh bagiannya, bukan menampilkan kotak
  /// kosong.
  static Future<List<BannerPromo>> ambil() async {
    try {
      final respons = await http
          .get(
            Uri.parse(ApiConfig.bannersUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (respons.statusCode != 200) return const [];

      final data = (jsonDecode(respons.body)['data'] as List?) ?? const [];
      return data
          .map((e) => BannerPromo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Banner itu hiasan. Gagal memuatnya tidak boleh membuat beranda
      // gagal, jadi kegagalannya diam-diam berarti tidak ada banner.
      return const [];
    }
  }
}
