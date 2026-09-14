import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/push_notifikasi.dart';
import '../services/realtime_chat.dart';
import '../utils/tampilan_venue.dart';
import '../theme/app_tokens.dart';
import '../widgets/sampul_venue.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'search_page.dart';
import 'all_categories_page.dart';
import 'category_venues_page.dart';
import 'venue_detail_page.dart';
import 'notifications_page.dart';
import 'map_page.dart';
import 'transactions_page.dart';
import 'profile_page.dart';

import '../services/venue_service.dart';
import '../services/field_type_service.dart';
import '../models/venue.dart' as model;
import '../models/field_type.dart';

class HomePage extends StatefulWidget {
  /// Tab yang dibuka pertama (0=Beranda, 1=Transaksi, 2=Profil).
  final int initialIndex;
  const HomePage({super.key, this.initialIndex = 0});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// Convenience wrapper to open [HomePage] on a specific bottom-nav tab.
class HomePageWithTab extends StatelessWidget {
  final int initialIndex;
  const HomePageWithTab({super.key, required this.initialIndex});

  @override
  Widget build(BuildContext context) => HomePage(initialIndex: initialIndex);
}

class _HomePageState extends State<HomePage> {
  late int _selectedIndex = widget.initialIndex;

  static const List<Widget> _pages = <Widget>[
    DashboardContent(),
    TransactionsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: _BottomNav(
        selectedIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
      ),
    );
  }
}

