/// Satu flash sale yang sedang berjalan, untuk ditemukan di beranda.
///
/// Dibedakan dari banner promo: ini berbasis data, bukan gambar
/// unggahan admin. Isinya venue, jam, dan potongan nyata yang langsung
/// bisa dipesan.
///
/// [mulai] dan [selesai] datang dari server dalam **UTC**, sama seperti
/// slot jam. Tampilkan lewat `WaktuWib.tampil()`.
class FlashSaleBerjalan {
  const FlashSaleBerjalan({
    required this.id,
    required this.venueId,
    required this.venueName,
    required this.fieldName,
    required this.tanggal,
    required this.mulai,
    required this.selesai,
    required this.harga,
    required this.hargaNormal,
    required this.diskonPersen,
    this.jarakKm,
  });

  final int id;
  final int venueId;
  final String venueName;
  final String fieldName;

  /// "YYYY-MM-DD"
  final String tanggal;

  /// UTC "HH:mm". Lihat catatan kelas.
  final String mulai;
  final String selesai;

  final double harga;
  final double hargaNormal;
  final int diskonPersen;

  /// Null kalau pemesan belum memberi lokasi.
  final double? jarakKm;

  /// Apakah flash sale ini berlaku hari ini.
  ///
  /// Dipakai untuk memilih kata "Hari ini" alih-alih tanggal — jauh
  /// lebih cepat dibaca, dan sisi mendesaknya justru itu intinya.
  bool get hariIni {
    final kini = DateTime.now();
    final t =
        '${kini.year.toString().padLeft(4, '0')}-'
        '${kini.month.toString().padLeft(2, '0')}-'
        '${kini.day.toString().padLeft(2, '0')}';
    return tanggal == t;
  }

  factory FlashSaleBerjalan.fromJson(Map<String, dynamic> json) {
    double angka(String k) => (json[k] as num?)?.toDouble() ?? 0;

    return FlashSaleBerjalan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      venueId: (json['venue_id'] as num?)?.toInt() ?? 0,
      venueName: (json['venue_name'] ?? '').toString(),
      fieldName: (json['field_name'] ?? '').toString(),
      tanggal: (json['date'] ?? '').toString(),
      mulai: (json['start_time'] ?? '').toString(),
      selesai: (json['end_time'] ?? '').toString(),
      harga: angka('price_per_hour'),
      hargaNormal: angka('original_price_per_hour'),
      diskonPersen: (json['discount_percent'] as num?)?.toInt() ?? 0,
      jarakKm: (json['distance_km'] as num?)?.toDouble(),
    );
  }
}
