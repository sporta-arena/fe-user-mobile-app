import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

/// Langganan pesan chat lewat WebSocket (Laravel Reverb).
///
/// Chat di Sportago tidak memakai polling: pesan baru didorong server
/// lewat kanal privat `private-booking.{id}`. Reverb berbicara protokol
/// Pusher, dan yang dipakai di sini hanya bagian kecilnya — sambung,
/// otorisasi kanal, berlangganan, dengarkan satu event — jadi cukup
/// ditulis langsung di atas `web_socket_channel` tanpa SDK tambahan.
///
/// Alurnya:
///   1. sambung ke ws://host/app/{key}
///   2. server mengirim `pusher:connection_established` berisi socket_id
///   3. socket_id ditukar ke `POST /broadcasting/auth` dengan bearer token
///      Sanctum yang sama seperti REST
///   4. kirim `pusher:subscribe` dengan tanda tangan itu
///   5. setiap `message.sent` diteruskan ke pemanggil
///
/// Kalau sambungan putus, ia menyambung ulang sendiri dengan jeda yang
/// membesar bertahap.
class RealtimeChat {
  RealtimeChat._(this._bookingId, this._onPesan, this._onStatus);

  final int _bookingId;
  final void Function(Map<String, dynamic> pesan) _onPesan;
  final void Function(bool tersambung)? _onStatus;

  WebSocketChannel? _kanal;
  StreamSubscription<dynamic>? _langganan;
  Timer? _sambungUlang;
  bool _ditutup = false;
  int _percobaan = 0;

  /// socket_id sambungan aktif.
  ///
  /// Dikirim sebagai header `X-Socket-ID` saat mengirim pesan lewat REST
  /// supaya server tidak menyiarkan balik pesan kita sendiri — kalau
  /// tidak, pesan yang baru saja kita kirim akan muncul dua kali.
  String? socketId;

  /// Mulai mendengarkan pesan baru pada satu booking.
  static RealtimeChat dengarkan(
    int bookingId, {
    required void Function(Map<String, dynamic> pesan) onPesan,
    void Function(bool tersambung)? onStatus,
  }) {
    final klien = RealtimeChat._(bookingId, onPesan, onStatus);
    klien._sambung();
    return klien;
  }

  void _sambung() {
    if (_ditutup) return;

    try {
      _kanal = WebSocketChannel.connect(Uri.parse(ApiConfig.reverbUrl));
    } catch (_) {
      _jadwalkanSambungUlang();
      return;
    }

    _langganan = _kanal!.stream.listen(
      _tanganiBingkai,
      onDone: _jadwalkanSambungUlang,
      onError: (_) => _jadwalkanSambungUlang(),
      cancelOnError: true,
    );
  }

  Future<void> _tanganiBingkai(dynamic bingkai) async {
    Map<String, dynamic> amplop;
    try {
      amplop = json.decode(bingkai as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final event = amplop['event'] as String?;

    // Muatan Pusher dikirim sebagai string JSON di dalam JSON.
    Map<String, dynamic> muatan() {
      final data = amplop['data'];
      if (data is String) {
        try {
          return json.decode(data) as Map<String, dynamic>;
        } catch (_) {
          return const {};
        }
      }
      return data is Map<String, dynamic> ? data : const {};
    }

    switch (event) {
      case 'pusher:connection_established':
        socketId = muatan()['socket_id'] as String?;
        _percobaan = 0;
        await _langgananKanal();
        break;

      case 'pusher:ping':
        _kirim({'event': 'pusher:pong', 'data': {}});
        break;

      case 'pusher_internal:subscription_succeeded':
        _onStatus?.call(true);
        break;

      case 'message.sent':
        _onPesan(muatan());
        break;
    }
  }

  Future<void> _langgananKanal() async {
    final id = socketId;
    final token = AuthService.token;
    if (id == null || token == null) return;

    final kanal = 'private-booking.$_bookingId';

    try {
      final respons = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'socket_id': id, 'channel_name': kanal}),
      );

      if (respons.statusCode != 200) {
        _onStatus?.call(false);
        return;
      }

      final auth = (json.decode(respons.body) as Map<String, dynamic>)['auth'];
      _kirim({
        'event': 'pusher:subscribe',
        'data': {'channel': kanal, 'auth': auth},
      });
    } catch (_) {
      _onStatus?.call(false);
    }
  }

  void _kirim(Map<String, dynamic> muatan) {
    try {
      _kanal?.sink.add(json.encode(muatan));
    } catch (_) {
      // Sambungan sudah tutup; _jadwalkanSambungUlang yang menangani.
    }
  }

  void _jadwalkanSambungUlang() {
    if (_ditutup) return;

    _onStatus?.call(false);
    socketId = null;
    _langganan?.cancel();
    _langganan = null;
    _kanal = null;

    // 1, 2, 4, 8 ... maksimal 30 detik. Jeda yang membesar mencegah
    // aplikasi menghantam server saat jaringan benar-benar mati.
    final detik = (1 << _percobaan).clamp(1, 30);
    _percobaan = (_percobaan + 1).clamp(0, 5);

    _sambungUlang?.cancel();
    _sambungUlang = Timer(Duration(seconds: detik), _sambung);
  }

  /// Berhenti mendengarkan dan tutup sambungan.
  void tutup() {
    _ditutup = true;
    _sambungUlang?.cancel();
    _langganan?.cancel();
    try {
      _kanal?.sink.close();
    } catch (_) {
      // Tidak apa-apa kalau sudah tertutup duluan.
    }
    _kanal = null;
  }
}