// ===========================================================================
// BOTTOM NAVIGATION
// ===========================================================================
class _BottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.selectedIndex, required this.onTap});

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Beranda'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Transaksi'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        border: Border(top: BorderSide(color: context.c.line)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (i) {
              final sel = selectedIndex == i;
              final (active, inactive, label) = _items[i];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(sel ? active : inactive,
                          color: sel ? context.c.accent : context.c.inkSoft,
                          size: 24),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            color: sel
                                ? context.c.accent
                                : context.c.inkSoft,
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// DASHBOARD
// ===========================================================================
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  /// Langganan notifikasi realtime milik pemesan yang sedang masuk.
  RealtimeChat? _notifRealtime;

  String _address = "Mencari lokasi…";

  /// Titik pemakai, dipakai untuk mengurutkan daftar terdekat.
  /// null berarti izin lokasi ditolak atau GPS gagal, dan judul
  /// bagiannya ikut berubah supaya tidak mengaku "terdekat".
  double? _lat;
  double? _lng;

  /// Kota yang dipilih lewat chip lokasi; null berarti semua kota.
  String? _kotaTerpilih;

  List<model.Venue> get _venueTampil => _kotaTerpilih == null
      ? _venues
      : _venues.where((v) => v.city == _kotaTerpilih).toList();
  List<model.Venue> _venues = [];
  List<FieldType> _fieldTypes = [];

  /// Arena yang benar-benar diurutkan dari titik pemakai.
  ///
  /// Sebelumnya bagian ini berjudul "Nearby from you" tapi isinya urutan
  /// apa adanya dari API, tanpa sekalipun menghitung jarak. Sekarang
  /// urutannya nyata, dan kalau titik pemakai belum ada, judulnya yang
  /// mengalah lewat [_judulTerdekat].
  List<model.Venue> get _urutTerdekat {
    final daftar = [..._venueTampil];
    if (_lat == null || _lng == null) return daftar;
    double jarak(model.Venue v) {
      if (v.latitude == null || v.longitude == null) return double.infinity;
      return Geolocator.distanceBetween(_lat!, _lng!, v.latitude!, v.longitude!);
    }
    daftar.sort((a, b) => jarak(a).compareTo(jarak(b)));
    return daftar;
  }

  bool get _adaJarak =>
      _lat != null &&
      _lng != null &&
      _venueTampil.any((v) => v.latitude != null && v.longitude != null);

  String get _judulTerdekat => _adaJarak ? "Terdekat dari kamu" : "Arena tersedia";

  /// Arena yang paling banyak diulas.
  ///
  /// Bagian kedua dulu berjudul "Popular" dan isinya daftar yang sama
  /// persis, cuma dibalik urutannya. Itu peringkat karangan. Sekarang
  /// dasarnya jumlah ulasan asli, dan bagiannya disembunyikan selama
  /// belum ada satu pun ulasan.
  List<model.Venue> get _urutUlasan {
    final daftar = _venueTampil
        .where((v) => (v.reviewCount ?? 0) > 0)
        .toList()
      ..sort((a, b) {
        final ulasan = (b.reviewCount ?? 0).compareTo(a.reviewCount ?? 0);
        if (ulasan != 0) return ulasan;
        return (b.averageRating ?? 0).compareTo(a.averageRating ?? 0);
      });
    return daftar;
  }
  bool _loadingVenues = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _loadFieldTypes();
    _getLocation();
    _sambungkanNotifikasi();
    // Push disiapkan sesudah pemesan masuk: sebelum itu tidak ada
    // pengguna yang bisa dikaitkan dengan tokennya, dan token tanpa
    // pemilik hanya jadi baris yatim di server.
    if (AuthService.isLoggedIn) PushNotifikasi.siapkan();
  }

  /// Sambungkan ke kanal notifikasi milik pemesan yang sedang masuk.
  ///
  /// Sebelumnya notifikasi hanya dimuat saat halaman notifikasi dibuka.
  /// Pembayaran yang lunas atau jadwal yang dibatalkan mitra baru
  /// diketahui kalau pemesan kebetulan membukanya.
  void _sambungkanNotifikasi() {
    final id = AuthService.currentUser?.id;
    if (id == null) return;

    _notifRealtime = RealtimeChat.dengarkanKanal(
      namaKanal: namaKanalPengguna(id),
      namaEvent: namaEventNotifikasi,
      onPesan: (muatan) {
        if (!mounted) return;
        final judul = muatan['title']?.toString() ?? 'Pemberitahuan baru';
        final isi = muatan['body']?.toString() ?? '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$judul\n$isi'.trim()),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // WebSocket yang tidak ditutup tetap hidup di latar, memegang
    // sambungan dan menyambung ulang selamanya walau layarnya sudah
    // tidak ada.
    _notifRealtime?.tutup();
    super.dispose();
  }

  Future<void> _loadVenues() async {
    try {
      final result = await VenueService.getVenues();
      if (mounted && result.success && result.venues != null) {
        setState(() {
          _venues = result.venues!;
          _loadingVenues = false;
        });
      } else if (mounted) {
        setState(() => _loadingVenues = false);
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVenues = false);
    }
  }

  Future<void> _loadFieldTypes() async {
    final types = await FieldTypeService.getFieldTypes();
    if (mounted) setState(() => _fieldTypes = types);
  }

  /// Lembar pemilih lokasi.
  ///
  /// Chip lokasi punya tanda panah ke bawah, yang menjanjikan pilihan,
  /// tapi ketukannya dulu hanya memanggil _getLocation. Kalau izin lokasi
  /// sudah pernah diberikan, GPS mengembalikan tempat yang sama dan
  /// layarnya tidak berubah sama sekali, sehingga terasa seperti tombol
  /// mati. Dan tidak pernah ada cara memilih kota lain.
  Future<void> _bukaPemilihLokasi() async {
    final kota = <String>{
      for (final v in _venues)
        if (v.city.trim().isNotEmpty) v.city,
    }.toList()
      ..sort();

    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.c.raised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pilih Lokasi',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: context.c.ink,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.my_location_rounded, color: context.c.accent),
              title: const Text('Gunakan lokasi saya'),
              subtitle: const Text('Venue terdekat diurutkan dari titik Anda'),
              onTap: () {
                Navigator.pop(sheetContext);
                _getLocation();
              },
            ),
            if (_kotaTerpilih != null)
              ListTile(
                leading: Icon(Icons.public_rounded, color: context.c.inkSoft),
                title: const Text('Semua kota'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  setState(() {
                    _kotaTerpilih = null;
                    _address = 'Semua kota';
                  });
                },
              ),
            if (kota.isNotEmpty) Divider(height: 1, color: context.c.line),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final k in kota)
                    ListTile(
                      leading: Icon(Icons.location_city_rounded,
                          color: context.c.inkSoft),
                      title: Text(formatKota(k)),
                      onTap: () {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _kotaTerpilih = k;
                          _address = formatKota(k);
                        });
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (mounted) setState(() => _address = "Pilih lokasi");
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
        });
      }
      final placemarks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(() => _address =
            p.subLocality?.isNotEmpty == true ? p.subLocality! : (p.locality ?? "Lokasi kamu"));
      }
    } catch (_) {
      if (mounted) setState(() => _address = "Pilih lokasi");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          RefreshIndicator(
            color: context.c.accent,
            backgroundColor: context.c.raised,
            onRefresh: () async {
              await Future.wait([_loadVenues(), _loadFieldTypes()]);
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                _header(),
                const SizedBox(height: 16),
                _searchBar(),
                const SizedBox(height: 20),
                _categories(),
                const SizedBox(height: 24),
                _venueSection(_judulTerdekat, _urutTerdekat),
                if (_urutUlasan.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _venueSection("Paling banyak diulas", _urutUlasan),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Floating Map button
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: _mapButton()),
          ),
        ],
      ),
    );
  }

  // ---- Header -------------------------------------------------------------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _bukaPemilihLokasi,
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      color: context.c.accent, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _address,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.c.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: context.c.ink, size: 22),
                ],
              ),
            ),
          ),
          _circleIcon(
            Icons.notifications_none_rounded,
            () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsPage())),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 42,
        width: 42,
        decoration: BoxDecoration(
          color: context.c.raised,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: context.c.ink, size: 22),
      ),
    );
  }

  // ---- Search -------------------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SearchPage(keyword: ""))),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.c.raised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: context.c.line),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: context.c.inkSoft, size: 22),
              SizedBox(width: 10),
              Text("Cari arena",
                  style: TextStyle(color: context.c.inkSoft, fontSize: 15)),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Categories ---------------------------------------------------------
  Widget _categories() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" button
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AllCategoriesPage())),
            child: Container(
              height: 40,
              width: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: context.c.accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.grid_view_rounded,
                  color: context.c.onAccent, size: 20),
            ),
          ),
          ..._fieldTypes.map(_categoryChip),
        ],
      ),
    );
  }

  Widget _categoryChip(FieldType type) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryVenuesPage(
              categoryName: type.label,
              categoryIcon: type.icon,
              categoryColor: context.c.kategori(type.indeksWarna),
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: context.c.raised,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.c.line),
          ),
          child: Row(
            children: [
              Icon(type.icon, color: context.c.accent, size: 18),
              const SizedBox(width: 8),
              Text(type.label,
                  style: TextStyle(
                      color: context.c.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Venue section ------------------------------------------------------
  Widget _venueSection(String title, List<model.Venue> venues) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: TextStyle(
                      color: context.c.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchPage(keyword: ""))),
                child: Text("Lihat semua",
                    style: TextStyle(
                        color: context.c.accent,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: _loadingVenues
              ? Center(
                  child: CircularProgressIndicator(color: context.c.accent))
              : venues.isEmpty
                  ? _emptyVenues()
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: venues.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 14),
                      itemBuilder: (_, i) => _VenueCard(venue: venues[i]),
                    ),
        ),
      ],
    );
  }

  Widget _emptyVenues() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Belum ada venue.",
            style: TextStyle(color: context.c.inkSoft)),
      ),
    );
  }

  // ---- Map button ---------------------------------------------------------
  Widget _mapButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MapPage()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: context.c.accent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, color: context.c.onAccent, size: 20),
            SizedBox(width: 8),
            Text("Peta",
                style: TextStyle(
                    color: context.c.onAccent,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// VENUE CARD
// ===========================================================================
class _VenueCard extends StatelessWidget {
  final model.Venue venue;
  const _VenueCard({required this.venue});

  @override
  Widget build(BuildContext context) {
    final rating = venue.averageRating;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VenueDetailPage(venueId: venue.id)),
      ),
      child: Container(
        width: 216,
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.c.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: _image(context),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          venue.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.c.ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(Icons.star_rounded,
                          color: context.c.accent, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        rating != null ? rating.toStringAsFixed(1) : "Baru",
                        style: TextStyle(
                          color: context.c.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined,
                          color: context.c.inkSoft, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          formatKota(venue.city),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: context.c.inkSoft, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _facilities(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image(BuildContext context) {
    // Venue tanpa foto dulu semuanya jatuh ke satu kotak abu-abu dengan
    // ikon stadion yang sama, jadi daftarnya terbaca seperti deretan
    // kartu kosong. Sampulnya sekarang berwarna dan berinisial.
    return SampulVenue(
      nama: venue.name,
      urlGambar: venue.coverImageUrl,
      olahraga: venue.fields?.isNotEmpty == true ? venue.fields!.first.type : null,
      lebar: 216,
      tinggi: 120,
      ukuranInisial: 30,
    );
  }

  Widget _facilities(BuildContext context) {
    final icons = venue.facilities.take(4).map(_facilityIcon).toList();
    if (icons.isEmpty) {
      return Text(
        // Pakai formattedOpenHours, bukan nilai mentah: API menyimpan jam
        // operasional sebagai UTC dan setiap permukaan menggesernya +7.
        // Tanpa ini, venue yang buka 08.00 tampil buka pukul 01.00.
        venue.formattedOpenHours,
        style: TextStyle(color: context.c.inkSoft, fontSize: 11),
      );
    }
    return Row(
      children: [
        for (final ic in icons)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(ic, color: context.c.inkSoft, size: 16),
          ),
      ],
    );
  }

  IconData _facilityIcon(String f) {
    final s = f.toLowerCase();
    if (s.contains('wifi')) return Icons.wifi_rounded;
    if (s.contains('park')) return Icons.local_parking_rounded;
    if (s.contains('toilet') || s.contains('wc')) return Icons.wc_rounded;
    if (s.contains('musho') || s.contains('pray') || s.contains('sholat')) {
      return Icons.mosque_rounded;
    }
    if (s.contains('cafe') || s.contains('food') || s.contains('kantin')) {
      return Icons.restaurant_rounded;
    }
    if (s.contains('shower') || s.contains('mandi')) return Icons.shower_rounded;
    if (s.contains('ac')) return Icons.ac_unit_rounded;
    if (s.contains('locker') || s.contains('loker')) return Icons.lock_rounded;
    return Icons.check_circle_outline_rounded;
  }
}
