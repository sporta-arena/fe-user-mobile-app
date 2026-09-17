import 'dart:async';

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
import '../models/banner_promo.dart';
import '../models/booking.dart';
import '../services/banner_service.dart';
import '../services/booking_service.dart';
import '../services/notifikasi_service.dart';
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

  late final List<Widget> _pages = <Widget>[
    DashboardContent(onBukaTab: (i) => setState(() => _selectedIndex = i)),
    const TransactionsPage(),
    const ProfilePage(),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        sel ? active : inactive,
                        color: sel ? context.c.accent : context.c.inkSoft,
                        size: 24,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        style: TextStyle(
                          color: sel ? context.c.accent : context.c.inkSoft,
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
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
  /// Pindah tab bawah dari dalam beranda.
  ///
  /// Kartu "Selesaikan pembayaran" mengarah ke tab Transaksi, bukan
  /// membuka sendiri layar pembayarannya: penyusunan data pembayaran
  /// di sana sudah ada dan cukup berliku (metode, biaya, string QR).
  /// Menyalinnya ke beranda berarti dua jalur yang bisa berbeda diam-
  /// diam begitu salah satunya berubah.
  final ValueChanged<int>? onBukaTab;

  const DashboardContent({super.key, this.onBukaTab});

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

  /// Booking milik pemakai, dipakai tiga blok teratas beranda.
  ///
  /// Dimuat sekali saat layar dibuka dan hanya kalau sudah masuk;
  /// tamu tidak punya apa pun untuk ditampilkan di situ.
  List<Booking> _booking = [];

  /// Jumlah notifikasi belum dibaca, untuk titik merah di lonceng.
  int _notifBelumDibaca = 0;

  /// Banner promo yang sedang tayang. Kosong berarti bagiannya tidak
  /// ditampilkan sama sekali, bukan menampilkan kotak kosong.
  List<BannerPromo> _banner = const [];
  final PageController _pageBanner = PageController(viewportFraction: 0.9);
  int _bannerAktif = 0;
  Timer? _geserBanner;

  /// Detik yang berdenyut untuk hitung mundur pembayaran.
  Timer? _detak;

  /// Booking yang belum dibayar dan belum kedaluwarsa.
  ///
  /// Slotnya cuma ditahan 10 menit. Pembayaran lewat m-banking berarti
  /// pemakai KELUAR dari app di tengah proses, dan waktu dia kembali
  /// tidak ada apa pun yang memberitahu sisa waktunya. Bookingnya lalu
  /// hangus, tercatat sebagai kedaluwarsa biasa, dan tidak ada yang
  /// tahu itu sebenarnya pembeli yang mau bayar.
  Booking? get _belumBayar {
    final kini = DateTime.now();
    for (final b in _booking) {
      if (b.status == 'pending' &&
          b.expiresAt != null &&
          b.expiresAt!.isAfter(kini)) {
        return b;
      }
    }
    return null;
  }

  /// Venue yang terakhir benar-benar dipakai main.
  ///
  /// Booking lapangan itu berulang: rombongan yang sama, lapangan yang
  /// sama, jam yang sama tiap minggu. Menawarkan pengulangan itu jauh
  /// lebih sering dipakai daripada seluruh bagian pencarian.
  Booking? get _terakhirMain {
    Booking? hasil;
    for (final b in _booking) {
      if (b.status != 'completed' && b.status != 'confirmed') continue;
      if (b.field?.venue == null) continue;
      if (hasil == null || b.createdAt.isAfter(hasil.createdAt)) hasil = b;
    }
    return hasil;
  }

  double? _jarakMeter(model.Venue v) {
    if (_lat == null || _lng == null) return null;
    if (v.latitude == null || v.longitude == null) return null;
    return Geolocator.distanceBetween(_lat!, _lng!, v.latitude!, v.longitude!);
  }

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
      return Geolocator.distanceBetween(
        _lat!,
        _lng!,
        v.latitude!,
        v.longitude!,
      );
    }

    daftar.sort((a, b) => jarak(a).compareTo(jarak(b)));
    return daftar;
  }

  bool get _adaJarak =>
      _lat != null &&
      _lng != null &&
      _venueTampil.any((v) => v.latitude != null && v.longitude != null);

  String get _judulTerdekat =>
      _adaJarak ? "Terdekat dari kamu" : "Arena tersedia";

  /// Arena yang paling banyak diulas.
  ///
  /// Bagian kedua dulu berjudul "Popular" dan isinya daftar yang sama
  /// persis, cuma dibalik urutannya. Itu peringkat karangan. Sekarang
  /// dasarnya jumlah ulasan asli, dan bagiannya disembunyikan selama
  /// belum ada satu pun ulasan.
  List<model.Venue> get _urutUlasan {
    final daftar = _venueTampil.where((v) => (v.reviewCount ?? 0) > 0).toList()
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
    _muatBooking();
    _muatJumlahNotif();
    _muatBanner();
  }

  Future<void> _muatBanner() async {
    final hasil = await BannerService.ambil();
    if (!mounted || hasil.isEmpty) return;
    setState(() => _banner = hasil);
    if (hasil.length > 1) _mulaiGeserBanner();
  }

  /// Geser sendiri tiap 5 detik.
  ///
  /// Carousel yang diam nyaris tidak pernah digeser orang, jadi banner
  /// kedua dan seterusnya tidak pernah terlihat. Lima detik cukup lama
  /// untuk dibaca dan cukup cepat untuk sempat berputar sebelum orang
  /// menggulir melewatinya.
  void _mulaiGeserBanner() {
    _geserBanner?.cancel();
    _geserBanner = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageBanner.hasClients || _banner.length < 2) return;
      final berikut = (_bannerAktif + 1) % _banner.length;
      _pageBanner.animateToPage(
        berikut,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  Future<void> _muatJumlahNotif() async {
    if (!AuthService.isLoggedIn) return;
    final hasil = await NotifikasiService.ambil();
    if (!mounted || hasil == null) return;
    setState(() => _notifBelumDibaca = hasil.belumDibaca);
  }

  /// Ambil booking pemakai untuk tiga blok teratas.
  Future<void> _muatBooking() async {
    if (!AuthService.isLoggedIn) return;
    try {
      final hasil = await BookingService.getMyBookings();
      if (!mounted || !hasil.success || hasil.bookings == null) return;
      setState(() => _booking = hasil.bookings!);

      // Denyut sedetik hanya dinyalakan kalau memang ada yang perlu
      // dihitung mundur, dan dimatikan lagi begitu waktunya habis.
      if (_belumBayar != null) _mulaiDetak();
    } catch (_) {}
  }

  void _mulaiDetak() {
    _detak?.cancel();
    _detak = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      if (_belumBayar == null) {
        t.cancel();
        // Sudah lewat: daftarnya diperbarui supaya bookingnya hilang
        // dari beranda, bukan membeku di 00:00.
        _muatBooking();
      }
      setState(() {});
    });
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
    _detak?.cancel();
    _geserBanner?.cancel();
    _pageBanner.dispose();
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
    }.toList()..sort();

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
                      leading: Icon(
                        Icons.location_city_rounded,
                        color: context.c.inkSoft,
                      ),
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
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        setState(
          () => _address = p.subLocality?.isNotEmpty == true
              ? p.subLocality!
              : (p.locality ?? "Lokasi kamu"),
        );
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

                // Urusan pemakai sendiri didahulukan dari katalog.
                // Yang balik lagi ke app ini datang buat lihat tiket
                // atau membayar, bukan buat mencari lapangan baru;
                // sebelumnya dua-duanya cuma ada di tab sebelah.
                // Tiap blok muncul hanya kalau memang ada isinya, jadi
                // pemakai baru tetap melihat beranda yang ramping.
                if (_belumBayar != null) _kartuBelumBayar(_belumBayar!),

                _searchBar(),
                const SizedBox(height: 20),

                // Banner di bawah pencarian, bukan di paling atas:
                // yang membuka app ini datang untuk memesan, dan promo
                // itu tawaran, bukan urusan yang sedang dia kerjakan.
                if (_banner.isNotEmpty) ...[
                  _carouselBanner(),
                  const SizedBox(height: 20),
                ],

                _categories(),
                const SizedBox(height: 24),
                _venueSection(_judulTerdekat, _urutTerdekat),

                // Seksi kedua ditahan sampai katalognya cukup tebal.
                // Dengan satu venue, "Terdekat" dan "Paling banyak
                // diulas" menampilkan kartu yang sama persis, dan itu
                // terbaca seperti rusak, bukan seperti kurasi.
                if (_venueTampil.length >= 5 && _urutUlasan.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  _venueSection("Paling banyak diulas", _urutUlasan),
                ],

                if (_terakhirMain != null) ...[
                  const SizedBox(height: 20),
                  _kartuMainLagi(_terakhirMain!),
                ],
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Tombol Peta mengambang dicabut 18 Sep 2026: ia menimpa
          // kartu venue paling bawah dan tidak bisa disingkirkan.
          // Sekarang jadi tombol bulat di kiri header.
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
          // Peta naik ke sini dari tombol mengambang di atas daftar.
          // Di posisi lamanya ia menimpa kartu venue paling bawah —
          // terlihat di dua tangkapan layar — dan satu-satunya cara
          // membacanya adalah menggulir melewatinya.
          _circleIcon(
            Icons.map_outlined,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapPage()),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _bukaPemilihLokasi,
              behavior: HitTestBehavior.opaque,
              child: Column(
                children: [
                  Text(
                    'Lokasi kamu',
                    style: TextStyle(color: context.c.inkDim, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          _address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.c.ink,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: context.c.ink,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          _circleIcon(
            Icons.notifications_none_rounded,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()),
            ),
            // Titiknya dari unread_count sungguhan, bukan dinyalakan
            // terus. Lencana yang selalu menyala berhenti berarti apa
            // pun setelah dua kali dilihat.
            bertitik: _notifBelumDibaca > 0,
          ),
        ],
      ),
    );
  }

  Widget _circleIcon(
    IconData icon,
    VoidCallback onTap, {
    bool bertitik = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: context.c.raised,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: context.c.ink, size: 21),
          ),
          if (bertitik)
            Positioned(
              right: 2,
              top: 2,
              child: Container(
                height: 9,
                width: 9,
                decoration: BoxDecoration(
                  color: context.c.danger,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.c.raised, width: 1.5),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ---- Blok booking pemakai ----------------------------------------------

  String _duaDigit(int n) => n.toString().padLeft(2, '0');

  /// Kartu aksi bergaya sama dengan kartu venue: putih, sudut 20,
  /// bayangan lembut, dan ikon di dalam lingkaran berwarna seperti
  /// baris kategori. Dipakai tiga blok booking supaya beranda terbaca
  /// sebagai satu bahasa, bukan tempelan yang masing-masing beda.
  Widget _kartuAksi({
    required IconData ikon,
    required Color warna,
    required String judul,
    required String isi,
    required VoidCallback onTap,
    Color? warnaJudul,
    Color? latar,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: latar ?? context.c.raised,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.c.line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warna, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: warnaJudul ?? context.c.ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isi,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.c.inkSoft,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: context.c.inkDim),
            ],
          ),
        ),
      ),
    );
  }

  /// Ada slot yang sedang ditahan dan belum dibayar.
  Widget _kartuBelumBayar(Booking b) {
    final sisa = b.expiresAt!.difference(DateTime.now());
    final menit = _duaDigit(sisa.inMinutes.remainder(60));
    final detik = _duaDigit(sisa.inSeconds.remainder(60));
    final nama = b.field?.venue?.name ?? b.field?.name ?? 'Booking kamu';

    return _kartuAksi(
      ikon: Icons.timer_outlined,
      warna: context.c.danger,
      warnaJudul: context.c.danger,
      latar: context.c.dangerSoft,
      judul: 'Selesaikan pembayaran · $menit:$detik',
      isi: '$nama · slot dilepas kalau waktunya habis',
      onTap: () => widget.onBukaTab?.call(1),
    );
  }

  /// "Main lagi di ..." — pengulangan booking terakhir.
  Widget _kartuMainLagi(Booking b) {
    final venue = b.field!.venue!;
    final jam = b.startTime.length >= 5
        ? b.startTime.substring(0, 5)
        : b.startTime;

    return _kartuAksi(
      ikon: Icons.replay_rounded,
      warna: context.c.info,
      judul: 'Main lagi di ${venue.name}?',
      isi: 'Terakhir ${b.field!.name} · $jam',
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VenueDetailPage(venueId: venue.id, venueName: venue.name),
        ),
      ),
    );
  }

  // ---- Banner promo ------------------------------------------------------

  Widget _carouselBanner() {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageBanner,
            itemCount: _banner.length,
            onPageChanged: (i) => setState(() => _bannerAktif = i),
            itemBuilder: (context, i) {
              final b = _banner[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () => _bukaBanner(b),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      b.gambarUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      // Banner yang gagal dimuat ditampilkan sebagai
                      // kotak berjudul, bukan ikon rusak: judulnya tetap
                      // membawa informasi promonya.
                      errorBuilder: (context, _, __) => Container(
                        color: context.c.accentSoft,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          b.judul,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: context.c.accent,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (_banner.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_banner.length, (i) {
              final aktif = i == _bannerAktif;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 6,
                width: aktif ? 18 : 6,
                decoration: BoxDecoration(
                  color: aktif ? context.c.accent : context.c.line,
                  borderRadius: BorderRadius.circular(999),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  void _bukaBanner(BannerPromo b) {
    switch (b.tujuanTipe) {
      case 'venue':
        final id = int.tryParse(b.tujuanNilai ?? '');
        if (id == null) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VenueDetailPage(venueId: id)),
        );
      case 'kategori':
        final jenis = b.tujuanNilai;
        if (jenis == null) return;
        final tipe = _fieldTypes.where((t) => t.value == jenis).firstOrNull;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CategoryVenuesPage(
              categoryName: tipe?.label ?? jenis,
              categoryIcon: tipe?.icon ?? Icons.sports,
              categoryColor: context.c.kategori(tipe?.indeksWarna ?? 0),
              fieldType: jenis,
            ),
          ),
        );
      default:
        // Banner pengumuman atau berpromo tanpa tujuan: kodenya dibaca
        // dari gambarnya dan diketik sendiri di layar bayar. Tidak ada
        // yang perlu dibuka, jadi ketukannya sengaja tidak melakukan
        // apa-apa daripada membuka layar yang tidak nyambung.
        break;
    }
  }

  // ---- Search -------------------------------------------------------------
  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SearchPage(keyword: "")),
        ),
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            // Bidang masuk ke dalam tanpa garis tepi: kolom cari yang
            // dikelilingi garis terbaca seperti kotak isian yang sedang
            // menunggu diketik, padahal ini tombol menuju layar cari.
            color: context.c.sunken,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            children: [
              Icon(Icons.search_rounded, color: context.c.inkDim, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Cari arena, venue...",
                  style: TextStyle(color: context.c.inkDim, fontSize: 15),
                ),
              ),
              Container(width: 1, height: 22, color: context.c.line),
              const SizedBox(width: 14),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AllCategoriesPage()),
                ),
                child: Icon(Icons.tune_rounded, color: context.c.ink, size: 21),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- Categories ---------------------------------------------------------

  /// Kategori sebagai lingkaran berwarna, bukan pil.
  ///
  /// Sebelumnya pil, dan begitu pintasan "Mau main kapan?" ditambahkan
  /// di atasnya jadi dua baris pil berdempetan yang bentuknya nyaris
  /// sama — mata tidak punya petunjuk mana yang lebih penting. Bentuk
  /// yang berbeda memisahkan keduanya tanpa perlu garis atau jarak.
  Widget _categories() {
    return SizedBox(
      height: 86,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _kategoriBulat(
            ikon: Icons.grid_view_rounded,
            label: 'Semua',
            warna: context.c.accent,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AllCategoriesPage()),
            ),
          ),
          ..._fieldTypes.map(_categoryChip),
        ],
      ),
    );
  }

  Widget _kategoriBulat({
    required IconData ikon,
    required String label,
    required Color warna,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 18),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 60,
          child: Column(
            children: [
              Container(
                height: 56,
                width: 56,
                decoration: BoxDecoration(
                  color: warna.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(ikon, color: warna, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryChip(FieldType type) {
    final warna = context.c.kategori(type.indeksWarna);
    return _kategoriBulat(
      ikon: type.icon,
      label: type.label,
      warna: warna,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryVenuesPage(
            categoryName: type.label,
            categoryIcon: type.icon,
            categoryColor: warna,
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
              Text(
                title,
                style: TextStyle(
                  color: context.c.ink,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SearchPage(keyword: ""),
                  ),
                ),
                child: Text(
                  "Lihat semua",
                  style: TextStyle(
                    color: context.c.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          // Naik dari 232: kartunya sekarang lebih lebar dan membawa
          // foto lebih besar, harga, jam buka, dan tombol jadwal.
          height: 332,
          child: _loadingVenues
              ? Center(
                  child: CircularProgressIndicator(color: context.c.accent),
                )
              : venues.isEmpty
              ? _emptyVenues()
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: venues.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
                  itemBuilder: (_, i) => _VenueCard(
                    venue: venues[i],
                    jarakMeter: _jarakMeter(venues[i]),
                  ),
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
        child: Text(
          "Belum ada venue.",
          style: TextStyle(color: context.c.inkSoft),
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

  /// Jarak dari pemakai dalam meter; null kalau lokasinya belum ada.
  ///
  /// Dihitung di beranda dengan Geolocator dari koordinat yang sudah
  /// ikut di daftar venue, jadi tidak ada permintaan tambahan.
  final double? jarakMeter;

  const _VenueCard({required this.venue, this.jarakMeter});

  void _bukaJadwal(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            VenueDetailPage(venueId: venue.id, venueName: venue.name),
      ),
    );
  }

  /// Rp dengan pemisah ribuan bertitik.
  String _rupiah(double harga) {
    final angka = harga.round().toString();
    final buf = StringBuffer();
    for (var i = 0; i < angka.length; i++) {
      if (i > 0 && (angka.length - i) % 3 == 0) buf.write('.');
      buf.write(angka[i]);
    }
    return 'Rp $buf';
  }

  String _jarakSingkat(double meter) => meter < 1000
      ? '${meter.round()} m'
      : '${(meter / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';

  @override
  Widget build(BuildContext context) {
    final rating = venue.averageRating;
    return GestureDetector(
      onTap: () => _bukaJadwal(context),
      child: Container(
        // Lebar naik dari 216. Kartu sempit memaksa nama venue terpotong
        // dan tidak menyisakan ruang untuk harga; kartu lebar memuat
        // semuanya dan tetap menyisakan kartu berikutnya mengintip di
        // tepi, yang justru memberi tahu daftarnya bisa digeser.
        width: 296,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.c.line),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _image(context),
                ),
                if (jarakMeter != null)
                  Positioned(
                    left: 10,
                    top: 10,
                    child: _lencana(
                      context,
                      Icons.near_me_outlined,
                      _jarakSingkat(jarakMeter!),
                    ),
                  ),
                Positioned(
                  right: 10,
                  top: 10,
                  child: _lencana(
                    context,
                    Icons.star_rounded,
                    rating != null ? rating.toStringAsFixed(1) : 'Baru',
                    warnaIkon: context.c.warn,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              venue.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: context.c.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.location_on_outlined,
                  color: context.c.inkDim,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    formatKota(venue.city),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Jam buka di kiri, harga di kanan — sejajar dengan cara
                // kartu properti menaruh keterangan kecil di kiri dan
                // angka besar di kanan. Harga yang paling menentukan,
                // jadi harga yang paling besar.
                Expanded(
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        color: context.c.inkDim,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          venue.formattedOpenHours,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: context.c.inkSoft,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (venue.hargaMin != null)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _rupiah(venue.hargaMin!),
                        style: TextStyle(
                          color: context.c.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        ' /jam',
                        style: TextStyle(
                          color: context.c.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _bukaJadwal(context),
                style: FilledButton.styleFrom(
                  backgroundColor: context.c.accent,
                  foregroundColor: context.c.onAccent,
                  minimumSize: const Size(0, 40),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Lihat Jadwal',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Lencana putih melayang di atas foto.
  Widget _lencana(
    BuildContext context,
    IconData ikon,
    String teks, {
    Color? warnaIkon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 14, color: warnaIkon ?? context.c.accent),
          const SizedBox(width: 4),
          Text(
            teks,
            style: TextStyle(
              color: context.c.ink,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
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
      olahraga: venue.fields?.isNotEmpty == true
          ? venue.fields!.first.type
          : null,
      lebar: 276,
      tinggi: 150,
      ukuranInisial: 30,
    );
  }

  // Ikon fasilitas (wifi, parkir, toilet) dicabut dari kartu ini
  // 18 Sep 2026, diganti harga dan tombol jadwal. Orang memilih
  // lapangan dengan harga, jarak, dan jam kosong; wifi dan toilet
  // tidak pernah menentukan. Daftar fasilitas lengkapnya tetap ada
  // di halaman detail venue, tempat orang memang mencarinya.
}
