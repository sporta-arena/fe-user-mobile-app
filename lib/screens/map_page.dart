import 'package:flutter/material.dart';
import '../utils/tampilan_venue.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

import 'venue_detail_page.dart';
import '../services/venue_service.dart';
import '../models/venue.dart' as model;
import '../utils/sisipan_bawah.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  // Default center: Jakarta, used until venues/location load.
  static const LatLng _fallbackCenter = LatLng(-6.2088, 106.8456);

  /// Jenis lapangan yang bisa disaring di peta.
  ///
  /// Nilainya harus sama persis dengan kolom `type` di tabel fields,
  /// karena backend menyaring dengan `where('type', $request->sport)`.
  /// Disalin apa adanya dari enum FieldType di backend, bukan ditebak:
  /// nilainya `basketball`/`volleyball`/`tennis`, bukan bentuk
  /// Indonesianya. Kalau meleset, backend menyaring dengan nilai yang
  /// tidak pernah cocok dan petanya jadi kosong tanpa galat apa pun.
  static const _jenisOlahraga = <String, String>{
    'futsal': 'Futsal',
    'badminton': 'Badminton',
    'mini_soccer': 'Mini Soccer',
    'basketball': 'Basket',
    'volleyball': 'Voli',
    'tennis': 'Tenis',
    'padel': 'Padel',
  };

  List<model.Venue> _venues = [];
  model.Venue? _selected;
  bool _loading = true;
  LatLng? _userLocation;

  /// Jenis yang sedang dipilih; null berarti semua.
  String? _olahraga;

  /// Titik acuan permintaan terakhir. Dipakai membandingkan dengan
  /// pusat peta sekarang untuk memutuskan apakah tombol "Cari di area
  /// ini" perlu muncul.
  LatLng? _titikCarian;

  bool _petaBergeser = false;
  bool _memuatUlang = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Lokasi didahulukan, bukan diparalelkan seperti sebelumnya.
    // Server hanya menghitung `distance_km` kalau permintaannya membawa
    // lat & lng, jadi memuat venue lebih dulu berarti jaraknya pasti
    // kosong dan harus diminta ulang. Izin yang sudah pernah diberikan
    // dijawab seketika, dan kalau ditolak fungsinya kembali cepat.
    await _loadLocation();
    await _loadVenues();
    if (mounted) {
      setState(() => _loading = false);
      _fitToContent();
    }
  }

  /// Ambil venue dari server.
  ///
  /// [titik] jadi acuan pengurutan dan perhitungan jarak: lokasi
  /// pengguna saat layar dibuka, atau pusat peta saat "Cari di area
  /// ini" ditekan.
  Future<void> _loadVenues({LatLng? titik}) async {
    final acuan = titik ?? _userLocation;
    try {
      final result = await VenueService.getVenues(
        olahraga: _olahraga,
        lat: acuan?.latitude,
        lng: acuan?.longitude,
      );
      if (result.success && result.venues != null) {
        _venues = result.venues!
            .where((v) => v.latitude != null && v.longitude != null)
            .toList();
        _titikCarian = acuan;
      }
    } catch (_) {}
  }

  /// Muat ulang untuk area yang sedang terlihat.
  Future<void> _cariDiAreaIni() async {
    setState(() {
      _memuatUlang = true;
      _selected = null;
    });
    await _loadVenues(titik: _mapController.camera.center);
    if (!mounted) return;
    setState(() {
      _memuatUlang = false;
      _petaBergeser = false;
    });
  }

  Future<void> _gantiOlahraga(String? jenis) async {
    setState(() {
      _olahraga = jenis;
      _selected = null;
      _memuatUlang = true;
    });
    await _loadVenues(titik: _titikCarian);
    if (!mounted) return;
    setState(() => _memuatUlang = false);
    _fitToContent();
  }

  Future<void> _loadLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      _userLocation = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  void _fitToContent() {
    final points = <LatLng>[
      if (_userLocation != null) _userLocation!,
      ..._venues.map((v) => LatLng(v.latitude!, v.longitude!)),
    ];
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(60),
        maxZoom: 15,
      ),
    );
  }

  LatLng get _initialCenter =>
      _userLocation ??
      (_venues.isNotEmpty
          ? LatLng(_venues.first.latitude!, _venues.first.longitude!)
          : _fallbackCenter);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: gayaOverlay(context),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _initialCenter,
                initialZoom: 12,
                onTap: (_, __) => setState(() => _selected = null),
                // Tombol "Cari di area ini" hanya muncul kalau petanya
                // benar-benar digeser jauh dari titik carian terakhir.
                // Ambangnya 2 km supaya geseran kecil saat memilih
                // jarum tidak memunculkan tombol yang tidak ada gunanya.
                onPositionChanged: (kamera, adaGerakanPengguna) {
                  if (!adaGerakanPengguna || _titikCarian == null) return;
                  final jauh =
                      const Distance().as(
                        LengthUnit.Kilometer,
                        kamera.center,
                        _titikCarian!,
                      ) >
                      2;
                  if (jauh != _petaBergeser) {
                    setState(() => _petaBergeser = jauh);
                  }
                },
              ),
              children: [
                TileLayer(
                  // Basemap CartoDB dark_all yang dipakai sebelumnya
                  // sekarang MENUNTUT API key dan menimpa peta dengan
                  // tulisan "API KEY REQUIRED". Pindah ke tile
                  // OpenStreetMap yang bebas kunci; versi gelapnya
                  // dihasilkan dari tile terang lewat pembalikan warna,
                  // jadi petanya ikut tema seperti sisa aplikasi.
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  retinaMode: RetinaMode.isHighDensity(context),
                  userAgentPackageName: 'id.sportago.app',
                  tileBuilder: Theme.of(context).brightness == Brightness.dark
                      ? darkModeTileBuilder
                      : null,
                ),
                if (_userLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _userLocation!,
                        width: 22,
                        height: 22,
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.c.info,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                      ),
                    ],
                  ),
                MarkerLayer(markers: _venues.map(_buildMarker).toList()),
              ],
            ),

            // Top bar
            _topBar(),

            // Tombol muat ulang untuk area yang terlihat
            if (_petaBergeser && !_memuatUlang) _tombolCariArea(),

            // Recenter button
            Positioned(
              right: 16,
              bottom: (_selected != null ? 188.0 : 28.0) + context.sisipanBawah,
              child: FloatingActionButton(
                heroTag: 'recenter',
                backgroundColor: context.c.raised,
                onPressed: _fitToContent,
                child: Icon(Icons.my_location_rounded, color: context.c.accent),
              ),
            ),

            // Selected venue card
            if (_selected != null) _venueCard(_selected!),

            if (_loading)
              Center(child: CircularProgressIndicator(color: context.c.accent)),
          ],
        ),
      ),
    );
  }

  /// Jarak singkat: "850 m" di bawah 1 km, "2,4 km" di atasnya.
  ///
  /// Angkanya datang dari server (`distance_km`), bukan dihitung ulang
  /// di app, supaya urutannya dan angkanya pasti sepakat.
  String _jarak(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1).replaceAll('.', ',')} km';
  }

  /// Rp dengan pemisah ribuan bertitik, gaya Indonesia.
  String _rupiah(double harga) {
    final angka = harga.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) buf.write('.');
      buf.write(angka[i]);
    }
    return 'Rp $buf';
  }

  /// Harga ringkas untuk label di peta: "150rb", "1,5jt".
  ///
  /// Dipendekkan karena labelnya menempel di atas jarum dan berjejalan
  /// dengan label venue lain; "Rp 150.000/jam" utuh menutupi petanya
  /// sendiri. Bentuk lengkapnya tetap ada di kartu yang muncul saat
  /// jarumnya disentuh.
  String _hargaRingkas(double harga) {
    if (harga >= 1000000) {
      final juta = harga / 1000000;
      final teks = juta.toStringAsFixed(juta % 1 == 0 ? 0 : 1);
      return '${teks.replaceAll('.', ',')}jt';
    }
    if (harga >= 1000) return '${(harga / 1000).round()}rb';
    return harga.round().toString();
  }

  Marker _buildMarker(model.Venue v) {
    final isSel = _selected?.id == v.id;
    final harga = v.hargaMin;

    void pilih() {
      setState(() => _selected = v);
      _mapController.move(
        LatLng(v.latitude!, v.longitude!),
        _mapController.camera.zoom < 14 ? 14 : _mapController.camera.zoom,
      );
    }

    // Venue tanpa lapangan aktif tidak punya harga sama sekali. Jarum
    // polos untuk yang itu, bukan label "Rp 0" yang menyesatkan.
    if (harga == null) {
      return Marker(
        point: LatLng(v.latitude!, v.longitude!),
        width: 44,
        height: 44,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: pilih,
          child: Icon(
            Icons.location_on,
            size: isSel ? 44 : 36,
            color: context.c.accent,
            shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
          ),
        ),
      );
    }

    final teks = _hargaRingkas(harga);
    // Lebar Marker wajib pasti sebelum digambar, jadi ditaksir dari
    // panjang teksnya. 7.5 px per karakter pada ukuran 13 sudah cukup
    // longgar untuk angka dan huruf "rb"/"jt".
    final lebar = 34.0 + teks.length * 7.5;

    return Marker(
      point: LatLng(v.latitude!, v.longitude!),
      width: lebar,
      height: 40,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: pilih,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: isSel ? context.c.ink : context.c.accent,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white, width: 1.5),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black38,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                teks,
                maxLines: 1,
                style: TextStyle(
                  color: context.c.onAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Ekor kecil supaya labelnya terbaca menunjuk satu titik,
            // bukan melayang di antara dua tempat.
            Container(
              width: 2,
              height: 7,
              color: isSel ? context.c.ink : context.c.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  _circleBtn(
                    Icons.arrow_back_rounded,
                    () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.raised,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: context.c.line),
                    ),
                    child: Text(
                      "${_venues.length} arena di sekitar",
                      style: TextStyle(
                        color: context.c.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _barisFilter(),
          ],
        ),
      ),
    );
  }

  /// Saringan jenis lapangan, digulir mendatar.
  ///
  /// Disaring di server lewat parameter `sport`, bukan di app: daftarnya
  /// dibatasi 15 per halaman, jadi menyaring hasil yang sudah terpotong
  /// akan membuang venue yang sebenarnya cocok tapi tidak ikut terambil.
  Widget _barisFilter() {
    final butir = <MapEntry<String?, String>>[
      const MapEntry(null, 'Semua'),
      ..._jenisOlahraga.entries.map(
        (e) => MapEntry<String?, String>(e.key, e.value),
      ),
    ];

    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        itemCount: butir.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final e = butir[i];
          final aktif = _olahraga == e.key;
          return GestureDetector(
            onTap: _memuatUlang ? null : () => _gantiOlahraga(e.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: aktif ? context.c.accent : context.c.raised,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: aktif ? context.c.accent : context.c.line,
                ),
              ),
              child: Text(
                e.value,
                style: TextStyle(
                  color: aktif ? context.c.onAccent : context.c.ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Muat ulang daftar untuk area yang sedang terlihat.
  ///
  /// Backend tidak menerima kotak batas, jadi yang dikirim adalah pusat
  /// peta sebagai titik acuan: hasilnya 15 venue terdekat dari situ,
  /// diurutkan dari yang paling dekat.
  Widget _tombolCariArea() {
    return Positioned(
      top: MediaQuery.paddingOf(context).top + 114,
      left: 0,
      right: 0,
      child: Center(
        child: GestureDetector(
          onTap: _cariDiAreaIni,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: context.c.accent,
              borderRadius: BorderRadius.circular(999),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.refresh_rounded,
                  size: 18,
                  color: context.c.onAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  'Cari di area ini',
                  style: TextStyle(
                    color: context.c.onAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: context.c.raised,
          shape: BoxShape.circle,
          border: Border.all(color: context.c.line),
        ),
        child: Icon(icon, color: context.c.ink, size: 22),
      ),
    );
  }

  Widget _venueCard(model.Venue v) {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 28 + context.sisipanBawah,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VenueDetailPage(venueId: v.id)),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.c.raised,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.c.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _thumb(v),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      v.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.c.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: context.c.inkSoft,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            v.jarakKm != null
                                ? '${_jarak(v.jarakKm!)} · ${formatKota(v.city)}'
                                : formatKota(v.city),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: context.c.inkSoft,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        if (v.averageRating != null) ...[
                          Icon(
                            Icons.star_rounded,
                            size: 15,
                            color: context.c.accent,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            v.averageRating!.toStringAsFixed(1),
                            style: TextStyle(
                              color: context.c.ink,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    // Harga lengkap di kartu, bukan versi pendek seperti
                    // di labelnya: di sini ruangnya ada, dan angka inilah
                    // yang dipakai memutuskan mau membuka venuenya atau
                    // tidak. "Mulai" karena ini lapangan termurah di
                    // venue itu, bukan harga tunggal.
                    if (v.hargaMin != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Mulai ${_rupiah(v.hargaMin!)}/jam',
                        style: TextStyle(
                          color: context.c.accent,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: context.c.inkSoft),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumb(model.Venue v) {
    final url = v.coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        height: 64,
        width: 64,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
      );
    }
    return _thumbPlaceholder();
  }

  Widget _thumbPlaceholder() {
    return Container(
      height: 64,
      width: 64,
      color: context.c.hoverSurface,
      child: Icon(Icons.stadium_rounded, color: context.c.inkSoft, size: 26),
    );
  }
}
