import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../utils/tampilan_venue.dart';

/// Foto sampul venue, atau penggantinya kalau mitranya belum mengunggah.
///
/// Sebelumnya layar konfirmasi memasang satu foto rumput dari Unsplash
/// untuk venue apa pun, dan kartu tanpa foto jatuh ke kotak abu-abu yang
/// sama untuk semuanya. Dua-duanya membuat venue kehilangan wajahnya.
///
/// Penggantinya sengaja tidak menyamar sebagai foto: bidang warna dari
/// palet kategori plus inisial venue membuat tiap venue terlihat berbeda,
/// jujur bahwa fotonya belum ada, dan memberi mitra alasan mengunggah
/// yang asli. Nama venue sudah dibacakan oleh judul kartunya, jadi bidang
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

  /// Hitam merek atau putih, mana pun yang rasio kontrasnya lebih tinggi
  /// di atas [latar]. Rumusnya WCAG 2.1: (L terang + 0,05) / (L gelap + 0,05).
  static Color _tintaTerbaca(Color latar) {
    const gelap = Color(0xFF101E17);
    final l = latar.computeLuminance();
    final rasioPutih = 1.05 / (l + 0.05);
    final rasioGelap = (l + 0.05) / (gelap.computeLuminance() + 0.05);
    return rasioPutih >= rasioGelap ? Colors.white : gelap;
  }

  Widget _pengganti(BuildContext context) {
    final warna = context.c.kategori(indeksWarnaVenue(nama));
    // Palet kategori tema terang gelap-gelap, tema gelap terang-terang.
    // Tinta putih yang dipatok akan jatuh ke 2,2:1 di atas amber tema
    // gelap, jadi rasio kedua kandidat benar-benar dihitung dan yang
    // menang yang dipakai.
    final tinta = _tintaTerbaca(warna);
    return ExcludeSemantics(
      child: Container(
        width: lebar,
        height: tinggi,
        color: warna,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              ikonOlahraga(olahraga),
              size: ukuranInisial * 0.8,
              color: tinta.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 2),
            Text(
              inisialVenue(nama),
              style: TextStyle(
                color: tinta,
                fontSize: ukuranInisial,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
