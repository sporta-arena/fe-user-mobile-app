/// Banner promo yang tampil di beranda.
///
/// Server hanya mengirim yang sedang tayang, jadi aplikasi tidak perlu
/// menyaring jendela tayangnya sendiri — dan tidak bisa salah menyaring.
class BannerPromo {
  const BannerPromo({
    required this.id,
    required this.judul,
    required this.gambarUrl,
    this.tujuanTipe,
    this.tujuanNilai,
  });

  final int id;
  final String judul;
  final String gambarUrl;

  /// 'venue', 'kategori', atau 'tautan'. Null berarti banner
  /// pengumuman yang tidak mengantar ke mana-mana.
  final String? tujuanTipe;
  final String? tujuanNilai;

  factory BannerPromo.fromJson(Map<String, dynamic> json) {
    return BannerPromo(
      id: json['id'] as int,
      judul: json['judul']?.toString() ?? '',
      gambarUrl: json['gambar_url']?.toString() ?? '',
      tujuanTipe: json['tujuan_tipe']?.toString(),
      tujuanNilai: json['tujuan_nilai']?.toString(),
    );
  }
}
