/// Membaca balasan server atas permintaan hapus akun.
///
/// Dipisah dari lapisan jaringan supaya bisa diuji tanpa server, dan
/// supaya satu hal yang mudah keliru berada di satu tempat: membedakan
/// "gagal, coba lagi" dari "belum boleh, selesaikan dulu urusannya".
/// Dua keadaan itu memakai kode HTTP yang berbeda dan menuntut kalimat
/// yang berbeda di layar, dan menyamakannya membuat pengguna menekan
/// tombol yang sama berulang-ulang tanpa hasil.
class HasilHapusAkun {
  /// Akunnya benar-benar sudah dihapus di server.
  final bool berhasil;

  /// Permintaannya sah, tapi akunnya masih punya tanggungan.
  final bool tertahan;

  final String pesan;

  const HasilHapusAkun({
    required this.berhasil,
    required this.tertahan,
    required this.pesan,
  });
}

const _pesanCadangan = 'Gagal menghapus akun. Coba lagi sebentar lagi.';

HasilHapusAkun bacaHasilHapusAkun(int kode, Map<String, dynamic> badan) {
  final pesan = (badan['message'] as String?)?.trim();

  if (kode == 200) {
    return HasilHapusAkun(
      berhasil: true,
      tertahan: false,
      pesan: (pesan == null || pesan.isEmpty)
          ? 'Akun Anda sudah dihapus.'
          : pesan,
    );
  }

  if (kode == 409) {
    return HasilHapusAkun(
      berhasil: false,
      tertahan: true,
      pesan: (pesan == null || pesan.isEmpty)
          ? 'Akun belum bisa dihapus karena masih ada tanggungan.'
          : pesan,
    );
  }

  if (kode == 429) {
    return const HasilHapusAkun(
      berhasil: false,
      tertahan: false,
      pesan: 'Terlalu banyak percobaan. Tunggu sebentar lalu coba lagi.',
    );
  }

  if (kode == 422) {
    // Laravel menaruh sebab yang sebenarnya di `errors`; `message`
    // hanya ringkasan generik yang tidak memberi tahu apa pun.
    final galat = badan['errors'];
    if (galat is Map) {
      for (final isi in galat.values) {
        if (isi is List && isi.isNotEmpty) {
          final baris = isi.first?.toString().trim();
          if (baris != null && baris.isNotEmpty) {
            return HasilHapusAkun(
                berhasil: false, tertahan: false, pesan: baris);
          }
        }
      }
    }
  }

  // Sisanya (404, 405, 5xx, jaringan aneh) bukan percakapan dengan
  // pengguna, melainkan keadaan yang tidak seharusnya terjadi. Pesan
  // servernya ditulis untuk pengembang dan pernah benar-benar tampil di
  // dialog sebagai "The DELETE method is not supported for route
  // api/v1/user". Untuk kode-kode itu pesan server dibuang.
  return HasilHapusAkun(
    berhasil: false,
    tertahan: false,
    pesan: _pesanDipercaya(kode) && pesan != null && pesan.isNotEmpty
        ? pesan
        : _pesanCadangan,
  );
}

/// Kode balasan yang pesannya memang ditujukan kepada pengguna.
///
/// 400 dan 403 ikut karena keduanya menjelaskan keadaan yang bisa
/// ditindaklanjuti pengguna; 422 sudah ditangani di atas lewat `errors`
/// dan jatuh ke sini hanya kalau daftar galatnya kosong.
bool _pesanDipercaya(int kode) => kode == 400 || kode == 403 || kode == 422;
