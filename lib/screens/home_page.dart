import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart'; // Untuk Koordinat GPS
import 'package:geocoding/geocoding.dart';   // Untuk Ubah Koordinat jadi Alamat
import 'search_page.dart';       // Import Halaman Pencarian
import 'promo_detail_page.dart'; // Import Halaman Detail Promo
import 'all_categories_page.dart'; // Import Halaman Semua Kategori
import 'category_venues_page.dart'; // Import Halaman Venue per Kategori

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
    const Center(child: Text("Halaman Riwayat Booking (Coming Soon)")),
    const Center(child: Text("Halaman Profil User (Coming Soon)")),
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

  @override
  void initState() {
    super.initState();
    _getCurrentLocation(); // Otomatis cari lokasi saat dibuka
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
          _currentAddress = "${place.subLocality}, ${place.locality}"; 
          _isLoadingLocation = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Gagal memuat lokasi";
          _isLoadingLocation = false;
        });
      }
      debugPrint("Error Lokasi: $e");
    }
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

            // --- 6. REKOMENDASI VENUE ---
            const Text("Rekomendasi Arena", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),

            const VenueCard(
              name: "Gor Bulutangkis Sejahtera",
              location: "Tebet, Jakarta Selatan",
              price: "Rp 60.000",
              rating: "4.8",
              imageColor: Colors.blueAccent,
            ),
            const VenueCard(
              name: "Futsal Champions Arena",
              location: "Kemang, Jakarta Selatan",
              price: "Rp 150.000",
              rating: "4.9",
              imageColor: Colors.green,
            ),
            const VenueCard(
              name: "Basketball Hall A",
              location: "Senayan, Jakarta Pusat",
              price: "Rp 200.000",
              rating: "4.7",
              imageColor: Colors.orange,
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Buka Detail: $name")));
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