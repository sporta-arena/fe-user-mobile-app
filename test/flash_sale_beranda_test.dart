import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/models/flash_sale.dart';
import 'package:sporta_app/models/venue.dart';

/// Flash sale di beranda pemesan.
void main() {
  FlashSaleBerjalan dariServer(Map<String, dynamic> ubah) =>
      FlashSaleBerjalan.fromJson({
        'id': 3,
        'venue_id': 9,
        'venue_name': 'GOR Uji',
        'field_name': 'Lapangan A',
        'date': '2026-09-20',
        'start_time': '09:00',
        'end_time': '11:00',
        'price_per_hour': 50000,
        'original_price_per_hour': 100000,
        'discount_percent': 50,
        'distance_km': 2.4,
        ...ubah,
      });

  group('membaca muatan', () {
    test('jam tetap UTC apa adanya', () {
      // Kalau ini berubah jadi "16:00", ada yang menyelipkan konversi
      // WIB di jalur baca — dan tampilannya akan meleset tujuh jam.
      final f = dariServer({});

      expect(f.mulai, '09:00');
      expect(f.selesai, '11:00');
    });

    test('harga coret dan potongan terbaca', () {
      final f = dariServer({});

      expect(f.harga, 50000);
      expect(f.hargaNormal, 100000);
      expect(f.diskonPersen, 50);
    });

    test('jarak boleh kosong kalau lokasi belum diberikan', () {
      expect(dariServer({'distance_km': null}).jarakKm, isNull);
    });

    test('muatan seadanya tidak membuat beranda mati', () {
      final f = FlashSaleBerjalan.fromJson({'id': 1});

      expect(f.harga, 0);
      expect(f.diskonPersen, 0);
      expect(f.venueName, '');
    });
  });

  group('penanda hari ini', () {
    test('tanggal hari ini dikenali', () {
      final kini = DateTime.now();
      final hariIni =
          '${kini.year.toString().padLeft(4, '0')}-'
          '${kini.month.toString().padLeft(2, '0')}-'
          '${kini.day.toString().padLeft(2, '0')}';

      expect(dariServer({'date': hariIni}).hariIni, true);
    });

    test('tanggal lain bukan hari ini', () {
      expect(dariServer({'date': '2020-01-01'}).hariIni, false);
    });
  });

  group('badge di kartu venue', () {
    test('venue dengan flash sale ditandai', () {
      final v = Venue.fromJson({
        'id': 1,
        'name': 'GOR Uji',
        'has_flash_sale': true,
      });

      expect(v.adaFlashSale, true);
    });

    test('venue tanpa penanda tidak ditandai', () {
      final v = Venue.fromJson({'id': 1, 'name': 'GOR Uji'});

      expect(v.adaFlashSale, false);
    });
  });
}
