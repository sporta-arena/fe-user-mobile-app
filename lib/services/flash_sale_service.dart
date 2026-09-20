import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/flash_sale.dart';

class FlashSaleService {
  /// Flash sale yang sedang berjalan di sekitar [lat]/[lng].
  ///
  /// Lokasinya dikirim sebagai parameter dan TIDAK disimpan server —
  /// penyaringan radius dilakukan di sana supaya kuota pemesan tidak
  /// habis untuk venue lintas kota yang tidak pernah ditampilkan.
  ///
  /// Sama seperti banner: kegagalannya diam-diam berarti "tidak ada
  /// flash sale", dan beranda menyembunyikan seluruh bagiannya. Flash
  /// sale itu tawaran tambahan; gagal memuatnya tidak boleh membuat
  /// beranda ikut gagal.
  static Future<List<FlashSaleBerjalan>> ambil({
    double? lat,
    double? lng,
    double radiusKm = 25,
  }) async {
    try {
      final params = <String, String>{'limit': '10'};
      if (lat != null && lng != null) {
        params['latitude'] = lat.toString();
        params['longitude'] = lng.toString();
        params['radius_km'] = radiusKm.toString();
      }

      final respons = await http
          .get(
            Uri.parse(ApiConfig.flashSalesUrl).replace(queryParameters: params),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 15));

      if (respons.statusCode != 200) return const [];

      final data = (jsonDecode(respons.body)['data'] as List?) ?? const [];
      return data
          .whereType<Map>()
          .map((e) => FlashSaleBerjalan.fromJson(e.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
