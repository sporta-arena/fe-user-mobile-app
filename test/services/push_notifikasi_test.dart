import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/services/push_notifikasi.dart';

/// Keputusan seputar push yang bisa salah tanpa terlihat.
///
/// Bagian Firebase-nya butuh perangkat, tapi yang paling mudah salah
/// bukan di sana: kapan token dikirim ulang, dan apa yang dibaca dari
/// muatan pesan.
void main() {
  group('perluDaftarUlang', () {
    test('token baru pertama kali selalu didaftarkan', () {
      expect(perluDaftarUlang(tokenLama: null, tokenBaru: 'abc'), isTrue);
    });

    test('token yang sama tidak dikirim ulang', () {
      expect(perluDaftarUlang(tokenLama: 'abc', tokenBaru: 'abc'), isFalse);
    });

    test('token yang diputar Firebase dikirim ulang', () {
      // Firebase memutar token sendiri. Kalau yang baru tidak dikirim,
      // server terus menembak token lama yang sudah mati dan pemesan
      // berhenti menerima notifikasi tanpa tahu sebabnya.
      expect(perluDaftarUlang(tokenLama: 'abc', tokenBaru: 'xyz'), isTrue);
    });

    test('token kosong tidak pernah didaftarkan', () {
      expect(perluDaftarUlang(tokenLama: null, tokenBaru: null), isFalse);
      expect(perluDaftarUlang(tokenLama: 'abc', tokenBaru: ''), isFalse);
    });
  });

  group('PesanPush.dariData', () {
    test('membaca judul, isi, dan tautan', () {
      final p = PesanPush.dariData(
        judul: 'Pembayaran berhasil',
        isi: 'SPG-1 - Lapangan A 19.00',
        data: {'type': 'booking_confirmed', 'link': '/bookings/9'},
      );

      expect(p.judul, 'Pembayaran berhasil');
      expect(p.tautan, '/bookings/9');
      expect(p.tipe, 'booking_confirmed');
    });

    test('tautan kosong dibaca sebagai tidak ada', () {
      // Server mengirim link sebagai string kosong kalau notifikasinya
      // tidak menunjuk ke mana pun. Memperlakukannya sebagai tautan
      // membuat aplikasi membuka layar kosong saat diketuk.
      final p = PesanPush.dariData(judul: 'Halo', isi: 'Isi', data: {'link': ''});

      expect(p.tautan, isNull);
    });

    test('pesan tanpa judul tetap bisa ditampilkan', () {
      expect(PesanPush.dariData(judul: null, isi: 'Isi', data: {}).judul,
          isNotEmpty);
    });
  });

  group('namaKanalPengguna', () {
    test('memakai kanal privat bawaan Laravel', () {
      // Harus sama persis dengan yang diotorisasi di
      // routes/channels.php. Salah satu huruf saja dan langganannya
      // ditolak tanpa pesan yang jelas di sisi klien.
      expect(namaKanalPengguna(7), 'private-App.Models.User.7');
    });
  });
}
