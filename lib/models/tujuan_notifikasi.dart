/// Tujuan yang benar-benar bisa dibuka aplikasi pemesan dari sebuah
/// tautan notifikasi.
///
/// Satu tabel notifikasi dipakai dua aplikasi, dan tautan mitra
/// (`/dashboard/...`) ikut tersimpan di sana. Tanpa penyaring, ketukan
/// pada notifikasi mitra akan membuka layar yang salah atau tidak ada.
///
/// Sengaja hanya sampai daftar pesanan, bukan ke satu booking
/// tertentu: aplikasi pemesan memang belum punya layar detail booking
/// yang bisa dibuka lewat id. Mengantar ke daftar itu jujur; berpura-pura
/// membuka booking tertentu lalu menampilkan daftar tidak.
enum TujuanNotifikasi { bookingSaya, tidakAda }

TujuanNotifikasi tujuanDariTautan(String? tautan) {
  final bersih = tautan?.trim() ?? '';
  if (bersih.isEmpty) return TujuanNotifikasi.tidakAda;
  if (bersih == '/my-bookings' || bersih.startsWith('/my-bookings/')) {
    return TujuanNotifikasi.bookingSaya;
  }
  return TujuanNotifikasi.tidakAda;
}
