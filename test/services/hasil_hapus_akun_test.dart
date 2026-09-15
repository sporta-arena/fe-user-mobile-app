import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/services/hasil_hapus_akun.dart';

void main() {
  group('bacaHasilHapusAkun', () {
    test('200 berarti akunnya benar-benar hilang', () {
      final h = bacaHasilHapusAkun(200, {'message': 'Akun Anda sudah dihapus.'});

      expect(h.berhasil, isTrue);
      expect(h.tertahan, isFalse);
      expect(h.pesan, 'Akun Anda sudah dihapus.');
    });

    test('409 ditampilkan sebagai tertahan, bukan sebagai kegagalan', () {
      // Bedanya penting di layar: "gagal" mengajak mencoba lagi,
      // sedangkan ini mengajak menyelesaikan booking dulu. Dua kalimat
      // berbeda, dua tindakan berbeda.
      final h = bacaHasilHapusAkun(409, {
        'message': 'Masih ada booking yang belum selesai.',
        'kode': 'booking_aktif',
      });

      expect(h.berhasil, isFalse);
      expect(h.tertahan, isTrue);
      expect(h.pesan, 'Masih ada booking yang belum selesai.');
    });

    test('422 memakai pesan galat per kolom, bukan pesan umum', () {
      // Laravel menaruh sebab yang sebenarnya di `errors`, dan `message`
      // hanya ringkasan generik. Menampilkan yang generik membuat orang
      // menebak apa yang salah dengan isian mereka.
      final h = bacaHasilHapusAkun(422, {
        'message': 'The given data was invalid.',
        'errors': {
          'password': ['Kata sandi salah.'],
        },
      });

      expect(h.berhasil, isFalse);
      expect(h.tertahan, isFalse);
      expect(h.pesan, 'Kata sandi salah.');
    });

    test('429 menjelaskan bahwa ini soal menunggu, bukan soal isian', () {
      final h = bacaHasilHapusAkun(429, {});

      expect(h.berhasil, isFalse);
      expect(h.pesan, contains('Terlalu banyak'));
    });

    test('balasan tanpa pesan tetap menghasilkan kalimat yang bisa dibaca', () {
      // Server yang mati atau proxy yang menyela mengirim badan kosong.
      // Dialog yang menampilkan string kosong terlihat seperti aplikasi
      // yang menggantung.
      final h = bacaHasilHapusAkun(500, {});

      expect(h.berhasil, isFalse);
      expect(h.pesan, isNotEmpty);
    });

    test('galat teknis dari server tidak ditampilkan mentah-mentah', () {
      // Terlihat sungguhan di perangkat: rute belum ter-deploy, Laravel
      // membalas 405 dengan "The DELETE method is not supported for
      // route api/v1/user", dan kalimat itu tampil utuh di dialog.
      // Pesan server hanya dipercaya untuk kode yang memang ditujukan
      // kepada pengguna.
      final h = bacaHasilHapusAkun(405, {
        'message': 'The DELETE method is not supported for route api/v1/user.',
      });

      expect(h.berhasil, isFalse);
      expect(h.pesan, isNot(contains('DELETE')));
      expect(h.pesan, isNot(contains('route')));
    });

    test('galat server 500 juga tidak membocorkan isinya', () {
      final h = bacaHasilHapusAkun(500, {
        'message': 'SQLSTATE[HY000]: General error',
      });

      expect(h.pesan, isNot(contains('SQLSTATE')));
    });
  });
}
