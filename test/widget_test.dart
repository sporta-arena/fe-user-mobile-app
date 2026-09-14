import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sporta_app/main.dart';

/// Uji asap: aplikasi bisa dibangun.
///
/// Sebelumnya berkas ini masih berisi uji template bawaan Flutter yang
/// menghitung angka pada tombol tambah. Aplikasi ini tidak pernah punya
/// keduanya, jadi ujinya merah sejak hari pertama. Dibiarkan merah,
/// tidak ada lagi yang menjaga bahwa aplikasi masih bisa dibangun sama
/// sekali: kegagalan sungguhan akan tenggelam di antara kegagalan yang
/// sudah biasa dilihat orang.
void main() {
  setUp(() {
    // Aplikasi membaca preferensi sebelum frame pertama (tema, favorit,
    // sesi). Tanpa nilai tiruan, pembacaannya menggantung di lingkungan
    // uji.
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('aplikasi terbangun tanpa galat', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Jeda dan permintaan jaringan yang dimulai saat pembukaan tidak
    // bisa dibatalkan, jadi waktunya dilewati sampai habis supaya uji
    // tidak gagal karena timer yang masih menggantung.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 60));
  });
}
