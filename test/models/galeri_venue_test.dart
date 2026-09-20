import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/models/venue.dart';

/// Server sudah lama mengirim `gallery_images`: foto sampul ditambah
/// foto tiap lapangan. Aplikasi tidak pernah membacanya, jadi yang
/// tampil selalu satu foto saja, sampulnya.
void main() {
  Map<String, dynamic> muatan(Object? galeri) => {
        'id': 1,
        'name': 'GOR Contoh',
        'cover_image': 'venues/cover.jpg',
        'cover_image_url': 'https://contoh.test/cover.jpg',
        'gallery_images': galeri,
      };

  group('Venue.galeri', () {
    test('semua foto galeri terbaca, bukan sampulnya saja', () {
      final venue = Venue.fromJson(muatan([
        {'url': 'https://contoh.test/cover.jpg', 'caption': 'Cover'},
        {'url': 'https://contoh.test/lap-1.jpg', 'caption': 'Lapangan 1'},
        {'url': 'https://contoh.test/lap-2.jpg', 'caption': 'Lapangan 2'},
      ]));

      expect(venue.galeri.length, 3);
      // Indeks 0 sampul, 1 dan 2 foto lapangan.
      expect(venue.galeri[2].url, 'https://contoh.test/lap-2.jpg');
      expect(venue.galeri[2].keterangan, 'Lapangan 2');
    });

    test('urutan dari server dipertahankan', () {
      final venue = Venue.fromJson(muatan([
        {'url': 'https://contoh.test/a.jpg', 'caption': 'Cover'},
        {'url': 'https://contoh.test/b.jpg', 'caption': 'Lapangan 1'},
      ]));

      expect(
        venue.galeri.map((g) => g.url).toList(),
        ['https://contoh.test/a.jpg', 'https://contoh.test/b.jpg'],
      );
    });

    test('venue tanpa galeri jatuh ke sampulnya', () {
      final venue = Venue.fromJson(muatan(null));

      expect(venue.galeri.length, 1);
      expect(venue.galeri.first.url, 'https://contoh.test/cover.jpg');
    });

    test('galeri kosong dan tanpa sampul menghasilkan daftar kosong', () {
      final venue = Venue.fromJson({
        'id': 2,
        'name': 'GOR Tanpa Foto',
        'gallery_images': const [],
      });

      expect(venue.galeri, isEmpty);
    });

    test('baris tanpa url dilewati, tidak membuat slide kosong', () {
      final venue = Venue.fromJson(muatan([
        {'url': 'https://contoh.test/ada.jpg', 'caption': 'Cover'},
        {'caption': 'Lapangan tanpa foto'},
        {'url': '', 'caption': 'Kosong'},
      ]));

      expect(venue.galeri.length, 1);
    });

    test('keterangan yang hilang tidak membuatnya gagal', () {
      final venue = Venue.fromJson(muatan([
        {'url': 'https://contoh.test/ada.jpg'},
      ]));

      expect(venue.galeri.single.keterangan, isEmpty);
    });
  });

  /// Keterangan yang benar-benar ditunjukkan ke pemesan.
  ///
  /// Server mengirim `caption` untuk SETIAP baris, termasuk label
  /// internal "Cover" untuk foto sampul. Sebelum ini keterangannya
  /// tidak dipakai sama sekali di layar mana pun; begitu dipakai,
  /// "Cover" tidak boleh ikut muncul — nama venuenya sudah tertulis
  /// besar di atas foto yang sama.
  group('FotoVenue.keteranganTampil', () {
    test('nama lapangan ditampilkan apa adanya', () {
      const foto = FotoVenue(url: 'x', keterangan: 'Lapangan Indoor A');

      expect(foto.keteranganTampil, 'Lapangan Indoor A');
    });

    test('label sampul tidak ditampilkan', () {
      const foto = FotoVenue(url: 'x', keterangan: 'Cover');

      expect(foto.keteranganTampil, isEmpty);
    });

    test('keterangan kosong tetap kosong', () {
      const foto = FotoVenue(url: 'x', keterangan: '');

      expect(foto.keteranganTampil, isEmpty);
    });

    test('lapangan yang kebetulan bernama mirip tetap ditampilkan', () {
      // Penyaringnya harus persis, bukan "mengandung". Lapangan
      // bernama "Cover Court" milik mitra yang nyata.
      const foto = FotoVenue(url: 'x', keterangan: 'Cover Court');

      expect(foto.keteranganTampil, 'Cover Court');
    });
  });

  /// Keterangan ini yang menjawab "dari 4 lapangan di venue, fotonya
  /// yang mana". Kalau server berhenti mengirimkannya, galerinya tetap
  /// jalan — cuma kembali tanpa petunjuk.
  test('galeri bercampur: tiap foto membawa nama lapangannya', () {
    final venue = Venue.fromJson(muatan([
      {'url': 'https://contoh.test/cover.jpg', 'caption': 'Cover'},
      {'url': 'https://contoh.test/a1.jpg', 'caption': 'Lapangan A'},
      {'url': 'https://contoh.test/a2.jpg', 'caption': 'Lapangan A'},
      {'url': 'https://contoh.test/b1.jpg', 'caption': 'Lapangan B'},
    ]));

    expect(
      venue.galeri.map((g) => g.keteranganTampil).toList(),
      ['', 'Lapangan A', 'Lapangan A', 'Lapangan B'],
    );
  });
}
