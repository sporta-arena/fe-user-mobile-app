import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/models/user.dart';

void main() {
  group('User.masukLewatGoogle', () {
    test('akun yang tertaut Google dikenali dari muatan server', () {
      // Layar hapus akun harus memilih pembuktian yang benar sebelum
      // bertanya apa pun. Salah pilih berarti meminta kata sandi kepada
      // orang yang tidak pernah punya kata sandi.
      final u = User.fromJson({
        'id': 1,
        'name': 'Budi',
        'email': 'budi@contoh.test',
        'google_id': 'sub-123',
      });

      expect(u.masukLewatGoogle, isTrue);
    });

    test('akun biasa tidak dianggap akun Google', () {
      final u = User.fromJson({
        'id': 2,
        'name': 'Siti',
        'email': 'siti@contoh.test',
      });

      expect(u.masukLewatGoogle, isFalse);
    });

    test('status Google bertahan lewat penyimpanan sesi', () {
      // Sesi disimpan sebagai JSON di shared_preferences lalu dibaca
      // lagi saat aplikasi dibuka. Kalau toJson melupakan kolom ini,
      // pengguna Google yang membuka aplikasi keesokan harinya kembali
      // dimintai kata sandi yang tidak mereka punya.
      final asal = User.fromJson({
        'id': 3,
        'name': 'Rina',
        'email': 'rina@contoh.test',
        'google_id': 'sub-789',
      });

      final pulang = User.fromJson(asal.toJson());

      expect(pulang.masukLewatGoogle, isTrue);
    });
  });
}
