/// Cara nilai mentah dari API ditampilkan ke pengguna.
///
/// API mengirim kota sebagai nilai enum snake_case (`jakarta_selatan`,
/// `kabupaten_bogor`). Beberapa layar sudah menambalnya sendiri dengan
/// `replaceAll('_', ' ')`, tapi beranda, discover, dan peta belum, jadi
/// pengguna masih melihat `jakarta_selatan` apa adanya.
library;

const Map<String, String> _kota = {
  'bogor': 'Bogor Kota',
  'kabupaten_bogor': 'Kabupaten Bogor',
  'depok': 'Depok',
  'jakarta_selatan': 'Jakarta Selatan',
  'tangerang': 'Tangerang',
};

/// Nilai enum kota jadi teks yang layak dibaca.
///
/// Mengembalikan string kosong kalau kotanya tidak diketahui. Sengaja
/// TIDAK memakai nilai bawaan seperti "Jakarta": menebak kota venue orang
/// lain lebih buruk daripada tidak menampilkan apa-apa.
String formatKota(String? kota) {
  if (kota == null || kota.trim().isEmpty) return '';
  final kunci = kota.trim().toLowerCase();
  final cocok = _kota[kunci];
  if (cocok != null) return cocok;

  return kunci
      .split('_')
      .where((k) => k.isNotEmpty)
      .map((k) => '${k[0].toUpperCase()}${k.substring(1)}')
      .join(' ');
}
