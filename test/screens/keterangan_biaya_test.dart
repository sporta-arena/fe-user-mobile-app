import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/screens/keterangan_biaya.dart';

void main() {
  group('keteranganBiayaGateway', () {
    test('menyebut dasar hitungan yang sebenarnya, bukan harga lapangan saja',
        () {
      // Angka nyata dari layar konfirmasi: lapangan Rp 300.000 +
      // platform Rp 20.000, QRIS 0.7% menghasilkan Rp 2.240. Kalau
      // dasarnya harga lapangan saja hasilnya Rp 2.100, jadi kalimat
      // lama membuat pemesan menghitung ulang dan menemukan selisih.
      expect(
        keteranganBiayaGateway(tipeBiaya: 'percent', nilai: 0.007),
        ' (0.7% dari harga lapangan + biaya platform)',
      );
    });

    test('biaya tetap tidak menyebut persentase apa pun', () {
      expect(
        keteranganBiayaGateway(tipeBiaya: 'flat', nilai: 4000),
        ' (biaya tetap)',
      );
    });
  });
}
