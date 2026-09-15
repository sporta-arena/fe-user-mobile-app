/// Alasan pelaporan percakapan, beserta pembaca balasannya.
///
/// Kodenya harus sama persis dengan `ChatReport::ALASAN` di server,
/// karena itulah yang divalidasi `Rule::in(...)`. Satu huruf berbeda
/// berarti laporan ditolak 422, dan orang yang sedang dilecehkan cuma
/// melihat kegagalan tanpa sebab.
class AlasanLaporan {
  final String kode;
  final String label;

  const AlasanLaporan(this.kode, this.label);

  static const semua = <AlasanLaporan>[
    AlasanLaporan('pelecehan', 'Pelecehan atau ancaman'),
    AlasanLaporan('penipuan', 'Penipuan'),
    AlasanLaporan('spam', 'Spam atau promosi'),
    AlasanLaporan('konten_tidak_pantas', 'Konten tidak pantas'),
    AlasanLaporan('lainnya', 'Lainnya'),
  ];
}

class HasilLaporan {
  final bool berhasil;
  final String pesan;

  const HasilLaporan({required this.berhasil, required this.pesan});
}

HasilLaporan bacaHasilLaporan(int kode, Map<String, dynamic> badan) {
  final pesan = (badan['message'] as String?)?.trim();

  if (kode == 200) {
    return HasilLaporan(
      berhasil: true,
      pesan: (pesan == null || pesan.isEmpty)
          ? 'Laporan Anda sudah kami terima.'
          : pesan,
    );
  }

  // Hanya kode yang pesannya memang ditujukan kepada pengguna. Sisanya
  // (5xx, 404) membawa kalimat untuk pengembang; pernah terlihat di
  // layar sebagai "The DELETE method is not supported for route ...".
  const dipercaya = {403, 422, 429};
  return HasilLaporan(
    berhasil: false,
    pesan: dipercaya.contains(kode) && pesan != null && pesan.isNotEmpty
        ? pesan
        : 'Gagal mengirim laporan. Coba lagi sebentar lagi.',
  );
}
