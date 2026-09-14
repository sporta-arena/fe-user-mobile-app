import 'package:flutter/services.dart';

/// Menolak spasi, tab, dan baris baru saat diketik.
///
/// Spasi di kata sandi nyaris selalu tidak disengaja: terbawa saat
/// menyalin-tempel, atau terpencet di ujung. Akibatnya baru terasa jauh
/// kemudian, waktu mitra yakin kata sandinya benar tapi tidak bisa
/// masuk, dan tidak ada layar yang bisa memberitahunya bahwa masalahnya
/// satu karakter tak terlihat.
///
/// Ditolak di titik pengetikan, bukan dipangkas diam-diam saat
/// disimpan. Dipangkas berarti yang tersimpan berbeda dari yang
/// diketik, dan mitra tetap tidak tahu apa yang terjadi.
class TanpaSpasi extends TextInputFormatter {
  const TanpaSpasi();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue lama,
    TextEditingValue baru,
  ) {
    final bersih = baru.text.replaceAll(RegExp(r'\s'), '');

    if (bersih == baru.text) return baru;

    // Kursor dimundurkan sebanyak karakter yang dibuang sebelum
    // posisinya. Tanpa koreksi ini huruf berikutnya masuk di tengah
    // kata sandi tanpa mitra menyadarinya.
    final sebelumKursor = baru.text.substring(0, baru.selection.baseOffset);
    final dibuang = sebelumKursor.length -
        sebelumKursor.replaceAll(RegExp(r'\s'), '').length;

    final posisi =
        (baru.selection.baseOffset - dibuang).clamp(0, bersih.length);

    return TextEditingValue(
      text: bersih,
      selection: TextSelection.collapsed(offset: posisi),
      composing: TextRange.empty,
    );
  }
}
