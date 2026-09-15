import '../utils/timezone_utils.dart';

/// Satu baris notifikasi dalam aplikasi.
///
/// Laravel menyimpan muatannya di kolom `data`, dan yang di akar baris
/// cuma metadata (`id`, `read_at`, `created_at`). Membaca `json['title']`
/// langsung menghasilkan null untuk setiap baris, tanpa satu pun galat
/// yang menandai kesalahannya, jadi pemetaannya dikunci di sini.
class Notifikasi {
  final String id;
  final String judul;
  final String isi;

  /// Tujuan ketukan, atau null kalau notifikasi ini memang tidak
  /// mengantar ke mana pun. Kartu yang bisa ditekan tapi tidak
  /// membuka apa-apa lebih membingungkan daripada kartu yang diam.
  final String? tautan;

  final String? jenis;
  final bool sudahDibaca;
  final DateTime dibuatPada;

  const Notifikasi({
    required this.id,
    required this.judul,
    required this.isi,
    required this.tautan,
    required this.jenis,
    required this.sudahDibaca,
    required this.dibuatPada,
  });

  factory Notifikasi.dariJson(Map<String, dynamic> json) {
    final data = (json['data'] is Map)
        ? Map<String, dynamic>.from(json['data'] as Map)
        : <String, dynamic>{};

    final tautan = (data['link'] as String?)?.trim();
    final waktu = json['created_at'] as String?;

    return Notifikasi(
      id: json['id']?.toString() ?? '',
      // Notifikasi lama dibuat sebelum kolomnya seragam. Satu baris
      // cacat tidak boleh mengosongkan seluruh daftar.
      judul: (data['title'] as String?)?.trim().isNotEmpty == true
          ? data['title'] as String
          : 'Pemberitahuan',
      isi: (data['body'] as String?) ?? '',
      tautan: (tautan == null || tautan.isEmpty) ? null : tautan,
      jenis: data['type'] as String?,
      sudahDibaca: json['read_at'] != null,
      dibuatPada: waktu != null
          ? TimezoneUtils.parseUtcToLocal(waktu)
          : DateTime.now(),
    );
  }
}
