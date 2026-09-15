import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/screens/chat/alasan_laporan.dart';

void main() {
  group('AlasanLaporan', () {
    test('setiap alasan punya kode yang diterima server', () {
      // Kode inilah yang divalidasi `Rule::in(ChatReport::ALASAN)` di
      // server. Satu huruf beda berarti laporan ditolak 422 dan orang
      // yang sedang dilecehkan melihat kegagalan tanpa sebab.
      expect(
        AlasanLaporan.semua.map((a) => a.kode).toList(),
        ['pelecehan', 'penipuan', 'spam', 'konten_tidak_pantas', 'lainnya'],
      );
    });

    test('setiap alasan punya label yang bisa dibaca orang', () {
      for (final a in AlasanLaporan.semua) {
        expect(a.label.trim(), isNotEmpty);
        expect(a.label, isNot(a.kode));
      }
    });
  });

  group('bacaHasilLaporan', () {
    test('200 berarti laporannya masuk', () {
      final h = bacaHasilLaporan(200, {'message': 'Laporan Anda sudah kami terima.'});

      expect(h.berhasil, isTrue);
      expect(h.pesan, contains('terima'));
    });

    test('403 dijelaskan sebagai bukan peserta, bukan galat umum', () {
      final h = bacaHasilLaporan(403, {'message': 'Anda bukan bagian dari percakapan ini'});

      expect(h.berhasil, isFalse);
      expect(h.pesan, contains('percakapan'));
    });

    test('galat teknis tidak ditampilkan mentah', () {
      final h = bacaHasilLaporan(500, {'message': 'SQLSTATE[HY000]'});

      expect(h.berhasil, isFalse);
      expect(h.pesan, isNot(contains('SQLSTATE')));
    });
  });
}
