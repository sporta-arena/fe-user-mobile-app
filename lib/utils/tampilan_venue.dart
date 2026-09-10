/// Cara nilai mentah dari API ditampilkan ke pengguna.
///
/// API mengirim kota sebagai nilai enum snake_case (`jakarta_selatan`,
/// `kabupaten_bogor`). Beberapa layar sudah menambalnya sendiri dengan
/// `replaceAll('_', ' ')`, tapi beranda dan peta belum, jadi pengguna
/// masih melihat `jakarta_selatan` apa adanya.
///
/// Berkas ini juga menyimpan pengganti foto sampul: venue baru datang
/// tanpa foto, dan menyamarkannya dengan foto stok membuat belasan venue
/// berbeda tampil dengan gambar yang sama persis.
library;

import 'package:flutter/material.dart';

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

/// Dua huruf awal untuk kartu tanpa foto.
String inisialVenue(String? nama) {
  if (nama == null) return '?';
  final kata = nama.trim().split(RegExp(r'\s+')).where((k) => k.isNotEmpty).toList();
  if (kata.isEmpty) return '?';
  if (kata.length == 1) {
    final satu = kata.first;
    return (satu.length >= 2 ? satu.substring(0, 2) : satu).toUpperCase();
  }
  return (kata.first[0] + kata.last[0]).toUpperCase();
}

/// Slot warna kategori untuk venue ini, tetap sama setiap kali dirender.
///
/// Memakai nama, bukan id, supaya dua venue bersebelahan di daftar tidak
/// otomatis berwarna sama hanya karena id-nya berurutan.
int indeksWarnaVenue(String? nama) {
  if (nama == null || nama.isEmpty) return 0;
  var hash = 0;
  for (final unit in nama.codeUnits) {
    hash = unit + ((hash << 5) - hash);
  }
  return hash.abs() % 6;
}

/// Ikon yang mewakili satu jenis olahraga.
IconData ikonOlahraga(String? olahraga) {
  final s = (olahraga ?? '').toLowerCase();
  if (s.contains('futsal') || s.contains('bola') || s.contains('soccer')) {
    return Icons.sports_soccer;
  }
  if (s.contains('basket')) return Icons.sports_basketball;
  if (s.contains('voli') || s.contains('volley')) return Icons.sports_volleyball;
  if (s.contains('badminton') ||
      s.contains('bulu') ||
      s.contains('tenis') ||
      s.contains('tennis') ||
      s.contains('padel')) {
    return Icons.sports_tennis;
  }
  if (s.contains('renang') || s.contains('swim')) return Icons.pool;
  if (s.contains('gym') || s.contains('fitness')) return Icons.fitness_center;
  return Icons.stadium_rounded;
}

/// Nama fasilitas seperti yang disimpan API, jadi teks Indonesia.
///
/// API mengirim kunci campur-campur: `wifi`, `parking`, `canteen`,
/// `free_parking`. Sebelumnya mobile hanya mengganti garis bawah dengan
/// spasi lalu membesarkan huruf pertama, jadi chip-nya terbaca "Parking"
/// dan "Canteen" di tengah antarmuka berbahasa Indonesia. Peta ini
/// disamakan dengan namespace `venueFacilities` di web, ditambah beberapa
/// kunci Inggris yang ternyata dipakai backend tapi belum ada di sana.
const Map<String, String> _fasilitas = {
  'wifi': 'Wifi',
  'wi_fi': 'Wifi',
  'parking': 'Parkir',
  'parkir': 'Parkir',
  'free_parking': 'Parkir gratis',
  'toilet': 'Toilet',
  'wc': 'Toilet',
  'shower': 'Kamar mandi',
  'locker': 'Loker',
  'loker': 'Loker',
  'locker_room': 'Ruang loker',
  'canteen': 'Kantin',
  'kantin': 'Kantin',
  'cafe': 'Kafe',
  'kafe': 'Kafe',
  'musholla': 'Musholla',
  'mushola': 'Musholla',
  'prayer_room': 'Musholla',
  'ac': 'AC',
  'cctv': 'CCTV',
  'light': 'Penerangan',
  'lighting': 'Penerangan',
  'tribun': 'Tribun',
  'tribune': 'Tribun',
  'scoreboard': 'Papan skor',
  'ball_rental': 'Sewa bola',
  'shoe_rental': 'Sewa sepatu',
  'free_water': 'Air minum gratis',
  'changing_room': 'Ruang ganti',
};

String formatFasilitas(String fasilitas) {
  final kunci = fasilitas.trim().toLowerCase();
  final cocok = _fasilitas[kunci];
  if (cocok != null) return cocok;

  // Kunci yang belum dipetakan tetap dirapikan, bukan disembunyikan:
  // fasilitas yang benar-benar ada lebih berguna daripada chip kosong.
  return kunci
      .split('_')
      .where((k) => k.isNotEmpty)
      .map((k) => '${k[0].toUpperCase()}${k.substring(1)}')
      .join(' ');
}
