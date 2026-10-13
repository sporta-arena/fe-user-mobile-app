import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_tokens.dart';

/// QR QRIS yang benar-benar bisa dipindai, dari qr_string gateway.
///
/// Dulu halaman Transaksi menggambar ikon Icons.qr_code_2 bertuliskan
/// "SCAN ME" lalu mencetak string mentahnya, dan halaman Booking Saya
/// mencetak string 200 karakter itu sebagai teks tebal. Keduanya mustahil
/// dipindai. Widget ini dipakai di layar konfirmasi, Transaksi, dan
/// Booking Saya supaya ketiganya sama.
///
/// Tombol simpan ada karena pelanggan yang membayar dari HP yang sama
/// tidak bisa memindai layarnya sendiri: QR disimpan ke galeri lalu
/// dipilih lewat "scan dari galeri" di aplikasi e-wallet atau m-banking.
class KodeQris extends StatefulWidget {
  final String? qrString;
  final double ukuran;

  const KodeQris({super.key, required this.qrString, this.ukuran = 220});

  @override
  State<KodeQris> createState() => _KodeQrisState();
}

class _KodeQrisState extends State<KodeQris> {
  final _kunciGambar = GlobalKey();
  bool _menyimpan = false;

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      final boundary =
          _kunciGambar.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) throw StateError('QR belum tergambar');

      final gambar = await boundary.toImage(pixelRatio: 3);
      final png = await gambar.toByteData(format: ui.ImageByteFormat.png);
      if (png == null) throw StateError('Gagal membuat gambar');

      final folder = await getTemporaryDirectory();
      final berkas = File(
        '${folder.path}/qris-sportago-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await berkas.writeAsBytes(png.buffer.asUint8List());

      if (!mounted) return;
      final kotak = context.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(berkas.path, mimeType: 'image/png')],
        text: 'QRIS pembayaran Sportago',
        // iPad butuh titik asal untuk lembar bagikan.
        sharePositionOrigin: kotak == null
            ? null
            : kotak.localToGlobal(Offset.zero) & kotak.size,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('QR gagal disimpan. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final qr = widget.qrString?.trim() ?? '';
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
        RepaintBoundary(
          key: _kunciGambar,
          child: Container(
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
              size: widget.ukuran,
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
        ),
        const SizedBox(height: 10),
        Text(
          'Scan dengan aplikasi e-wallet atau m-banking',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.c.inkSoft),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _menyimpan ? null : _simpan,
          icon: _menyimpan
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.download_rounded, size: 18),
          label: const Text('Simpan QR'),
        ),
        const SizedBox(height: 4),
        Text(
          'Bayar dari HP ini? Simpan QR, lalu pilih "scan dari galeri" '
          'di aplikasi pembayaran.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.c.inkDim),
        ),
      ],
    );
  }
}
