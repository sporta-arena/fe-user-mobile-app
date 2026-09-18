import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/banner_promo.dart';
import 'auth_service.dart';

/// Hasil pemeriksaan kode promo.
class HasilPromo {
  const HasilPromo({
    required this.kode,
    required this.judul,
    required this.potongan,
  });

  final String kode;
  final String judul;
  final double potongan;
}

/// Memeriksa kode promo sebelum pemesan menekan Bayar.
///
/// Hasilnya bukan jaminan: yang mengikat tetap pemeriksaan server di
/// dalam transaksi pemesanan, karena kuota bisa habis di sela keduanya.
/// Gunanya supaya potongannya terlihat di rincian biaya lebih dulu —
/// tanpa itu pemesan baru tahu kodenya ditolak setelah pemesanannya
/// gagal seluruhnya.
class PromoService {
  /// Mengembalikan [HasilPromo] kalau berlaku, atau melempar
  /// [PromoDitolak] berisi alasan yang layak dibaca pemesan.
  static Future<HasilPromo> cek({
    required String kode,
    required int fieldId,
    required String tanggal,
    required String jamMulai,
    required int durasiJam,
  }) async {
    final token = AuthService.token;
    if (token == null) {
      throw const PromoDitolak('Masuk dulu untuk memakai kode promo.');
    }

    late final http.Response respons;
    try {
      respons = await http
          .post(
            Uri.parse(ApiConfig.cekPromoUrl),
            headers: ApiConfig.authHeaders(token),
            body: jsonEncode({
              'kode': kode.trim(),
              'field_id': fieldId,
              'booking_date': tanggal,
              'start_time': jamMulai,
              'duration_hours': durasiJam,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (_) {
      throw const PromoDitolak('Gagal menghubungi server. Coba lagi.');
    }

    final badan = jsonDecode(respons.body) as Map<String, dynamic>;

    if (respons.statusCode == 401) {
      // Token kedaluwarsa. Pesan mentah server berbunyi
      // "Unauthenticated." dan itu bukan kalimat untuk pemesan.
      throw const PromoDitolak(
        'Sesi kamu habis. Masuk lagi untuk memakai kode promo.',
      );
    }

    if (respons.statusCode != 200) {
      // Server menjelaskan sebabnya — promonya belum mulai, tidak
      // berlaku di venue itu, di luar jam, atau kuotanya habis.
      // Pesannya diteruskan apa adanya; "kode tidak valid" membuat orang
      // mencoba berulang kali tanpa tahu apa yang salah.
      throw PromoDitolak(
        badan['message']?.toString() ?? 'Kode promo tidak berlaku.',
      );
    }

    final data = badan['data'] as Map<String, dynamic>;
    return HasilPromo(
      kode: data['kode']?.toString() ?? kode.toUpperCase(),
      judul: data['judul']?.toString() ?? '',
      potongan: double.tryParse(data['potongan'].toString()) ?? 0,
    );
  }
}

class PromoDitolak implements Exception {
  const PromoDitolak(this.pesan);

  final String pesan;

  @override
  String toString() => pesan;
}

/// Promo yang sedang berjalan, untuk layar "Semua Promo".
///
/// Terpisah dari /banners: tidak semua promo punya banner, dan kode yang
/// dibagikan lewat WhatsApp tetap harus bisa ditemukan di sini.
extension PromoBerjalan on PromoService {
  static Future<List<RingkasPromo>> ambil() async {
    try {
      final respons = await http
          .get(
            Uri.parse(ApiConfig.promosUrl),
            headers: ApiConfig.defaultHeaders,
          )
          .timeout(const Duration(seconds: 15));
      if (respons.statusCode != 200) return const [];
      final data = (jsonDecode(respons.body)['data'] as List?) ?? const [];
      return data
          .map((e) => RingkasPromo.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
