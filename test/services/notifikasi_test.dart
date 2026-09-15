import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/models/notifikasi.dart';

void main() {
  group('Notifikasi.dariJson', () {
    Map<String, dynamic> baris({Object? readAt}) => {
          'id': '9c1f-uuid',
          'data': {
            'type': 'booking',
            'title': 'Pembayaran berhasil',
            'body': 'Booking BK-1 sudah lunas.',
            'link': '/my-bookings/3',
            'icon': 'payment',
          },
          'read_at': readAt,
          'created_at': '2026-09-15T03:00:00.000000Z',
        };

    test('membaca isi dari kolom data, bukan dari akar baris', () {
      // Laravel menyimpan muatan notifikasi di kolom `data`, dan yang di
      // akar cuma metadata. Membaca `json['title']` menghasilkan null
      // untuk semua baris tanpa satu pun galat.
      final n = Notifikasi.dariJson(baris());

      expect(n.id, '9c1f-uuid');
      expect(n.judul, 'Pembayaran berhasil');
      expect(n.isi, 'Booking BK-1 sudah lunas.');
      expect(n.tautan, '/my-bookings/3');
    });

    test('read_at null berarti belum dibaca', () {
      expect(Notifikasi.dariJson(baris()).sudahDibaca, isFalse);
      expect(
        Notifikasi.dariJson(baris(readAt: '2026-09-15T04:00:00.000000Z'))
            .sudahDibaca,
        isTrue,
      );
    });

    test('baris tanpa judul tetap bisa ditampilkan', () {
      // Notifikasi lama dibuat sebelum kolom-kolom ini seragam. Satu
      // baris cacat tidak boleh mengosongkan seluruh daftar.
      final n = Notifikasi.dariJson({
        'id': 'x',
        'data': {},
        'read_at': null,
        'created_at': '2026-09-15T03:00:00.000000Z',
      });

      expect(n.judul, isNotEmpty);
      expect(n.tautan, isNull);
    });

    test('tautan kosong dibaca sebagai tidak ada', () {
      // Kartu yang bisa ditekan tapi tidak ke mana-mana lebih buruk
      // daripada kartu yang memang tidak bisa ditekan.
      final n = Notifikasi.dariJson({
        'id': 'x',
        'data': {'title': 'Halo', 'link': ''},
        'read_at': null,
        'created_at': '2026-09-15T03:00:00.000000Z',
      });

      expect(n.tautan, isNull);
    });

    test('waktu dibaca sebagai UTC lalu dijadikan waktu lokal', () {
      final n = Notifikasi.dariJson(baris());

      expect(n.dibuatPada.isUtc, isFalse);
    });
  });
}
