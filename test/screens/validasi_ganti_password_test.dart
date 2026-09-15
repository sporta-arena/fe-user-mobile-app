import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/screens/validasi_ganti_password.dart';

void main() {
  group('periksaGantiPassword', () {
    test('kolom kosong ditolak sebelum menyentuh jaringan', () {
      expect(periksaGantiPassword(lama: '', baru: 'rahasia123', ulangi: 'rahasia123'),
          isNotNull);
      expect(periksaGantiPassword(lama: 'lama1234', baru: '', ulangi: ''), isNotNull);
    });

    test('password baru yang tidak cocok ditolak', () {
      final galat = periksaGantiPassword(
          lama: 'lama1234', baru: 'rahasia123', ulangi: 'rahasia124');

      expect(galat, contains('cocok'));
    });

    test('batas panjangnya 8, mengikuti server, bukan 6', () {
      // Server memakai `min:8`. Selama layar ini menerima 6 karakter,
      // pengguna mengetik password yang sah menurut aplikasi lalu
      // ditolak server tanpa sebab yang terbaca. Dua angka yang berbeda
      // untuk aturan yang sama selalu berakhir begitu.
      expect(periksaGantiPassword(lama: 'lama1234', baru: 'rahas1', ulangi: 'rahas1'),
          isNotNull);
      expect(
          periksaGantiPassword(lama: 'lama1234', baru: 'rahasia1', ulangi: 'rahasia1'),
          isNull);
    });

    test('password baru yang sama dengan yang lama ditolak', () {
      expect(
          periksaGantiPassword(lama: 'rahasia1', baru: 'rahasia1', ulangi: 'rahasia1'),
          isNotNull);
    });

    test('masukan yang sah menghasilkan null', () {
      expect(
          periksaGantiPassword(lama: 'lama1234', baru: 'barubaru1', ulangi: 'barubaru1'),
          isNull);
    });
  });
}
