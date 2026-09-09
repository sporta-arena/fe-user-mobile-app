import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

/// Kebijakan refund yang berlaku, dibaca dari server.
///
/// Sengaja tidak menyimpan tier persentase apa pun: **tidak ada jalur
/// refund dari sisi pemesan**, dan itu memang desainnya — backend
/// menyatakannya lewat `customer_can_request: false` di
/// `GET /refund-policy`.
///
/// Sebelumnya app ini menghitung sendiri tier 100% / 50% berdasarkan
/// jarak waktu ke jadwal, lalu memanggil `POST /bookings/{id}/refund`.
/// Rute itu tidak pernah ada di backend, jadi tombolnya selalu berakhir
/// 404 — dan tier-nya pun fiksi.
class KebijakanRefund {
  const KebijakanRefund({
    required this.pemesanBisaMengajukan,
    required this.mitraBisaMengajukan,
    required this.pesan,
  });

  /// Selalu false pada desain sekarang; tetap dibaca dari server supaya
  /// app tidak perlu dirilis ulang kalau kebijakannya berubah.
  final bool pemesanBisaMengajukan;

  /// Refund yang dimulai mitra. Saat mati, refund ditangani manual oleh
  /// admin Sportago.
  final bool mitraBisaMengajukan;

  final String pesan;

  factory KebijakanRefund.fromJson(Map<String, dynamic> json) {
    return KebijakanRefund(
      pemesanBisaMengajukan: json['customer_can_request'] == true,
      mitraBisaMengajukan: json['partner_initiated_enabled'] == true,
      pesan: (json['message'] as String?) ?? '',
    );
  }

  /// Dipakai kalau server tidak terjangkau. Menutup jalur pengajuan
  /// adalah sikap yang aman: lebih baik pemesan diarahkan menghubungi
  /// venue daripada menekan tombol yang pasti gagal.
  static const KebijakanRefund tertutup = KebijakanRefund(
    pemesanBisaMengajukan: false,
    mitraBisaMengajukan: false,
    pesan: 'Refund diproses oleh tim Sportago. Hubungi venue atau '
        'support untuk pengajuan.',
  );
}

class RefundService {
  /// Ambil kebijakan refund yang berlaku.
  ///
  /// Tidak pernah melempar: kalau gagal, mengembalikan
  /// [KebijakanRefund.tertutup].
  static Future<KebijakanRefund> ambilKebijakan() async {
    final token = AuthService.token;
    if (token == null) return KebijakanRefund.tertutup;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.refundPolicyUrl),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) return KebijakanRefund.tertutup;

      return KebijakanRefund.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    } catch (_) {
      return KebijakanRefund.tertutup;
    }
  }

  /// Perkiraan nominal refund untuk satu booking.
  ///
  /// Ini satu-satunya endpoint refund sisi pemesan yang benar-benar ada
  /// (`GET /bookings/{id}/refund-preview`). Sifatnya informasi saja —
  /// tidak mengajukan apa pun.
  static Future<Map<String, dynamic>?> ambilPerkiraan(int bookingId) async {
    final token = AuthService.token;
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.refundPreviewUrl(bookingId)),
        headers: ApiConfig.authHeaders(token),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return data is Map<String, dynamic> ? (data['data'] ?? data) : null;
    } catch (_) {
      return null;
    }
  }
}
