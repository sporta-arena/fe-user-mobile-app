import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/services/realtime_chat.dart';

/// Nama kanal privat yang dilanggan layar chat.
///
/// Pernah tertulis `'private-booking.\$bookingId'` dengan garis miring
/// terbalik, yang di Dart berarti tanda dolar HARFIAH, bukan
/// interpolasi. Aplikasi berlangganan ke kanal bernama persis
/// "private-booking.$bookingId" untuk setiap booking, kanal yang tidak
/// pernah disiarkan siapa pun.
///
/// Yang paling menipu: tidak ada yang meledak. Pesan tetap muncul,
/// karena layarnya menariknya sekali saat dibuka. Satu-satunya tanda
/// adalah tulisan "Menyambungkan…" yang tidak pernah hilang, dan itu
/// mudah dikira lambat, bukan rusak.
void main() {
  group('namaKanalBooking', () {
    test('menyisipkan id booking, bukan menuliskannya harfiah', () {
      expect(namaKanalBooking(3), 'private-booking.3');
    });

    test('tidak menyisakan tanda dolar di nama kanal', () {
      expect(namaKanalBooking(42), isNot(contains(r'$')));
    });

    test('id berbeda menghasilkan kanal berbeda', () {
      expect(namaKanalBooking(1), isNot(namaKanalBooking(2)));
    });
  });
}
