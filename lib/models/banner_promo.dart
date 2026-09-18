/// Ringkasan promo yang dibawa sebuah banner.
class RingkasPromo {
  const RingkasPromo({
    required this.kode,
    required this.judul,
    this.deskripsi,
    required this.potonganTeks,
    this.berlakuSampai,
    this.syarat = const [],
    this.gambarUrl,
  });

  final String kode;
  final String judul;
  final String? deskripsi;

  /// Sudah berbentuk teks siap tampil: "Rp20.000" atau "20% (maks Rp20.000)".
  /// Diformat server supaya angka yang dibaca pemesan tidak bisa berbeda
  /// dari angka yang dihitung saat membayar.
  final String potonganTeks;

  final String? berlakuSampai;

  /// Syarat yang benar-benar bisa membuat kodenya ditolak.
  final List<String> syarat;

  /// Gambar banner promo ini, kalau punya. Hanya terisi lewat /promos;
  /// di /banners gambarnya dibawa BannerPromo sendiri.
  final String? gambarUrl;

  factory RingkasPromo.fromJson(Map<String, dynamic> json) {
    return RingkasPromo(
      kode: json['kode']?.toString() ?? '',
      judul: json['judul']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      potonganTeks: json['potongan_teks']?.toString() ?? '',
      berlakuSampai: json['berlaku_sampai']?.toString(),
      syarat: ((json['syarat'] as List?) ?? const [])
          .map((e) => e.toString())
          .toList(),
      gambarUrl: json['gambar_url']?.toString(),
    );
  }
}

/// Banner promo yang tampil di beranda.
///
/// Server hanya mengirim yang sedang tayang, jadi aplikasi tidak perlu
/// menyaring jendela tayangnya sendiri — dan tidak bisa salah menyaring.
class BannerPromo {
  const BannerPromo({
    required this.id,
    required this.judul,
    required this.gambarUrl,
    this.promo,
    this.tujuanTipe,
    this.tujuanNilai,
  });

  final int id;
  final String judul;
  final String gambarUrl;

  /// Promo yang diiklankan banner ini, kalau ada.
  ///
  /// Gambarnya sendiri tidak bisa diandalkan memuat kode dan syaratnya —
  /// admin bisa saja mengunggah logo polos, dan itu yang terjadi pada
  /// banner pertama. Jadi keterangannya dibawa datanya, bukan gambarnya.
  final RingkasPromo? promo;

  /// 'venue', 'kategori', atau 'tautan'. Null berarti banner
  /// pengumuman yang tidak mengantar ke mana-mana.
  final String? tujuanTipe;
  final String? tujuanNilai;

  factory BannerPromo.fromJson(Map<String, dynamic> json) {
    return BannerPromo(
      id: json['id'] as int,
      judul: json['judul']?.toString() ?? '',
      gambarUrl: json['gambar_url']?.toString() ?? '',
      promo: json['promo'] is Map<String, dynamic>
          ? RingkasPromo.fromJson(json['promo'] as Map<String, dynamic>)
          : null,
      tujuanTipe: json['tujuan_tipe']?.toString(),
      tujuanNilai: json['tujuan_nilai']?.toString(),
    );
  }
}
