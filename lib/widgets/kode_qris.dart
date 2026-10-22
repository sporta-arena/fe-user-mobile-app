import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
  bool _menyimpan = false;

  /// Gambar QR untuk disimpan, dibuat langsung dari datanya.
  ///
  /// Tidak memotret widget di layar: QR-nya digambar ulang di kanvas
  /// putih dengan bingkai, jadi hasilnya selalu utuh walau sebagian
  /// widget sedang tergulir keluar layar.
  Future<List<int>> _gambarPng(String qr) async {
    const sisi = 900.0;
    const bingkai = 60.0;
    final perekam = ui.PictureRecorder();
    final kanvas = Canvas(perekam);
    kanvas.drawRect(
      const Rect.fromLTWH(0, 0, sisi + bingkai * 2, sisi + bingkai * 2),
      Paint()..color = Colors.white,
    );
    kanvas.translate(bingkai, bingkai);
    QrPainter(
      data: qr,
      version: QrVersions.auto,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
      ),
    ).paint(kanvas, const Size(sisi, sisi));
    final gambar = await perekam.endRecording().toImage(
      (sisi + bingkai * 2).toInt(),
      (sisi + bingkai * 2).toInt(),
    );
    final png = await gambar.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw StateError('gambar PNG kosong');
    return png.buffer.asUint8List();
  }

  Future<void> _simpan(BuildContext konteksTombol, String qr) async {
    setState(() => _menyimpan = true);
    try {
      final png = await _gambarPng(qr);
      final folder = await getTemporaryDirectory();
      final berkas = File(
        '${folder.path}/qris-sportago-${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await berkas.writeAsBytes(png);

      // Titik asal lembar bagikan diambil dari tombol yang baru ditekan,
      // bukan dari seluruh widget. iOS menolak titik asal yang keluar
      // dari layar, dan widget QR bisa lebih tinggi dari layar atau
      // sebagian tergulir; itu yang dulu membuat simpan selalu gagal.
      final kotak = konteksTombol.findRenderObject() as RenderBox?;
      await Share.shareXFiles(
        [XFile(berkas.path, mimeType: 'image/png')],
        text: 'QRIS pembayaran Sportago',
        sharePositionOrigin: kotak == null
            ? null
            : kotak.localToGlobal(Offset.zero) & kotak.size,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('QR gagal disimpan: $e')));
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
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // QR wajib gelap di atas terang apa pun temanya.
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
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
        const SizedBox(height: 10),
        Text(
          'Scan dengan aplikasi e-wallet atau m-banking',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: context.c.inkSoft),
        ),
        const SizedBox(height: 10),
        Builder(
          builder: (konteksTombol) => OutlinedButton.icon(
            onPressed: _menyimpan ? null : () => _simpan(konteksTombol, qr),
            icon: _menyimpan
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download_rounded, size: 18),
            label: const Text('Simpan QR'),
          ),
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
