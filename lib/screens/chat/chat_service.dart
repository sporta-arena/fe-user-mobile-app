import '../../services/auth_service.dart';
import '../../config/api_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'chat_models.dart';

/// Isi satu percakapan berikut keadaannya.
///
/// Riwayat saja tidak cukup: chat terkunci begitu booking selesai atau
/// dibatalkan, dan layar perlu tahu itu sebelum pemakai mengetik. Aturan
/// penguncinya ditentukan server lewat `can_send`, tidak disalin ke sini,
/// supaya tidak ada dua versi aturan yang bisa melenceng.
class IsiPercakapan {
  const IsiPercakapan({required this.pesan, required this.bolehKirim});

  final List<Message> pesan;
  final bool bolehKirim;

  /// Dipakai waktu pemuatan gagal: tidak ada pesan, dan kolom ketik
  /// ditutup sampai keadaannya benar-benar diketahui.
  static const IsiPercakapan kosong =
      IsiPercakapan(pesan: <Message>[], bolehKirim: false);
}

class ChatService {
  // Get messages for a specific booking
  static Future<IsiPercakapan> getMessages(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/messages'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> messages = data['data'] ?? [];
        return IsiPercakapan(
          pesan: messages.map((m) => Message.fromJson(m)).toList(),
          bolehKirim: data['can_send'] == true,
        );
      }
      return IsiPercakapan.kosong;
    } catch (e) {
      return IsiPercakapan.kosong;
    }
  }

  // Send a message
  //
  // [socketId] adalah socket_id sambungan WebSocket yang sedang aktif.
  // Server memakainya untuk TIDAK menyiarkan balik pesan ini ke
  // pengirim. Tanpa itu, pesan yang baru dikirim muncul dua kali: sekali dari
  // balasan REST, sekali lagi dari kanal WebSocket.
  static Future<Message?> sendMessage(
    int bookingId,
    String content, {
    String? socketId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/messages'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
          if (socketId != null) 'X-Socket-ID': socketId,
        },
        body: json.encode({
          'content': content,
          'type': 'text',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return Message.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get partner contact info for a booking
  static Future<PartnerContact?> getPartnerContact(int bookingId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/partner'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PartnerContact.fromJson(data['data']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Tandai pesan dari mitra sebagai sudah dibaca.
  static Future<bool> markAsRead(int bookingId) async {
    try {
      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/bookings/$bookingId/messages/read'),
        headers: {
          'Authorization': 'Bearer ${AuthService.token}',
          'Content-Type': 'application/json',
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
