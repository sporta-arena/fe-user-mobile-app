import 'dart:math' as math;

import 'package:flutter/widgets.dart';

extension SisipanBawah on BuildContext {
  /// Jarak aman dari tepi bawah layar, untuk lembar dan tombol yang
  /// menempel di bawah.
  ///
  /// Sejak targetSdk 35 Android memaksa aplikasi menggambar sampai tepi
  /// layar, jadi bilah navigasi tidak lagi menyisakan ruang dengan
  /// sendirinya: ia menumpuk di atas apa pun yang ada di bawahnya.
  /// Tombol simpan yang sebelumnya terlihat baik-baik saja jadi
  /// tertindih separuh, dan di HP bergestur ia justru bertabrakan
  /// dengan garis geser.
  ///
  /// Diambil yang terbesar antara dua sisipan, bukan dijumlahkan:
  ///
  /// - `viewPadding.bottom` ruang bilah navigasi, tetap ada selama
  ///   bilahnya ada.
  /// - `viewInsets.bottom` tinggi papan ketik, nol selama ia tertutup.
  ///
  /// Waktu papan ketik naik ia menutupi bilah navigasi, jadi ruangnya
  /// sudah terhitung sekali di dalam `viewInsets`. Menjumlahkan
  /// keduanya menyisakan celah kosong setinggi bilah di atas papan
  /// ketik.
  ///
  /// Nol di perangkat yang tidak punya bilah menumpuk, jadi aman
  /// dipakai tanpa syarat.
  double get sisipanBawah => math.max(
    MediaQuery.viewInsetsOf(this).bottom,
    MediaQuery.viewPaddingOf(this).bottom,
  );
}
