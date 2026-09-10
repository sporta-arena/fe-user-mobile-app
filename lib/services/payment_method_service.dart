import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

/// Satu metode pembayaran, apa adanya dari server.
class MetodePembayaran {
  const MetodePembayaran({
    required this.kode,
    required this.label,
    required this.kategori,
    required this.biaya,
    required this.jenisBiaya,
    required this.nilaiBiaya,
  });

  final String kode;
  final String label;

  /// 'qris', 'ewallet', 'va', atau 'card'.
  final String kategori;

  /// Biaya untuk jumlah yang diminta, SUDAH dihitung server.
  final int biaya;

  final String jenisBiaya;
  final double nilaiBiaya;

  factory MetodePembayaran.fromJson(Map<String, dynamic> j) => MetodePembayaran(
        kode: (j['code'] ?? '').toString(),
        label: (j['label'] ?? '').toString(),
        kategori: (j['category'] ?? '').toString(),
        biaya: (j['fee'] as num?)?.toInt() ?? 0,
        jenisBiaya: (j['fee_type'] ?? '').toString(),
        nilaiBiaya: (j['fee_value'] as num?)?.toDouble() ?? 0,
      );

  /// Keterangan singkat untuk kartu pilihan.
  String get keterangan {
    switch (kategori) {
      case 'qris':
        return 'Scan QR via e-wallet atau m-banking';
      case 'ewallet':
        return 'Bayar langsung dari aplikasi $label';
      case 'va':
        return 'Transfer via ATM atau m-Banking';
      default:
        return '';
    }
  }

  IconData get ikon {
    switch (kategori) {
      case 'qris':
        return Icons.qr_code_2;
      case 'ewallet':
        return Icons.account_balance_wallet;
      case 'va':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }
}

/// Metode pembayaran yang benar-benar bisa dipakai, langsung dari server.
///
/// Sebelumnya daftar ini ditulis keras di layar konfirmasi, lengkap dengan
/// salinan biayanya sendiri. Isinya tiga belas metode padahal backend
/// hanya bisa membuat lima: lima Virtual Account belum ada kodenya,
/// LinkAja belum punya biaya, dan Alfamart serta Indomaret bahkan tidak
/// dikenal backend. Pelanggan bisa memilih jalan buntu, dan biaya yang
/// ditampilkan tidak dijamin sama dengan yang ditagih.
class PaymentMethodService {
  static Future<List<MetodePembayaran>> ambil({required int jumlah}) async {
    final url = Uri.parse('${ApiConfig.apiUrl}/payment-methods?amount=$jumlah');
    final token = AuthService.token;
    if (token == null) {
      throw Exception('Perlu masuk dulu untuk melihat metode pembayaran');
    }

    final r = await http.get(url, headers: ApiConfig.authHeaders(token));

    if (r.statusCode != 200) {
      throw Exception('Gagal memuat metode pembayaran (${r.statusCode})');
    }

    final daftar = (jsonDecode(r.body) as Map<String, dynamic>)['payment_methods'];
    if (daftar is! List) return const [];

    return daftar
        .whereType<Map>()
        .map((m) => MetodePembayaran.fromJson(m.cast<String, dynamic>()))
        .toList();
  }
}
