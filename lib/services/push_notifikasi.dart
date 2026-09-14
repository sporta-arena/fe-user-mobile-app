import 'dart:convert';

import 'package:flutter/material.dart' show Color;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

/// Nama kanal privat notifikasi milik satu pengguna.
///
/// Harus sama persis dengan yang diotorisasi di routes/channels.php
/// (`App.Models.User.{id}`). Salah satu huruf saja dan langganannya
/// ditolak tanpa pesan yang jelas di sisi klien: sambungannya terbuka,
/// tapi tidak ada event yang pernah datang.
String namaKanalPengguna(Object idPengguna) =>
    'private-App.Models.User.$idPengguna';

/// Nama event notifikasi, dipatok di server lewat broadcastType().
const String namaEventNotifikasi = 'notifikasi.baru';

/// Apakah token perlu didaftarkan ulang ke server.
///
/// Aplikasi memanggil pendaftaran tiap kali dibuka. Mengirim ulang
/// token yang sama berarti satu permintaan jaringan sia-sia di setiap
/// pembukaan, seumur hidup pemasangan. Tapi Firebase memutar tokennya
/// sendiri, dan token baru yang tidak dilaporkan membuat server terus
/// menembak token mati: pemesan berhenti menerima notifikasi tanpa
/// tahu sebabnya.
bool perluDaftarUlang({required String? tokenLama, required String? tokenBaru}) {
  if (tokenBaru == null || tokenBaru.isEmpty) return false;

  return tokenLama != tokenBaru;
}

/// Satu pesan push yang sudah dibaca isinya.
class PesanPush {
  const PesanPush({
    required this.judul,
    required this.isi,
    this.tipe,
    this.tautan,
  });

  final String judul;
  final String isi;
  final String? tipe;
  final String? tautan;

  /// Baca dari muatan pesan.
  ///
  /// Setiap field dibaca dengan cadangan. Server boleh menambah jenis
  /// notifikasi baru kapan saja, dan aplikasi yang sudah terpasang di
  /// HP orang tidak ikut diperbarui: satu field yang belum dikenal
  /// tidak boleh membuat notifikasinya hilang.
  factory PesanPush.dariData({
    required String? judul,
    required String? isi,
    required Map<String, dynamic> data,
  }) {
    final tautan = data['link']?.toString();

    return PesanPush(
      judul: (judul == null || judul.isEmpty) ? 'Pemberitahuan baru' : judul,
      isi: isi ?? '',
      tipe: _atauNull(data['type']),
      // String kosong bukan tautan. Memperlakukannya sebagai tautan
      // membuat aplikasi membuka layar kosong saat diketuk.
      tautan: (tautan == null || tautan.isEmpty) ? null : tautan,
    );
  }

  static String? _atauNull(Object? nilai) {
    final teks = nilai?.toString();

    return (teks == null || teks.isEmpty) ? null : teks;
  }
}

/// Warna yang dipakai Android untuk mewarnai ikon notifikasi.
///
/// Sama dengan warna_notifikasi di res/values/colors.xml, yang dipakai
/// untuk pesan yang datang saat aplikasi tidak berjalan. Dua tempat
/// karena dua jalur penampil yang berbeda, dan nilainya harus sama:
/// kalau berbeda, notifikasi berubah warna tergantung aplikasinya
/// sedang terbuka atau tidak.
const Color _warnaMerek = Color(0xFF00693C);

const String _kunciTokenTerdaftar = 'fcm_token_terdaftar';

/// Saluran notifikasi Android.
///
/// Android menolak menampilkan notifikasi prioritas tinggi tanpa kanal
/// yang dideklarasikan lebih dulu, dan menolaknya diam-diam.
const AndroidNotificationChannel _kanalPenting = AndroidNotificationChannel(
  'sportago_penting',
  'Pemesanan',
  description: 'Pemberitahuan pembayaran, jadwal, dan pembatalan.',
  importance: Importance.high,
);

/// Push notification untuk aplikasi pemesan.
class PushNotifikasi {
  static final FlutterLocalNotificationsPlugin _lokal =
      FlutterLocalNotificationsPlugin();

