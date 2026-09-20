import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/models/field.dart';

/// Slot jam di sisi pemesan.
///
/// Yang dijaga: penanda flash sale hanya muncul kalau memang ada
/// potongan, dan harga yang dipakai adalah harga PER SLOT. Perhitungan
/// lama mengalikan harga dasar lapangan dengan jumlah jam, sehingga
/// aturan jam sibuk pun tidak pernah ikut terhitung di layar — pemesan
/// melihat satu angka lalu ditagih angka lain oleh server.
void main() {
  TimeSlot slot(Map<String, dynamic> ubah) => TimeSlot.fromJson({
        'start_time': '09:00',
        'end_time': '10:00',
        'available': true,
        'price_per_hour': 50000,
        'original_price_per_hour': 100000,
        'is_flash_sale': true,
        ...ubah,
      });

  group('penanda diskon', () {
    test('setengah harga jadi -50%', () {
      expect(slot({}).diskonPersen, 50);
    });

    test('slot biasa tidak menampilkan penanda', () {
      expect(
        slot({
          'is_flash_sale': false,
          'price_per_hour': 100000,
          'original_price_per_hour': 100000,
        }).diskonPersen,
        0,
      );
    });

    test('tidak menampilkan penanda kalau harganya justru naik', () {
      // Bisa terjadi kalau harga normalnya turun setelah flash dipasang.
      expect(slot({'price_per_hour': 150000}).diskonPersen, 0);
    });

    test('tanpa harga pembanding, tidak ada penanda', () {
      expect(slot({'original_price_per_hour': 0}).diskonPersen, 0);
    });

    test('dibulatkan', () {
      // 100.000 -> 67.000 = 33%
      expect(slot({'price_per_hour': 67000}).diskonPersen, 33);
    });
  });

  group('membaca muatan', () {
    test('harga per slot terbaca, bukan harga lapangan', () {
      final s = slot({});

      expect(s.pricePerHour, 50000);
      expect(s.originalPricePerHour, 100000);
      expect(s.isFlashSale, true);
    });

    test('muatan lama tanpa kolom harga tetap aman dibaca', () {
      // Server versi lama hanya mengirim start_time/end_time/available.
      // App tidak boleh mati karenanya.
      final s = TimeSlot.fromJson({
        'start_time': '09:00',
        'end_time': '10:00',
        'available': true,
      });

      expect(s.pricePerHour, 0);
      expect(s.isFlashSale, false);
      expect(s.diskonPersen, 0);
    });
  });
}
