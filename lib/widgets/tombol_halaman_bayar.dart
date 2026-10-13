import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../theme/app_tokens.dart';

/// Tombol membuka halaman bayar gateway (e-wallet atau DOKU Checkout).
///
/// Tautannya disimpan server di payment.checkout_url, jadi pelanggan yang
/// kembali lewat Transaksi atau kartu "Selesaikan pembayaran" tetap bisa
/// melanjutkan. Dulu halaman itu cuma mengenal QRIS dan VA, dan metode
/// lain jatuh ke tampilan "Nomor Virtual Account" yang kosong.
class TombolHalamanBayar extends StatelessWidget {
  final String url;
  final String keterangan;

  const TombolHalamanBayar({
    super.key,
    required this.url,
    this.keterangan =
        'Pilih cara bayar di halaman DOKU: VA bank lain, '
        'e-wallet, minimarket, PayLater, atau kartu.',
  });

  Future<void> _buka(BuildContext context) async {
    final uri = Uri.tryParse(url);
    final bisa =
        uri != null &&
        await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!bisa && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Halaman pembayaran tidak bisa dibuka.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          keterangan,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.c.inkSoft),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _buka(context),
            icon: Icon(Icons.open_in_new, size: 18, color: context.c.onAccent),
            label: Text(
              'Lanjutkan Pembayaran',
              style: TextStyle(
                color: context.c.onAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.c.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Setelah membayar, kembali ke aplikasi. Status pesanan diperbarui '
          'otomatis.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.c.inkDim),
        ),
      ],
    );
  }
}
