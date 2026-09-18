import 'package:flutter/material.dart';

import '../models/filter_venue.dart';
import 'hasil_filter_page.dart';

/// Daftar venue untuk satu cabang olahraga.
///
/// Sebelum 18 Sep 2026 layar ini 1275 baris dengan penyaring versinya
/// sendiri — harga, kota, fasilitas, rating, pengurutan — dan SEMUANYA
/// dijalankan di aplikasi, di atas 15 venue yang sudah dipotong server.
/// Dengan satu venue hasilnya benar; dengan dua ratus, "di bawah 100rb"
/// menyembunyikan lapangan murah yang kebetulan ada di halaman tiga.
///
/// Ia juga menembak satu permintaan HTTP PER VENUE hanya untuk membaca
/// harga lapangannya, padahal min_price sudah ikut di respons pertama.
///
/// Sekarang layar ini cuma [HasilFilterPage] dengan cabang olahraganya
/// dipilihkan di depan. Penyaringnya satu, perilakunya satu, dan
/// menambah penyaring baru cukup di satu tempat.
class CategoryVenuesPage extends StatelessWidget {
  const CategoryVenuesPage({
    super.key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.showAllVenues = false,
    this.fieldType,
  });

  final String categoryName;

  /// Tidak dipakai lagi; dipertahankan supaya pemanggil lama tetap jalan.
  final IconData categoryIcon;
  final Color categoryColor;

  final bool showAllVenues;
  final String? fieldType;

  @override
  Widget build(BuildContext context) {
    return HasilFilterPage(
      judul: showAllVenues ? 'Semua Arena' : categoryName,
      filterAwal: FilterVenue(olahraga: showAllVenues ? null : fieldType),
    );
  }
}
