import 'package:flutter/foundation.dart';

/// Pilihan penyaring pencarian venue.
///
/// Semua isinya dikirim apa adanya ke server. Tidak ada satu pun yang
/// disaring di aplikasi: daftar venue dipotong 15 per halaman, jadi
/// menyaring hasil yang sudah terpotong membuang venue yang sebenarnya
/// cocok tapi kebetulan ada di halaman berikutnya — tanpa galat, dan
/// tanpa ada yang tahu.
@immutable
class FilterVenue {
  const FilterVenue({
    this.olahraga,
    this.hargaMin,
    this.hargaMaks,
    this.ratingMin,
    this.radiusKm,
    this.tersedia,
    this.urutkan,
  });

  /// Nilai `type` lapangan, mis. `futsal`. Null berarti semua cabang.
  final String? olahraga;

  final int? hargaMin;
  final int? hargaMaks;

  /// 4.0 berarti "rating 4 ke atas".
  final double? ratingMin;

  final double? radiusKm;

  /// `hari_ini`, `besok`, atau `akhir_pekan`.
  final String? tersedia;

  /// `terdekat`, `termurah`, `termahal`, `rating`.
  final String? urutkan;

  bool get kosong =>
      olahraga == null &&
      hargaMin == null &&
      hargaMaks == null &&
      ratingMin == null &&
      radiusKm == null &&
      tersedia == null &&
      urutkan == null;

  /// Berapa penyaring yang sedang menyala, untuk lencana di tombolnya.
  /// Pengurutan tidak ikut dihitung: ia selalu punya nilai dan bukan
  /// penyaring, jadi menghitungnya membuat lencana menyala terus.
  int get jumlahAktif => [
    olahraga,
    hargaMin,
    hargaMaks,
    ratingMin,
    radiusKm,
    tersedia,
  ].where((e) => e != null).length;

  FilterVenue salin({
    Object? olahraga = _tetap,
    Object? hargaMin = _tetap,
    Object? hargaMaks = _tetap,
    Object? ratingMin = _tetap,
    Object? radiusKm = _tetap,
    Object? tersedia = _tetap,
    Object? urutkan = _tetap,
  }) {
    return FilterVenue(
      olahraga: olahraga == _tetap ? this.olahraga : olahraga as String?,
      hargaMin: hargaMin == _tetap ? this.hargaMin : hargaMin as int?,
      hargaMaks: hargaMaks == _tetap ? this.hargaMaks : hargaMaks as int?,
      ratingMin: ratingMin == _tetap ? this.ratingMin : ratingMin as double?,
      radiusKm: radiusKm == _tetap ? this.radiusKm : radiusKm as double?,
      tersedia: tersedia == _tetap ? this.tersedia : tersedia as String?,
      urutkan: urutkan == _tetap ? this.urutkan : urutkan as String?,
    );
  }

  /// Penanda "jangan ubah nilai ini".
  ///
  /// `salin(olahraga: null)` harus berarti MENGOSONGKAN, bukan
  /// mempertahankan — dan `??` tidak bisa membedakan keduanya.
  static const Object _tetap = Object();
}