  static bool _siap = false;

  /// Siapkan izin, saluran, dan pendengar pesan.
  ///
  /// Dipanggil sesudah pemesan masuk: sebelum itu tidak ada pengguna
  /// yang bisa dikaitkan dengan tokennya, dan mendaftarkan token tanpa
  /// pemilik hanya menghasilkan baris yatim di server.
  static Future<void> siapkan({void Function(PesanPush)? saatDiketuk}) async {
    if (_siap) return;
    _siap = true;

    await FirebaseMessaging.instance.requestPermission();

    await _lokal.initialize(
      const InitializationSettings(
        // Siluet lambang Sportago, bukan ikon peluncur: ikon
        // status bar hanya memakai kanal alfa, jadi ikon
        // berwarna tampil sebagai bulatan putih tanpa bentuk.
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (respons) {
        final muatan = respons.payload;
        if (muatan == null || saatDiketuk == null) return;
        final data = jsonDecode(muatan) as Map<String, dynamic>;
        saatDiketuk(PesanPush.dariData(
          judul: data['title']?.toString(),
          isi: data['body']?.toString(),
          data: data,
        ));
      },
    );

    await _lokal
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_kanalPenting);

    // Saat aplikasi terbuka, Android tidak menampilkan apa pun sendiri.
    FirebaseMessaging.onMessage.listen(_tampilkan);

    if (saatDiketuk != null) {
      FirebaseMessaging.onMessageOpenedApp.listen((pesan) {
        saatDiketuk(PesanPush.dariData(
          judul: pesan.notification?.title,
          isi: pesan.notification?.body,
          data: pesan.data,
        ));
      });
    }

    await daftarkanToken();

    FirebaseMessaging.instance.onTokenRefresh.listen(_kirimToken);
  }

  /// Daftarkan token perangkat ini ke server.
  static Future<void> daftarkanToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    final prefs = await SharedPreferences.getInstance();

    if (!perluDaftarUlang(
      tokenLama: prefs.getString(_kunciTokenTerdaftar),
      tokenBaru: token,
    )) {
      return;
    }

    await _kirimToken(token!);
  }

  static Future<void> _kirimToken(String token) async {
    final auth = AuthService.token;
    if (auth == null) return;

    try {
      final respons = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/perangkat'),
        headers: ApiConfig.authHeaders(auth),
        body: jsonEncode({'token': token, 'platform': 'android'}),
      );

      if (respons.statusCode >= 200 && respons.statusCode < 300) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kunciTokenTerdaftar, token);
      }
    } catch (_) {
      // Gagal mendaftar bukan alasan menggagalkan pembukaan aplikasi.
      // Token tidak disimpan, jadi percobaan berikutnya mengirim lagi.
    }
  }

  /// Lepaskan perangkat ini saat pemesan keluar akun.
  ///
  /// Tanpa ini, HP yang sudah logout terus menerima notifikasi pemilik
  /// akun sebelumnya, termasuk kode pemesanan dan nominal uang.
  static Future<void> lepaskan() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_kunciTokenTerdaftar);
    final auth = AuthService.token;
    if (token == null) return;

    if (auth != null) {
      try {
        await http.delete(
          Uri.parse('${ApiConfig.baseUrl}/perangkat'),
          headers: ApiConfig.authHeaders(auth),
          body: jsonEncode({'token': token}),
        );
      } catch (_) {
        // Diabaikan: keluar akun tidak boleh gagal karena ini.
      }
    }

    await prefs.remove(_kunciTokenTerdaftar);
  }

  static Future<void> _tampilkan(RemoteMessage pesan) async {
    final notif = pesan.notification;
    if (notif == null) return;

    await _lokal.show(
      pesan.hashCode,
      notif.title,
      notif.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _kanalPenting.id,
          _kanalPenting.name,
          channelDescription: _kanalPenting.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
          color: _warnaMerek,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode({
        ...pesan.data,
        'title': notif.title,
        'body': notif.body,
      }),
    );
  }
}
