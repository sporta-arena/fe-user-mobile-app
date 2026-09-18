import 'package:flutter/material.dart';

import '../models/field_type.dart';
import '../models/filter_venue.dart';
import '../theme/app_tokens.dart';
import '../utils/sisipan_bawah.dart';

/// Lembar penyaring pencarian venue.
///
/// Dipakai bersama beranda, layar cari, dan layar kategori. Sebelumnya
/// tiga permukaan itu punya penyaring sendiri-sendiri dengan perilaku
/// berbeda — dan yang di layar kategori bahkan menyaring di aplikasi,
/// di atas daftar yang sudah dipotong server.
///
/// Mengembalikan [FilterVenue] baru, atau null kalau dibatalkan.
Future<FilterVenue?> tampilkanLembarFilter(
  BuildContext context, {
  required FilterVenue awal,
  required List<FieldType> cabang,
}) {
  return showModalBottomSheet<FilterVenue>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _LembarFilter(awal: awal, cabang: cabang),
  );
}

class _LembarFilter extends StatefulWidget {
  const _LembarFilter({required this.awal, required this.cabang});

  final FilterVenue awal;
  final List<FieldType> cabang;

  @override
  State<_LembarFilter> createState() => _LembarFilterState();
}

class _LembarFilterState extends State<_LembarFilter> {
  late FilterVenue _f = widget.awal;

  /// Batas harga yang ditawarkan.
  ///
  /// Angka bulat, bukan penggeser bebas: penggeser menuntut orang
  /// menentukan angka yang tepat, padahal yang ada di kepalanya
  /// "sekitar seratus ribuan". Rentang siap pilih lebih cepat ditekan
  /// dan hasilnya sama berguna.
  static const _rentangHarga = <(String, int?, int?)>[
    ('Semua harga', null, null),
    ('< Rp100rb', null, 100000),
    ('Rp100rb - 200rb', 100000, 200000),
    ('Rp200rb - 350rb', 200000, 350000),
    ('> Rp350rb', 350000, null),
  ];

  static const _kapan = <(String, String?)>[
    ('Kapan saja', null),
    ('Hari ini', 'hari_ini'),
    ('Besok', 'besok'),
    ('Akhir pekan', 'akhir_pekan'),
  ];

  static const _radius = <(String, double?)>[
    ('Semua jarak', null),
    ('< 3 km', 3),
    ('< 5 km', 5),
    ('< 10 km', 10),
  ];

  static const _rating = <(String, double?)>[
    ('Semua', null),
    ('4.0+', 4.0),
    ('4.5+', 4.5),
  ];

  static const _urutan = <(String, String?)>[
    ('Terdekat', null),
    ('Termurah', 'termurah'),
    ('Termahal', 'termahal'),
    ('Rating tertinggi', 'rating'),
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (context, pengendali) => Container(
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.c.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Filter',
                    style: TextStyle(
                      color: context.c.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (!_f.kosong)
                    TextButton(
                      onPressed: () => setState(() => _f = const FilterVenue()),
                      child: Text(
                        'Atur ulang',
                        style: TextStyle(
                          color: context.c.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Divider(height: 1, color: context.c.line),
            Expanded(
              child: ListView(
                controller: pengendali,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  if (widget.cabang.isNotEmpty) ...[
                    _judul('Cabang olahraga'),
                    _pilihan<String?>(
                      [
                        ('Semua', null),
                        ...widget.cabang.map((c) => (c.label, c.value)),
                      ],
                      _f.olahraga,
                      (v) => setState(() => _f = _f.salin(olahraga: v)),
                    ),
                    const SizedBox(height: 22),
                  ],
                  _judul('Harga per jam'),
                  _pilihanHarga(),
                  const SizedBox(height: 22),
                  _judul('Ada jam kosong'),
                  _pilihan<String?>(
                    _kapan,
                    _f.tersedia,
                    (v) => setState(() => _f = _f.salin(tersedia: v)),
                  ),
                  const SizedBox(height: 22),
                  _judul('Jarak maksimal'),
                  _pilihan<double?>(
                    _radius,
                    _f.radiusKm,
                    (v) => setState(() => _f = _f.salin(radiusKm: v)),
                  ),
                  const SizedBox(height: 22),
                  _judul('Rating minimum'),
                  _pilihan<double?>(
                    _rating,
                    _f.ratingMin,
                    (v) => setState(() => _f = _f.salin(ratingMin: v)),
                  ),
                  const SizedBox(height: 22),
                  _judul('Urutkan'),
                  _pilihan<String?>(
                    _urutan,
                    _f.urutkan,
                    (v) => setState(() => _f = _f.salin(urutkan: v)),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.fromLTRB(
                20,
                12,
                20,
                12 + context.sisipanBawah,
              ),
              decoration: BoxDecoration(
                color: context.c.raised,
                border: Border(top: BorderSide(color: context.c.line)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _f),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.accent,
                    foregroundColor: context.c.onAccent,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Terapkan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _judul(String teks) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      teks,
      style: TextStyle(
        color: context.c.ink,
        fontSize: 14.5,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  Widget _pilihan<T>(
    List<(String, T)> pilihan,
    T terpilih,
    ValueChanged<T> onPilih,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pilihan.map((p) {
        final aktif = p.$2 == terpilih;
        return GestureDetector(
          onTap: () => onPilih(p.$2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: aktif ? context.c.accent : context.c.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: aktif ? context.c.accent : context.c.line,
              ),
            ),
            child: Text(
              p.$1,
              style: TextStyle(
                color: aktif ? context.c.onAccent : context.c.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _pilihanHarga() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _rentangHarga.map((r) {
        final aktif = _f.hargaMin == r.$2 && _f.hargaMaks == r.$3;
        return GestureDetector(
          onTap: () =>
              setState(() => _f = _f.salin(hargaMin: r.$2, hargaMaks: r.$3)),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: aktif ? context.c.accent : context.c.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: aktif ? context.c.accent : context.c.line,
              ),
            ),
            child: Text(
              r.$1,
              style: TextStyle(
                color: aktif ? context.c.onAccent : context.c.ink,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
