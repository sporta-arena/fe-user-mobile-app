import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../models/field_type.dart';
import '../models/filter_venue.dart';
import '../models/venue.dart' as model;
import '../services/field_type_service.dart';
import '../services/venue_service.dart';
import '../theme/app_tokens.dart';
import '../utils/tampilan_venue.dart';
import '../widgets/lembar_filter.dart';
import '../widgets/sampul_venue.dart';
import 'venue_detail_page.dart';

/// Hasil pencarian venue dengan penyaring.
///
/// Semua penyaringnya dikirim ke server; layar ini tidak pernah
/// membuang venue sendiri. Itu bukan kerapian belaka: daftarnya dipotong
/// 15 per halaman, jadi menyaring di sini akan menyembunyikan venue yang
/// cocok tapi ada di halaman berikutnya.
class HasilFilterPage extends StatefulWidget {
  const HasilFilterPage({
    super.key,
    this.filterAwal = const FilterVenue(),
    this.kataKunci,
  });

  final FilterVenue filterAwal;
  final String? kataKunci;

  @override
  State<HasilFilterPage> createState() => _HasilFilterPageState();
}

class _HasilFilterPageState extends State<HasilFilterPage> {
  late FilterVenue _filter = widget.filterAwal;
  List<model.Venue> _venue = const [];
  List<FieldType> _cabang = const [];
  bool _memuat = true;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    _siapkan();
    FieldTypeService.getFieldTypes().then((t) {
      if (mounted) setState(() => _cabang = t);
    });
  }

  Future<void> _siapkan() async {
    // Lokasi didahulukan: penyaring jarak dan urutan "terdekat" tidak
    // berarti apa-apa tanpa titik acuan, dan server hanya menghitung
    // jaraknya kalau koordinatnya ikut dikirim.
    try {
      final izin = await Geolocator.checkPermission();
      if (izin == LocationPermission.always ||
          izin == LocationPermission.whileInUse) {
        final pos = await Geolocator.getCurrentPosition();
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
    } catch (_) {}
    await _muat();
  }

  Future<void> _muat() async {
    setState(() => _memuat = true);
    try {
      final hasil = await VenueService.getVenues(
        search: widget.kataKunci,
        olahraga: _filter.olahraga,
        lat: _lat,
        lng: _lng,
        hargaMin: _filter.hargaMin,
        hargaMaks: _filter.hargaMaks,
        ratingMin: _filter.ratingMin,
        radiusKm: _filter.radiusKm,
        urutkan: _filter.urutkan,
        tersedia: _filter.tersedia,
      );
      if (!mounted) return;
      setState(() {
        _venue = hasil.venues ?? const [];
        _memuat = false;
      });
    } catch (_) {
      if (mounted) setState(() => _memuat = false);
    }
  }

  Future<void> _bukaFilter() async {
    final baru = await tampilkanLembarFilter(
      context,
      awal: _filter,
      cabang: _cabang,
    );
    if (baru == null || !mounted) return;
    setState(() => _filter = baru);
    await _muat();
  }

  @override
  Widget build(BuildContext context) {
    final jumlah = _filter.jumlahAktif;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.c.ink),
        title: Text(
          widget.kataKunci?.isNotEmpty == true
              ? '"${widget.kataKunci}"'
              : 'Cari Arena',
          style: TextStyle(
            color: context.c.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: _bukaFilter,
                  icon: Icon(Icons.tune_rounded, color: context.c.ink),
                ),
                if (jumlah > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      height: 18,
                      width: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.c.surface, width: 2),
                      ),
                      child: Text(
                        '$jumlah',
                        style: TextStyle(
                          color: context.c.onAccent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _memuat
            ? Center(child: CircularProgressIndicator(color: context.c.accent))
            : _venue.isEmpty
            ? _kosong()
            : RefreshIndicator(
                onRefresh: _muat,
                color: context.c.accent,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _venue.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _kartu(_venue[i]),
                ),
              ),
      ),
    );
  }

  Widget _kosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 44, color: context.c.inkDim),
            const SizedBox(height: 14),
            Text(
              'Tidak ada arena yang cocok',
              style: TextStyle(
                color: context.c.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _filter.kosong
                  ? 'Belum ada arena di sini.'
                  : 'Coba longgarkan salah satu filternya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.inkSoft, fontSize: 13.5),
            ),
            if (!_filter.kosong) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() => _filter = const FilterVenue());
                  _muat();
                },
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.c.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Hapus semua filter',
                  style: TextStyle(
                    color: context.c.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _rupiah(double harga) {
    final angka = harga.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) buf.write('.');
      buf.write(angka[i]);
    }
    return 'Rp $buf';
  }

  Widget _kartu(model.Venue v) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VenueDetailPage(venueId: v.id, venueName: v.name),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.c.line),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SampulVenue(
                nama: v.name,
                urlGambar: v.coverImageUrl,
                lebar: 96,
                tinggi: 96,
                ukuranInisial: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    v.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.c.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.c.inkDim,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          v.jarakKm != null
                              ? '${formatKota(v.city)} · ${v.jarakKm!.toStringAsFixed(1).replaceAll('.', ',')} km'
                              : formatKota(v.city),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.c.inkSoft,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (v.averageRating != null) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 15,
                          color: context.c.warn,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          v.averageRating!.toStringAsFixed(1),
                          style: TextStyle(
                            color: context.c.ink,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (v.hargaMin != null)
                        Flexible(
                          child: Text(
                            'Mulai ${_rupiah(v.hargaMin!)}/jam',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.c.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
