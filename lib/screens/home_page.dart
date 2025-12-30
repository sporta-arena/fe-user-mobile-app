import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Untuk Koordinat GPS
import 'package:geocoding/geocoding.dart';   // Untuk Ubah Koordinat jadi Alamat
import 'search_page.dart';       // Import Halaman Pencarian
import 'promo_detail_page.dart'; // Import Halaman Detail Promo
import 'all_categories_page.dart'; // Import Halaman Semua Kategori
import 'category_venues_page.dart'; // Import Halaman Venue per Kategori
import 'loyalty_page.dart'; // Import Halaman Loyalty
import 'venue_detail_page.dart'; // Import Halaman Detail Venue
import 'my_booking_page.dart'; // Import Halaman My Booking
import 'profile_page.dart'; // Import Halaman Profile
import '../services/venue_service.dart';
import '../services/auth_service.dart';
import '../models/venue.dart' as model;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0; // State Menu Bawah

  // Daftar Halaman (Dashboard, Booking, Profile)
  static final List<Widget> _pages = <Widget>[
    const DashboardContent(), // Halaman Utama
    const MyBookingPage(), // Halaman My Booking
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.confirmation_number_rounded),
              label: 'My Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color(0xFF0047FF),
          unselectedItemColor: Colors.grey,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          showUnselectedLabels: true,
          onTap: _onItemTapped,
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

  // Data venue dari API (tidak pakai hardcode lagi)
  // Hardcoded dummy data sudah di-comment out - hanya ambil dari API

  // List venue terdekat (akan diupdate berdasarkan lokasi)
  List<Map<String, dynamic>> _nearbyVenues = [];

  @override
  void initState() {
    super.initState();
    _loadVenuesFromApi(); // Load venues dari API
    _getCurrentLocation(); // Otomatis cari lokasi saat dibuka
    // _setDefaultVenues(); // DISABLED - tidak pakai hardcode lagi
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
          _convertApiVenuesToNearby();
        }
        // Tidak ada fallback ke hardcode lagi
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

  // --- HITUNG JARAK DAN UPDATE NEARBY VENUES ---
  void _updateNearbyVenues() {
    if (_currentPosition == null) return;

    List<Map<String, dynamic>> venuesWithDistance = [];
    
    for (var venue in _allVenues) {
      double distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        venue['latitude'],
        venue['longitude'],
      );
      
      // Convert meter ke kilometer
      double distanceKm = distance / 1000;
      
      venue['distance'] = distanceKm;
      venue['distanceText'] = distanceKm < 1 
          ? '${(distance).round()} m'
          : '${distanceKm.toStringAsFixed(1)} km';
      
      venuesWithDistance.add(venue);
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
      _nearbyVenues = _allVenues.take(3).map((venue) {
        venue['distanceText'] = '-- km';
        return venue;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- 1. HEADER (LOKASI & NOTIF) ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: _getCurrentLocation, // Klik untuk refresh lokasi
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Lokasi Anda",
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Color(0xFF0047FF), size: 16),
                          const SizedBox(width: 4),
                          _isLoadingLocation 
                            ? const SizedBox(
                                width: 14, height: 14, 
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0047FF))
                              )
                            : Text(
                                _currentAddress,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade200),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.notifications_none_rounded, color: Colors.black),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- 2. GREETING TEXT ---
            const Text(
              "Mau olahraga apa\nhari ini?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            
            const SizedBox(height: 20),

            // --- 3. SEARCH BAR (NAVIGASI KE SEARCH PAGE) ---
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SearchPage(keyword: "")),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: const AbsorbPointer( // Mencegah keyboard muncul di sini
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Cari lapangan futsal, badminton...",
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.search, color: Color(0xFF0047FF)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // --- LOYALTY CARD ---
            const LoyaltyCard(),

            const SizedBox(height: 24),

            // --- 4. BANNER PROMO (NAVIGASI KE DETAIL PROMO) ---
            SizedBox(
              height: 140,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildPromoBanner(Colors.blue, "Diskon 50%", "Untuk Pengguna Baru"),
                  const SizedBox(width: 16),
                  _buildPromoBanner(Colors.orange, "Weekend Deal", "Hemat s.d Rp 50rb"),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 5. KATEGORI OLAHRAGA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Kategori", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AllCategoriesPage()),
                    );
                  },
                  child: const Text(
                    "Lihat Semua", 
                    style: TextStyle(color: Color(0xFF0047FF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  CategoryItem(title: "Futsal", icon: Icons.sports_soccer, color: Colors.green),
                  CategoryItem(title: "Badminton", icon: Icons.sports_tennis, color: Colors.blue),
                  CategoryItem(title: "Basket", icon: Icons.sports_basketball, color: Colors.orange),
                  CategoryItem(title: "Renang", icon: Icons.pool, color: Colors.cyan),
                  CategoryItem(title: "Gym", icon: Icons.fitness_center, color: Colors.red),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // --- 6. NEARBY ARENA ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Nearby Arena", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                GestureDetector(
                  onTap: () {
                    // Navigasi ke halaman semua venue terdekat
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Membuka semua venue terdekat...'),
                        backgroundColor: Color(0xFF0047FF),
                      ),
                    );
                  },
                  child: const Text(
                    "Lihat Semua", 
                    style: TextStyle(color: Color(0xFF0047FF), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Loading atau list venue terdekat
            (_isLoadingLocation || _isLoadingVenues)
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: Column(
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0047FF)),
                        SizedBox(height: 16),
                        Text('Memuat venue dari server...', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              : _nearbyVenues.isEmpty
                ? Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.sports_outlined, size: 40, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Belum ada venue tersedia',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Data diambil dari database',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: _nearbyVenues.map((venue) => 
                      NearbyVenueCard(
                        name: venue['name'],
                        location: venue['location'],
                        price: venue['price'],
                        rating: venue['rating'],
                        imageColor: venue['imageColor'],
                        distance: venue['distanceText'] ?? '-- km',
                        category: venue['category'],
                        facilities: List<String>.from(venue['facilities']),
                      )
                    ).toList(),
                  ),
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
  final String name;
  final String location;
  final String price;
  final String rating;
  final Color imageColor;

  const VenueCard({
    super.key,
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
          MaterialPageRoute(builder: (context) => const VenueDetailPage()),
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
  final String name;
  final String location;
  final String price;
  final String rating;
  final Color imageColor;
  final String distance;
  final String category;
  final List<String> facilities;

  const NearbyVenueCard({
    super.key,
    required this.name,
    required this.location,
    required this.price,
    required this.rating,
    required this.imageColor,
    required this.distance,
    required this.category,
    required this.facilities,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const VenueDetailPage()),
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
              ),
              child: Stack(
                children: [
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