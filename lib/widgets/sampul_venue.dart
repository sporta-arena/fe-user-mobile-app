import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../utils/tampilan_venue.dart';

/// Foto sampul venue, atau penggantinya kalau mitranya belum mengunggah.
///
/// Sebelumnya layar konfirmasi memasang satu foto rumput dari Unsplash
/// untuk venue apa pun, dan kartu tanpa foto jatuh ke kotak abu-abu yang
/// sama untuk semuanya. Dua-duanya membuat venue kehilangan wajahnya.
///
/// Penggantinya sengaja tidak menyamar sebagai foto: bidang hitam merek
/// dengan inisial kuning, plus pita bawah dari palet kategori supaya
/// venue yang bersebelahan tetap terbedakan. Jujur bahwa fotonya belum
/// ada, dan memberi mitra alasan mengunggah yang asli. Nama venue sudah dibacakan oleh judul kartunya, jadi bidang
/// ini disembunyikan dari pembaca layar.
class SampulVenue extends StatelessWidget {
  final String nama;
  final String? urlGambar;
  final String? olahraga;
  final double? lebar;
  final double? tinggi;
  final double ukuranInisial;
  final BorderRadius? radius;

  const SampulVenue({
    super.key,
    required this.nama,
    this.urlGambar,
    this.olahraga,
    this.lebar,
    this.tinggi,
    this.ukuranInisial = 24,
    this.radius,
  });

  @override
  Widget build(BuildContext context) {
    final isi = (urlGambar != null && urlGambar!.isNotEmpty)
        ? Image.network(
            urlGambar!,
            width: lebar,
            height: tinggi,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _pengganti(context),
          )
        : _pengganti(context);

    if (radius == null) return isi;
    return ClipRRect(borderRadius: radius!, child: isi);
  }

  Widget _pengganti(BuildContext context) {
    final pita = context.c.kategori(indeksWarnaVenue(nama));
    // Hitam merek, bukan bidang warna kategori: kartu tanpa foto dulu
    // tampil teal/tembaga yang terbaca sebagai sisa tema lama di antara
    // kartu kuning-hitam. Warna kategori tinggal pita tipis di bawah.
    final latar = SportagoColors.light.ink;
    return ExcludeSemantics(
      child: Container(
        width: lebar,
        height: tinggi,
        decoration: BoxDecoration(
          color: latar,
          border: Border(bottom: BorderSide(color: pita, width: 4)),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ikonOlahraga(olahraga),
              size: ukuranInisial * 0.8,
              color: SportagoColors.kuning.withValues(alpha: 0.75),
            ),
            const SizedBox(height: 2),
            Text(
              inisialVenue(nama),
              style: TextStyle(
                color: SportagoColors.kuning,
                fontSize: ukuranInisial,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
