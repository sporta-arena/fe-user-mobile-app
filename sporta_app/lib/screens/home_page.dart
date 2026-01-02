import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Untuk Koordinat GPS
import 'package:geocoding/geocoding.dart';   // Untuk Ubah Koordinat jadi Alamat
import 'search_page.dart';       // Import Halaman Pencarian
import 'promo_detail_page.dart'; // Import Halaman Detail Promo & All Promos
import 'all_categories_page.dart'; // Import Halaman Semua Kategori
import 'discover_page.dart'; // Import Halaman Discover
import 'transactions_page.dart'; // Import Halaman Transactions
// messages_page.dart removed from bottom nav - chat now accessible via E-Ticket
import 'category_venues_page.dart'; // Import Halaman Venue per Kategori
import 'loyalty_page.dart'; // Import Halaman Loyalty
import 'venue_detail_page.dart'; // Import Halaman Detail Venue
import 'profile_page.dart'; // Import Halaman Profile
import '../services/venue_service.dart';
import '../services/favorite_service.dart'; // Import Favorite Service
import '../services/field_type_service.dart'; // Import Field Type Service
import '../models/venue.dart' as model;
import '../models/field_type.dart'; // Import Field Type Model

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // State Menu Bawah

  // Daftar Halaman (Home, Discover, Transactions, Profile)
  static final List<Widget> _pages = <Widget>[
    const DashboardContent(), // Halaman Utama
    const DiscoverPage(), // Halaman Discover
    const TransactionsPage(), // Halaman Transactions
    const ProfilePage(), // Halaman Profile
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Background agak abu sedikit
      body: _pages[_selectedIndex],

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Discover'),
                _buildNavItem(2, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Transaksi'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0047FF).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF0047FF) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0047FF) : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET ISI DASHBOARD UTAMA
// ==========================================
class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  // Variabel Lokasi
  String _currentAddress = "Mencari Lokasi...";
  bool _isLoadingLocation = false;
  bool _isLoadingVenues = false;
  Position? _currentPosition; // Tambah variabel untuk menyimpan posisi GPS

  // Data venue dari API
  List<model.Venue> _apiVenues = [];

  // Field types dari API
  List<FieldType> _fieldTypes = [];
  bool _isLoadingFieldTypes = false;

  // Favorite Service
  final FavoriteService _favoriteService = FavoriteService();

  // Promo banner page controller
  final PageController _promoPageController = PageController(viewportFraction: 0.9);
  int _currentPromoPage = 0;

  // Data venue dari API (tidak pakai hardcode lagi)
  // Venues dari API

  // List venue terdekat (akan diupdate berdasarkan lokasi)
  List<Map<String, dynamic>> _nearbyVenues = [];

  @override
  void initState() {
    super.initState();
    _loadVenuesFromApi(); // Load venues dari API
    _loadFieldTypes(); // Load field types dari API
    _getCurrentLocation(); // Otomatis cari lokasi saat dibuka
    // _setDefaultVenues(); // DISABLED - tidak pakai hardcode lagi

    // Listen to favorite changes
    _favoriteService.addListener(_onFavoritesChanged);
  }

  @override
  void dispose() {
    _favoriteService.removeListener(_onFavoritesChanged);
    _promoPageController.dispose();
    super.dispose();
  }

  void _onFavoritesChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  // --- LOAD FIELD TYPES DARI API ---
  Future<void> _loadFieldTypes() async {
    setState(() => _isLoadingFieldTypes = true);

    final types = await FieldTypeService.getFieldTypes();

    if (mounted) {
      setState(() {
        _fieldTypes = types;
        _isLoadingFieldTypes = false;
      });
    }
  }

  // --- LOAD VENUES DARI API ---
  Future<void> _loadVenuesFromApi() async {
    setState(() => _isLoadingVenues = true);

    try {
      final result = await VenueService.getVenues();

      if (mounted && result.success && result.venues != null) {
        setState(() {
          _apiVenues = result.venues!;
          _isLoadingVenues = false;
        });

        // Convert API venues to map format untuk nearby
        _convertApiVenuesToNearby();
      } else {
        setState(() => _isLoadingVenues = false);
      }
    } catch (e) {
      debugPrint("Error loading venues: $e");
      if (mounted) {
        setState(() => _isLoadingVenues = false);
      }
    }
  }

  // --- CONVERT API VENUES KE FORMAT MAP ---
  void _convertApiVenuesToNearby() {
    if (_apiVenues.isEmpty) return;

    final colors = [Colors.blueAccent, Colors.green, Colors.orange, Colors.cyan, Colors.red, Colors.purple];

    List<Map<String, dynamic>> venuesFromApi = _apiVenues.map((venue) {
      int index = _apiVenues.indexOf(venue) % colors.length;
      return {
        'id': venue.id,
        'name': venue.name,
        'location': '${venue.address}, ${venue.city}',
        'price': 'Lihat Detail',
        'rating': '4.5',
        'imageColor': colors[index],
        'category': 'Olahraga',
        'latitude': venue.latitude ?? -6.2,
        'longitude': venue.longitude ?? 106.8,
        'facilities': venue.facilities,
        'coverImageUrl': venue.coverImageUrl,
      };
    }).toList();

    setState(() {
      if (_currentPosition != null) {
        // Sort berdasarkan jarak jika ada posisi
        for (var venue in venuesFromApi) {
          if (venue['latitude'] != null && venue['longitude'] != null) {
            double distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              venue['latitude'],
              venue['longitude'],
            );
            venue['distance'] = distance / 1000;
            venue['distanceText'] = distance < 1000
                ? '${distance.round()} m'
                : '${(distance / 1000).toStringAsFixed(1)} km';
          }
        }
        venuesFromApi.sort((a, b) => (a['distance'] ?? 999).compareTo(b['distance'] ?? 999));
      }

      _nearbyVenues = venuesFromApi.take(3).toList();
    });
  }

  // --- LOGIKA MENCARI LOKASI ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS mati. Harap nyalakan GPS.';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Izin lokasi ditolak';
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen. Buka pengaturan HP.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude, 
        position.longitude
      );

      Placemark place = placemarks[0];
      
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _currentAddress = "${place.subLocality}, ${place.locality}";
          _isLoadingLocation = false;
        });

        // Update nearby venues berdasarkan lokasi (hanya dari API)
        if (_apiVenues.isNotEmpty) {
          _sortVenuesByDistance(); // Sort arena terdekat
          _convertApiVenuesToNearby();
        }
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Gagal memuat lokasi";
          _isLoadingLocation = false;
        });

        // Tidak pakai hardcode fallback - tetap ambil dari API
        if (_apiVenues.isNotEmpty) {
          _convertApiVenuesToNearby();
        }
      }
      debugPrint("Error Lokasi: $e");
    }
  }

  // --- SORT VENUES BERDASARKAN JARAK ---
  void _sortVenuesByDistance() {
    if (_currentPosition == null || _apiVenues.isEmpty) return;

    _apiVenues.sort((a, b) {
      // Venue tanpa koordinat diletakkan di belakang
      if (a.latitude == null || a.longitude == null) return 1;
      if (b.latitude == null || b.longitude == null) return -1;

      double distanceA = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        a.latitude!,
        a.longitude!,
      );
      double distanceB = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        b.latitude!,
        b.longitude!,
      );

      return distanceA.compareTo(distanceB);
    });

    setState(() {}); // Refresh UI
  }

  // --- HITUNG JARAK DAN UPDATE NEARBY VENUES ---
  void _updateNearbyVenues() {
    if (_currentPosition == null) return;

    List<Map<String, dynamic>> venuesWithDistance = [];
    
    // Convert _apiVenues to Map format for distance calculation
    for (var venue in _apiVenues) {
      // Skip venues without coordinates
      if (venue.latitude == null || venue.longitude == null) continue;
      
      Map<String, dynamic> venueMap = {
        'id': venue.id,
        'name': venue.name,
        'location': '${venue.address}, ${venue.city}',
        'price': 150000, // Default price, should come from fields
        'rating': 4.5, // Default rating
        'category': 'Sports', // Default category
        'latitude': venue.latitude!,
        'longitude': venue.longitude!,
        'imageUrl': venue.coverImageUrl ?? '',
      };
      
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        venue.latitude!,
        venue.longitude!,
      );
      
      // Convert meter ke kilometer
      double distanceKm = distance / 1000;
      
      venueMap['distance'] = distanceKm;
      venueMap['distanceText'] = distanceKm < 1 
          ? '${(distance).round()} m'
          : '${distanceKm.toStringAsFixed(1)} km';
      
      venuesWithDistance.add(venueMap);
    }
    
    // Sort berdasarkan jarak terdekat
    venuesWithDistance.sort((a, b) => a['distance'].compareTo(b['distance']));
    
    setState(() {
      _nearbyVenues = venuesWithDistance.take(3).toList(); // Ambil 3 terdekat
    });
  }

  // --- SET DEFAULT VENUES JIKA GPS GAGAL ---
  void _setDefaultVenues() {
    setState(() {
      _nearbyVenues = _apiVenues.take(3).map((venue) {
        return {
          'id': venue.id,
          'name': venue.name,
          'location': '${venue.address}, ${venue.city}',
          'price': 150000, // Default price
          'rating': 4.5, // Default rating
          'category': 'Sports', // Default category
          'latitude': venue.latitude ?? 0.0,
          'longitude': venue.longitude ?? 0.0,
          'imageUrl': venue.coverImageUrl ?? '',
          'distanceText': '-- km',
        };
      }).toList();
    });
  }

  // --- REFRESH ALL DATA ---
  Future<void> _refreshData() async {
    await Future.wait([
      _loadVenuesFromApi(),
      _loadFieldTypes(),
      _getCurrentLocation(),
    ]);
  }

  // --- SHOW NOTIFICATIONS ---
  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Notifikasi",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Semua notifikasi ditandai sudah dibaca"),
                          backgroundColor: Color(0xFF0047FF),
                        ),
                      );
                    },
                    child: const Text(
                      "Tandai Dibaca",
                      style: TextStyle(color: Color(0xFF0047FF)),
                    ),
                  ),
                ],
              ),
            ),

            // Notification List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _buildNotificationItem(
                    icon: Icons.check_circle,
                    iconColor: Colors.green,
                    title: "Booking Berhasil!",
                    message: "Booking lapangan Futsal A di GOR Sudirman telah dikonfirmasi untuk besok jam 19:00",
                    time: "5 menit lalu",
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.local_offer,
                    iconColor: Colors.orange,
                    title: "Promo Spesial!",
                    message: "Diskon 30% untuk booking di hari kerja. Gunakan kode SPORTA30",
                    time: "1 jam lalu",
                    isUnread: true,
                  ),
                  _buildNotificationItem(
                    icon: Icons.access_time,
                    iconColor: Colors.blue,
                    title: "Pengingat Booking",
                    message: "Jangan lupa! Kamu punya booking besok di Lapangan Badminton B jam 08:00",
                    time: "3 jam lalu",
                    isUnread: false,
                  ),
                  _buildNotificationItem(
                    icon: Icons.star,
                    iconColor: Colors.amber,
                    title: "Beri Rating",
                    message: "Bagaimana pengalamanmu bermain di GOR Senayan? Beri rating sekarang",
                    time: "Kemarin",
                    isUnread: false,
                  ),
                  _buildNotificationItem(
                    icon: Icons.campaign,
                    iconColor: Colors.purple,
                    title: "Info Terbaru",
                    message: "Venue baru tersedia! Cek Arena Sport Center dengan fasilitas lengkap",
                    time: "2 hari lalu",
                    isUnread: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SHOW LOCATION PICKER ---
  void _showLocationPicker() {
    final cities = [
      {'name': 'Jakarta Selatan', 'region': 'DKI Jakarta'},
      {'name': 'Jakarta Pusat', 'region': 'DKI Jakarta'},
      {'name': 'Jakarta Barat', 'region': 'DKI Jakarta'},
      {'name': 'Jakarta Timur', 'region': 'DKI Jakarta'},
      {'name': 'Jakarta Utara', 'region': 'DKI Jakarta'},
      {'name': 'Tangerang', 'region': 'Banten'},
      {'name': 'Tangerang Selatan', 'region': 'Banten'},
      {'name': 'Bekasi', 'region': 'Jawa Barat'},
      {'name': 'Depok', 'region': 'Jawa Barat'},
      {'name': 'Bogor', 'region': 'Jawa Barat'},
      {'name': 'Bandung', 'region': 'Jawa Barat'},
      {'name': 'Surabaya', 'region': 'Jawa Timur'},
      {'name': 'Yogyakarta', 'region': 'DIY'},
      {'name': 'Semarang', 'region': 'Jawa Tengah'},
      {'name': 'Medan', 'region': 'Sumatera Utara'},
      {'name': 'Makassar', 'region': 'Sulawesi Selatan'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Pilih Lokasi",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Use current location button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                  _getCurrentLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Row(
                        children: [
                          SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          ),
                          SizedBox(width: 12),
                          Text("Mendapatkan lokasi saat ini..."),
                        ],
                      ),
                      backgroundColor: Color(0xFF0047FF),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0047FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF0047FF).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0047FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.my_location, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Gunakan Lokasi Saat Ini",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Color(0xFF0047FF),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              "Aktifkan GPS untuk lokasi akurat",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF0047FF)),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Divider with text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      "atau pilih kota",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.grey[300])),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // City list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  final isSelected = _currentAddress == city['name'];

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _currentAddress = city['name']!;
                      });
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF0047FF).withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_city,
                            color: isSelected ? const Color(0xFF0047FF) : Colors.grey[400],
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  city['name']!,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    fontSize: 15,
                                    color: isSelected ? const Color(0xFF0047FF) : Colors.black87,
                                  ),
                                ),
                                Text(
                                  city['region']!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: Color(0xFF0047FF), size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
    required String time,
    required bool isUnread,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnread ? const Color(0xFF0047FF).withOpacity(0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUnread ? const Color(0xFF0047FF).withOpacity(0.2) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    if (isUnread)
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0047FF),
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- FILTER STATE ---
  String? _selectedFilterCategory;
  String? _selectedFilterDistance;
  String? _selectedFilterPrice;
  double _selectedFilterRating = 0;

  // --- SHOW FILTER BOTTOM SHEET ---
  void _showFilterBottomSheet() {
    // Reset temporary filter values
    String? tempCategory = _selectedFilterCategory;
    String? tempDistance = _selectedFilterDistance;
    String? tempPrice = _selectedFilterPrice;
    double tempRating = _selectedFilterRating;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Pencarian",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            tempCategory = null;
                            tempDistance = null;
                            tempPrice = null;
                            tempRating = 0;
                          });
                        },
                        child: const Text(
                          "Reset",
                          style: TextStyle(color: Color(0xFF0047FF)),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Kategori Olahraga
                        const Text(
                          "Kategori Olahraga",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip("Semua", tempCategory == null, () {
                              setModalState(() => tempCategory = null);
                            }),
                            ..._fieldTypes.take(6).map((type) => _buildFilterChip(
                              type.label,
                              tempCategory == type.value,
                              () => setModalState(() => tempCategory = type.value),
                            )),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Jarak
                        const Text(
                          "Jarak Maksimal",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip("Semua", tempDistance == null, () {
                              setModalState(() => tempDistance = null);
                            }),
                            _buildFilterChip("< 1 km", tempDistance == "1", () {
                              setModalState(() => tempDistance = "1");
                            }),
                            _buildFilterChip("< 5 km", tempDistance == "5", () {
                              setModalState(() => tempDistance = "5");
                            }),
                            _buildFilterChip("< 10 km", tempDistance == "10", () {
                              setModalState(() => tempDistance = "10");
                            }),
                            _buildFilterChip("< 20 km", tempDistance == "20", () {
                              setModalState(() => tempDistance = "20");
                            }),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Range Harga
                        const Text(
                          "Range Harga per Jam",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFilterChip("Semua", tempPrice == null, () {
                              setModalState(() => tempPrice = null);
                            }),
                            _buildFilterChip("< Rp 50rb", tempPrice == "50000", () {
                              setModalState(() => tempPrice = "50000");
                            }),
                            _buildFilterChip("Rp 50-100rb", tempPrice == "100000", () {
                              setModalState(() => tempPrice = "100000");
                            }),
                            _buildFilterChip("Rp 100-150rb", tempPrice == "150000", () {
                              setModalState(() => tempPrice = "150000");
                            }),
                            _buildFilterChip("> Rp 150rb", tempPrice == "999999", () {
                              setModalState(() => tempPrice = "999999");
                            }),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Rating Minimum
                        const Text(
                          "Rating Minimum",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            ...List.generate(5, (index) {
                              return GestureDetector(
                                onTap: () {
                                  setModalState(() {
                                    if (tempRating == index + 1) {
                                      tempRating = 0;
                                    } else {
                                      tempRating = (index + 1).toDouble();
                                    }
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Icon(
                                    index < tempRating ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 32,
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(width: 8),
                            Text(
                              tempRating > 0 ? "${tempRating.toInt()}+" : "Semua",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Fasilitas
                        const Text(
                          "Fasilitas",
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _buildFacilityChip(Icons.local_parking, "Parkir"),
                            _buildFacilityChip(Icons.wifi, "WiFi"),
                            _buildFacilityChip(Icons.wc, "Toilet"),
                            _buildFacilityChip(Icons.restaurant, "Kantin"),
                            _buildFacilityChip(Icons.shower, "Shower"),
                            _buildFacilityChip(Icons.checkroom, "Loker"),
                          ],
                        ),

                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Apply Button
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          // Save filter values
                          setState(() {
                            _selectedFilterCategory = tempCategory;
                            _selectedFilterDistance = tempDistance;
                            _selectedFilterPrice = tempPrice;
                            _selectedFilterRating = tempRating;
                          });
                          Navigator.pop(context);

                          // Navigate to category page with filters
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CategoryVenuesPage(
                                categoryName: tempCategory != null
                                    ? _fieldTypes.firstWhere((t) => t.value == tempCategory, orElse: () => _fieldTypes.first).label
                                    : 'Semua',
                                categoryIcon: Icons.filter_list,
                                categoryColor: const Color(0xFF0047FF),
                                showAllVenues: tempCategory == null,
                                fieldType: tempCategory,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0047FF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Terapkan Filter",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0047FF) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF0047FF) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildFacilityChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: const Color(0xFF0047FF),
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER SECTION ---
              SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location and notification row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Location
                        InkWell(
                          onTap: () => _showLocationPicker(),
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lokasi",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.location_on, color: Color(0xFF0047FF), size: 18),
                                  const SizedBox(width: 4),
                                  _isLoadingLocation
                                    ? const SizedBox(
                                        width: 14, height: 14,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0047FF))
                                      )
                                    : Text(
                                        _currentAddress,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_arrow_down, size: 18, color: Colors.black54),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Notification
                        GestureDetector(
                          onTap: () => _showNotifications(),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0047FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Stack(
                              children: [
                                const Icon(Icons.notifications_none_rounded, color: Color(0xFF0047FF), size: 24),
                                // Notification badge
                                Positioned(
                                  right: 0,
                                  top: 0,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Search bar - Simple clean design
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SearchPage(keyword: "")),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: Colors.grey[400], size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Cari lapangan olahraga...",
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // --- INFO & PROMO SECTION (PROMO CAROUSEL) ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.local_offer, color: Colors.orange.shade600, size: 18),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "Info & Promo",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            // Navigate to all promos page
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AllPromosPage(),
                              ),
                            );
                          },
                          child: const Text(
                            "Lihat Semua",
                            style: TextStyle(
                              color: Color(0xFF0047FF),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),

            // Promo Carousel
            SizedBox(
              height: 180,
              child: PageView.builder(
                controller: _promoPageController,
                onPageChanged: (index) {
                  setState(() => _currentPromoPage = index);
                },
                itemCount: 3,
                itemBuilder: (context, index) {
                  return _buildPromoCard(index);
                },
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    width: _currentPromoPage == index ? 8 : 6,
                    height: _currentPromoPage == index ? 8 : 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentPromoPage == index
                          ? const Color(0xFF0047FF)
                          : Colors.grey[300],
                    ),
                  );
                }),
              ),
            ),

            // Divider after promo
            _buildSectionDivider(),

            // --- LOYALTY PROGRAM ENTRY POINT ---
            _buildLoyaltyEntryPoint(),

            // Divider after loyalty
            _buildSectionDivider(),

            // --- 2. MAIN CONTENT AREA ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- SERVICES/KATEGORI SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Kategori",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AllCategoriesPage()),
                          );
                        },
                        child: const Text(
                          "Lihat Semua",
                          style: TextStyle(
                            color: Color(0xFF0047FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Circular category icons (horizontal scroll) - Dynamic from API
                  _isLoadingFieldTypes
                    ? const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0047FF),
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _fieldTypes.take(5).map((type) {
                            return _buildServiceIconFromType(context, type);
                          }).toList(),
                        ),
                      ),

                ],
              ),
            ),

            // Divider after kategori
            _buildSectionDivider(),

            // --- ARENA TERDEKAT SECTION ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Arena Terdekat",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CategoryVenuesPage(
                                categoryName: 'Semua',
                                categoryIcon: Icons.near_me,
                                categoryColor: Color(0xFF0047FF),
                                showAllVenues: true,
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          "Lihat Semua",
                          style: TextStyle(
                            color: Color(0xFF0047FF),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Grid 2 columns for venues
                  (_isLoadingLocation || _isLoadingVenues)
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(color: Color(0xFF0047FF)),
                        ),
                      )
                    : _apiVenues.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(Icons.sports_outlined, size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada venue tersedia',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.9,
                          ),
                          itemCount: _apiVenues.length > 4 ? 4 : _apiVenues.length,
                          itemBuilder: (context, index) {
                            return _buildTopRatedCard(_apiVenues[index]);
                          },
                        ),

                  const SizedBox(height: 16),
                ],
              ),
            ),

            // --- FAVORITES SECTION ---
            if (_favoriteService.favorites.isNotEmpty) ...[
              // Divider before favorites
              _buildSectionDivider(),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.favorite, color: Colors.red, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Favorit Saya",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${_favoriteService.favorites.length} venue",
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...(_favoriteService.favorites.map((venue) =>
                      FavoriteVenueCard(
                        venue: venue,
                        onRemove: () {
                          _favoriteService.removeFavorite(venue.id);
                        },
                      )
                    ).toList()),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
          ],
        ),
        ),
      ),
    );
  }

  // --- PROMO DATA ---
  static final List<Map<String, dynamic>> _promoData = [
    {
      'id': '1',
      'badge': 'Waktu Terbatas!',
      'title': 'Diskon Spesial',
      'discount': '30',
      'subtitle': 'Semua lapangan | S&K Berlaku',
      'description': 'Dapatkan diskon hingga 30% untuk semua lapangan olahraga. Promo berlaku untuk booking di hari kerja (Senin-Jumat) jam 08:00-15:00.',
      'validUntil': '31 Jan 2026',
      'code': 'SPORTA30',
      'type': 'discount',
      'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=600',
    },
    {
      'id': '2',
      'badge': 'Member Baru',
      'title': 'Gratis Booking',
      'discount': '1x',
      'subtitle': 'Booking pertama gratis | S&K Berlaku',
      'description': 'Khusus member baru! Nikmati gratis 1x booking untuk pengalaman pertamamu di Sporta. Daftar sekarang dan langsung main!',
      'validUntil': '28 Feb 2026',
      'code': 'NEWMEMBER',
      'type': 'freebie',
      'image': 'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=600',
    },
    {
      'id': '3',
      'badge': 'Weekend Deal',
      'title': 'Cashback',
      'discount': '20',
      'subtitle': 'Sabtu & Minggu | S&K Berlaku',
      'description': 'Main di weekend lebih hemat! Dapatkan cashback 20% untuk setiap booking di hari Sabtu dan Minggu. Cashback masuk ke Sporta Points.',
      'validUntil': '15 Jan 2026',
      'code': 'WEEKEND20',
      'type': 'cashback',
      'image': 'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=600',
    },
  ];

  // --- HELPER: PROMO CARD ---
  Widget _buildPromoCard(int index) {
    final promo = _promoData[index];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromoDetailPage(
              title: promo['title']!,
              subtitle: promo['subtitle']!,
              color: const Color(0xFF0047FF),
              promoData: promo,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          image: DecorationImage(
            image: NetworkImage(promo['image']!),
            fit: BoxFit.cover,
            opacity: 0.4,
          ),
        ),
        child: Stack(
          children: [
            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      promo['badge']!,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Text(
                    promo['title']!,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Discount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        "Hingga ",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        promo['discount']!,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                      Text(
                        promo['type'] == 'freebie' ? "" : "%",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0047FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Subtitle
                  Text(
                    promo['subtitle']!,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Claim button
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0047FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Lihat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, color: Colors.white, size: 14),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: CALCULATE DISTANCE ---
  double _calculateDistance(model.Venue venue) {
    if (_currentPosition == null || venue.latitude == null || venue.longitude == null) {
      return -1; // Return -1 if can't calculate
    }
    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      venue.latitude!,
      venue.longitude!,
    );
    return distance / 1000; // Convert to km
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm < 0) return '';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  // --- HELPER: SERVICE ICON FROM FIELD TYPE ---
  Widget _buildServiceIconFromType(BuildContext context, FieldType type) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryVenuesPage(
              categoryName: type.label,
              categoryIcon: type.icon,
              categoryColor: type.color,
              fieldType: type.value,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF0047FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(type.icon, color: const Color(0xFF0047FF), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              type.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: SERVICE ICON (Legacy) ---
  Widget _buildServiceIcon(BuildContext context, String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryVenuesPage(
              categoryName: title,
              categoryIcon: icon,
              categoryColor: color,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                color: const Color(0xFF0047FF).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF0047FF), size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: SECTION DIVIDER ---
  Widget _buildSectionDivider() {
    return Container(
      width: double.infinity,
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey.shade100,
    );
  }

  // --- HELPER: LOYALTY ENTRY POINT ---
  Widget _buildLoyaltyEntryPoint() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LoyaltyPage()),
          );
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0047FF), Color(0xFF00C6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0047FF).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Left side - Icon with animation feel
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      color: Colors.white,
                      size: 32,
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Text(
                          "!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              // Middle - Text content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: Colors.amber, size: 18),
                        const SizedBox(width: 6),
                        const Text(
                          "Sporta Rewards",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Main Penalty Kick & menangkan hadiah menarik!",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side - Arrow
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER: TOP RATED CARD (GRID ITEM) ---
  Widget _buildTopRatedCard(model.Venue venue) {
    final isFavorite = _favoriteService.isFavorite(venue.id.toString());
    final distance = _calculateDistance(venue);
    final distanceText = _formatDistance(distance);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(
              venueId: venue.id,
              venueName: venue.name,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0047FF).withValues(alpha: 0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      image: venue.coverImageUrl != null && venue.coverImageUrl!.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(venue.coverImageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: venue.coverImageUrl == null || venue.coverImageUrl!.isEmpty
                        ? const Center(
                            child: Icon(Icons.sports, color: Color(0xFF0047FF), size: 40),
                          )
                        : null,
                  ),
                  // Favorite button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        if (isFavorite) {
                          _favoriteService.removeFavorite(venue.id.toString());
                        } else {
                          _favoriteService.addFavorite(FavoriteVenue(
                            id: venue.id.toString(),
                            name: venue.name,
                            address: '${venue.address}, ${venue.city}',
                            rating: 4.5,
                            category: 'Olahraga',
                            pricePerHour: 0,
                          ));
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                  // Rating badge
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          const Text(
                            "4.8",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            venue.city,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Distance badge
                        if (distanceText.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0047FF).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              distanceText,
                              style: const TextStyle(
                                color: Color(0xFF0047FF),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: CATEGORY CIRCLE ---
  Widget _buildCategoryCircle(
    BuildContext context,
    String title,
    IconData icon,
    Color color, {
    String? imageUrl,
    bool isNearby = false,
  }) {
    return GestureDetector(
      onTap: () {
        if (isNearby) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CategoryVenuesPage(
                categoryName: 'Semua',
                categoryIcon: Icons.location_on,
                categoryColor: Color(0xFF0047FF),
                showAllVenues: true,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CategoryVenuesPage(
                categoryName: title,
                categoryIcon: icon,
                categoryColor: color,
              ),
            ),
          );
        }
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              height: 70,
              width: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isNearby ? color : null,
                border: Border.all(
                  color: isNearby ? color : Colors.grey.shade200,
                  width: 2,
                ),
                image: !isNearby && imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isNearby
                  ? Icon(icon, color: Colors.white, size: 30)
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- HELPER: HORIZONTAL VENUE CARD (LIKE HOTEL CARD) ---
  Widget _buildHorizontalVenueCard(Map<String, dynamic> venue) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(
              venueId: venue['id'],
              venueName: venue['name'],
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                color: venue['imageColor'] ?? Colors.blueAccent,
                image: venue['coverImageUrl'] != null && venue['coverImageUrl'].toString().isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(venue['coverImageUrl']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (venue['coverImageUrl'] == null || venue['coverImageUrl'].toString().isEmpty)
                    const Center(
                      child: Icon(Icons.sports, color: Colors.white54, size: 40),
                    ),
                  // Price badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        venue['distanceText'] ?? '-- km',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          venue['name'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 2),
                          Text(
                            venue['rating']?.toString() ?? '4.5',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue['location'] ?? '',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Facilities row
                  Row(
                    children: [
                      _buildFacilityIcon(Icons.local_parking, 'Parkir'),
                      const SizedBox(width: 8),
                      _buildFacilityIcon(Icons.wifi, 'WiFi'),
                      const SizedBox(width: 8),
                      _buildFacilityIcon(Icons.wc, 'Toilet'),
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

  // --- HELPER: FACILITY ICON ---
  Widget _buildFacilityIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 14, color: Colors.grey[600]),
      ),
    );
  }

  // --- HELPER: POPULAR VENUE CARD (HORIZONTAL LIST ITEM) ---
  Widget _buildPopularVenueCard(model.Venue venue) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(
              venueId: venue.id,
              venueName: venue.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF0047FF).withOpacity(0.1),
                image: venue.coverImageUrl != null && venue.coverImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(venue.coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: venue.coverImageUrl == null || venue.coverImageUrl!.isEmpty
                  ? const Icon(Icons.sports, color: Color(0xFF0047FF), size: 30)
                  : null,
            ),
            const SizedBox(width: 14),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${venue.address}, ${venue.city}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              '4.5',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (venue.facilities.isNotEmpty)
                        ...venue.facilities.take(2).map((f) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0047FF).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              f,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF0047FF),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        )),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --- HELPER: BANNER PROMO (CLICKABLE) ---
  Widget _buildPromoBanner(Color color, String title, String subtitle) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromoDetailPage(
              title: title,
              subtitle: subtitle,
              color: color,
            ),
          ),
        );
      },
      child: Hero(
        tag: title,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text("PROMO SPESIAL", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              // Material dipakai agar teks tidak error saat animasi Hero
              Material(
                color: Colors.transparent,
                child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              ),
              Material(
                color: Colors.transparent,
                child: Text(subtitle, style: const TextStyle(color: Colors.white, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// WIDGET KECIL (COMPONENT UI)
// ==========================================

class CategoryItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const CategoryItem({
    super.key, 
    required this.title, 
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman venue berdasarkan kategori
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryVenuesPage(
              categoryName: title,
              categoryIcon: icon,
              categoryColor: color,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, color: const Color(0xFF0047FF), size: 30),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              style: const TextStyle(
                fontSize: 12, 
                fontWeight: FontWeight.w500, 
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VenueCard extends StatelessWidget {
  final int venueId;
  final String name;
  final String location;
  final String price;
  final String rating;
  final Color imageColor;

  const VenueCard({
    super.key,
    required this.venueId,
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(
              venueId: venueId,
              venueName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: imageColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Stack(
                children: [
                  const Center(child: Icon(Icons.image, color: Colors.white54, size: 50)),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 14),
                          const SizedBox(width: 4),
                          Text(rating, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(location, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(text: price, style: const TextStyle(color: Color(0xFF0047FF), fontWeight: FontWeight.bold, fontSize: 16)),
                            TextSpan(text: " / jam", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0047FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text("Book", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// NEARBY VENUE CARD (DENGAN JARAK)
// ==========================================

class NearbyVenueCard extends StatelessWidget {
  final int venueId;
  final String name;
  final String location;
  final String price;
  final String rating;
  final Color imageColor;
  final String distance;
  final String category;
  final List<String> facilities;
  final String? coverImageUrl;

  const NearbyVenueCard({
    super.key,
    required this.venueId,
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageColor,
    required this.distance,
    required this.category,
    required this.facilities,
    this.coverImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(
              venueId: venueId,
              venueName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: imageColor.withOpacity(0.8),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: coverImageUrl != null && coverImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(coverImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: Stack(
                children: [
                  if (coverImageUrl == null || coverImageUrl!.isEmpty)
                    const Center(child: Icon(Icons.sports, color: Colors.white54, size: 40)),
                  
                  // Distance badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0047FF),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, color: Colors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            distance,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Rating badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Category badge
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: imageColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Facilities
                  Wrap(
                    spacing: 6,
                    children: facilities.take(3).map((facility) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0047FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          facility,
                          style: const TextStyle(
                            color: Color(0xFF0047FF),
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: price,
                              style: const TextStyle(
                                color: Color(0xFF0047FF),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            TextSpan(
                              text: " / jam",
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0047FF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          "Book",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
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
// ==========================================
// LOYALTY CARD WIDGET
// ==========================================

class LoyaltyCard extends StatelessWidget {
  const LoyaltyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const LoyaltyPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200), // Border halus
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Icon Mahkota/Bintang
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF9C4), // Kuning muda banget
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.stars_rounded, color: Colors.orange, size: 24),
            ),
            
            const SizedBox(width: 12),
            
            // Info Poin
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Sporta Points", 
                    style: TextStyle(
                      fontSize: 10, 
                      color: Colors.grey, 
                      fontWeight: FontWeight.bold
                    )
                  ),
                  Text(
                    "150 Poin", 
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.w900, 
                      color: Colors.black87
                    )
                  ),
                ],
              ),
            ),
            
            // Badge Level Member
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0047FF).withOpacity(0.1), // Biru transparan
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Silver", 
                style: TextStyle(
                  color: Color(0xFF0047FF), 
                  fontWeight: FontWeight.bold, 
                  fontSize: 12
                )
              ),
            ),
            
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// FAVORITE VENUE CARD WIDGET
// ==========================================

class FavoriteVenueCard extends StatelessWidget {
  final FavoriteVenue venue;
  final VoidCallback onRemove;

  const FavoriteVenueCard({
    super.key,
    required this.venue,
    required this.onRemove,
  });

  String _formatPrice(int price) {
    return "Rp ${price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";
  }

  @override
  Widget build(BuildContext context) {
    // Parse venue id from String to int (FavoriteVenue uses String id)
    final int? venueIdInt = int.tryParse(venue.id);

    return GestureDetector(
      onTap: () {
        if (venueIdInt != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VenueDetailPage(
                venueId: venueIdInt,
                venueName: venue.name,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image placeholder
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.sports,
                color: Colors.red.shade200,
                size: 30,
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.address,
                          style: TextStyle(color: Colors.grey[600], fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 10),
                            const SizedBox(width: 2),
                            Text(
                              venue.rating.toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0047FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          venue.category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0047FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove button
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text(
                      "Hapus dari Favorit?",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    content: Text(
                      "Hapus ${venue.name} dari daftar favorit?",
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          "Batal",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          onRemove();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Hapus",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              },
              icon: Icon(
                Icons.favorite,
                color: Colors.red.shade400,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// HOMEPAGE WITH INITIAL TAB INDEX
// ==========================================
class HomePageWithTab extends StatefulWidget {
  final int initialIndex;

  const HomePageWithTab({super.key, this.initialIndex = 0});

  @override
  State<HomePageWithTab> createState() => _HomePageWithTabState();
}

class _HomePageWithTabState extends State<HomePageWithTab> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Daftar Halaman (Home, Discover, Transactions, Profile)
  static final List<Widget> _pages = <Widget>[
    const DashboardContent(),
    const DiscoverPage(),
    const TransactionsPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0047FF).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : inactiveIcon,
              color: isSelected ? const Color(0xFF0047FF) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF0047FF) : Colors.grey,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _pages[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.explore_rounded, Icons.explore_outlined, 'Discover'),
                _buildNavItem(2, Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Transaksi'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}