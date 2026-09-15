import 'package:flutter_test/flutter_test.dart';
import 'package:sporta_app/models/tujuan_notifikasi.dart';

void main() {
  group('tujuanDariTautan', () {
    test('tautan booking pemesan membuka daftar transaksi', () {
      // Server memakai bentuk /my-bookings/{id}; notifikasi chat pemesan
      // juga mendarat di sana.
      expect(tujuanDariTautan('/my-bookings/3'), TujuanNotifikasi.bookingSaya);
      expect(tujuanDariTautan('/my-bookings'), TujuanNotifikasi.bookingSaya);
    });

    test('tautan milik dasbor mitra tidak dibuka di aplikasi pemesan', () {
      // Satu tabel notifikasi dipakai dua aplikasi. Membuka tautan mitra
      // di aplikasi pemesan hanya menghasilkan layar yang salah.
      expect(tujuanDariTautan('/dashboard/bookings/3'), TujuanNotifikasi.tidakAda);
      expect(tujuanDariTautan('/dashboard/withdrawals'), TujuanNotifikasi.tidakAda);
      expect(tujuanDariTautan('/dashboard'), TujuanNotifikasi.tidakAda);
    });

    test('tautan kosong atau tidak ada berarti tidak ke mana-mana', () {
      expect(tujuanDariTautan(null), TujuanNotifikasi.tidakAda);
      expect(tujuanDariTautan(''), TujuanNotifikasi.tidakAda);
      expect(tujuanDariTautan('   '), TujuanNotifikasi.tidakAda);
    });

    test('tautan yang belum dikenal tidak memaksa membuka apa pun', () {
      expect(tujuanDariTautan('/promo/lebaran'), TujuanNotifikasi.tidakAda);
    });
  });
}
