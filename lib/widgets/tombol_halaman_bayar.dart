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

  /// true untuk DOKU Checkout (halaman DOKU di browser, didahului
  /// penjelasan); false untuk e-wallet yang membuka aplikasi dompetnya.
  final bool lewatDoku;

  const TombolHalamanBayar({
    super.key,
    required this.url,
    this.lewatDoku = true,
  });

  String get _keterangan => lewatDoku
      ? 'Pembayaran dilanjutkan di halaman DOKU yang terbuka di browser. '
            'Di sana kamu bisa pilih VA bank lain, e-wallet, minimarket, '
            'PayLater, atau kartu.'
      : 'Pembayaran dilanjutkan di aplikasi e-wallet kamu.';

  /// Penjelasan singkat sebelum aplikasi berganti ke browser.
  ///
  /// Tanpa ini pelanggan mendadak berada di halaman DOKU yang asing,
  /// mengira tersasar, lalu menutupnya.
  Future<bool> _setuju(BuildContext context) async {
    final hasil = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lanjut ke halaman DOKU'),
        content: const Text(
          'Pembayaran dilanjutkan di halaman resmi DOKU, mitra pembayaran '
          'Sportago, yang terbuka di browser.\n\n'
          'Pilih cara bayar di sana. Setelah selesai, kembali ke aplikasi '
          'Sportago: status pesananmu diperbarui otomatis.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Buka halaman DOKU'),
          ),
        ],
      ),
    );
    return hasil ?? false;
  }

  Future<void> _buka(BuildContext context) async {
    if (lewatDoku && (!await _setuju(context) || !context.mounted)) return;
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
          _keterangan,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: context.c.inkSoft),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () => _buka(context),
            // Warna dari tema: aksen hijau di terang, volt di gelap.
            icon: const Icon(Icons.open_in_new, size: 18),
            label: Text(
              lewatDoku ? 'Bayar di halaman DOKU' : 'Lanjutkan Pembayaran',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Setelah membayar, kembali ke aplikasi Sportago. Status pesanan '
          'diperbarui otomatis. Selesaikan dalam 10 menit.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.c.inkDim),
        ),
      ],
    );
  }
}
