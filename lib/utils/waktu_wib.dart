/// Konversi jam-dalam-hari dari API ke WIB untuk DITAMPILKAN.
///
/// Kontraknya sama dengan fe-web (`formatTime` di `src/utils/index.ts`):
/// backend menyimpan jam operasional dan slot sebagai waktu UTC, dan
/// setiap permukaan menambahkan +7 saat menampilkannya.
///
/// App mobile sebelumnya menampilkan nilai mentah, jadi venue yang di web
/// tertulis buka 08.00–22.00 muncul sebagai 01.00–15.00 di HP — dan slot
/// booking pun ikut meleset tujuh jam.
///
/// PENTING: ini hanya untuk tampilan. Nilai yang dikirim balik ke API
/// (`start_time` waktu membuat booking) harus tetap nilai mentah dari
/// server, jangan yang sudah digeser.
class WaktuWib {
  const WaktuWib._();

  static const int offsetJam = 7;

  /// "01:00:00" atau "01:00" → "08:00".
  ///
  /// Bertahan terhadap nilai rusak: kalau tidak bisa dibaca, string
  /// aslinya dikembalikan apa adanya daripada membuat layar gagal render.
  static String tampil(String? jam) {
    if (jam == null || jam.isEmpty) return '';
    final bagian = jam.split(':');
    if (bagian.length < 2) return jam;
    final j = int.tryParse(bagian[0]);
    final m = int.tryParse(bagian[1]);
    if (j == null || m == null) return jam;
    final jWib = (((j + offsetJam) % 24) + 24) % 24;
    return '${jWib.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  /// "01:00:00" + "15:00:00" → "08:00 - 22:00".
  static String rentang(String? mulai, String? selesai) =>
      '${tampil(mulai)} - ${tampil(selesai)}';
}
