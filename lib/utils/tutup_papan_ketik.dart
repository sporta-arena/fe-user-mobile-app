import 'package:flutter/widgets.dart';

/// Menutup papan ketik saat pemesan menyentuh area kosong.
///
/// Tanpa ini sebuah bidang teks bisa mengunci layar. Satu-satunya jalan
/// keluar bawaan adalah tombol return, dan pada bidang banyak-baris
/// tombol itu justru menambah baris. iOS memang tidak punya tombol
/// kembali sama sekali, tapi Android pun tidak menyelamatkan: di Galaxy
/// A35 bilah tiga tombolnya ikut tersembunyi saat papan ketik naik.
///
/// Terlihat 18 Sep 2026 di bidang Catatan pada layar pembayaran: papan
/// ketiknya menutupi setengah layar dan tidak ada cara membuangnya.
///
/// Dipasang di akar MaterialApp, bukan per layar, supaya tidak ada
/// bidang teks baru yang lolos hanya karena layarnya lupa dibungkus.
///
/// `translucent` membuatnya tetap menerima sentuhan di ruang kosong
/// tanpa merebut sentuhan milik anaknya: dalam arena gestur Flutter
/// tombol atau bidang teks yang lebih dalam selalu menang, jadi
/// mengetuk tombol tetap menekan tombol, dan mengetuk bidang teks
/// tetap memindahkan fokus ke sana.
class TutupPapanKetik extends StatelessWidget {
  const TutupPapanKetik({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
      child: child,
    );
  }
}
