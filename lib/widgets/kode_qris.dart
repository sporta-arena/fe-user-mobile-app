import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../theme/app_tokens.dart';

/// QR QRIS yang benar-benar bisa dipindai, dari qr_string gateway.
///
/// Dulu halaman Transaksi menggambar ikon Icons.qr_code_2 bertuliskan
/// "SCAN ME" lalu mencetak string mentahnya, dan halaman Booking Saya
/// mencetak string 200 karakter itu sebagai teks tebal. Keduanya mustahil
/// dipindai. Layar konfirmasi pesanan sudah memakai QrImageView; widget
/// ini menyamakan ketiganya.
class KodeQris extends StatelessWidget {
  final String? qrString;
  final double ukuran;

  const KodeQris({super.key, required this.qrString, this.ukuran = 220});

  @override
  Widget build(BuildContext context) {
    final qr = qrString?.trim() ?? '';
    if (qr.isEmpty) {
      return Text(
        'Kode QR belum diterima dari server. Tarik ke bawah untuk memuat '
        'ulang, atau buat ulang pemesanan.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: context.c.danger),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // QR wajib gelap di atas terang apa pun temanya.
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.line),
          ),
          child: QrImageView(
            data: qr,
            version: QrVersions.auto,
            size: ukuran,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Scan dengan aplikasi e-wallet atau m-banking',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.c.inkSoft),
        ),
      ],
    );
  }
}
