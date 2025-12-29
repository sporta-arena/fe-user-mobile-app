import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../constants/colors.dart';
import 'venue_detail_page.dart';

class CategoryVenuesPage extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  const CategoryVenuesPage({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  }) : super(key: key);

  @override
  State<CategoryVenuesPage> createState() => _CategoryVenuesPageState();
}

class _CategoryVenuesPageState extends State<CategoryVenuesPage> {
  String selectedFilter = 'Semua';
  String selectedSort = 'Terdekat';
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> filteredVenues = [];
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  // Data dummy venues berdasarkan kategori dengan koordinat GPS
  List<Map<String, dynamic>> get venues {
    switch (widget.categoryName.toLowerCase()) {
      case 'futsal':
        return [
          {
            'name': 'Futsal Arena Champions',
            'location': 'Kemang, Jakarta Selatan',
            'latitude': -6.2615,
            'longitude': 106.8106,
            'price': 150000,
            'priceText': 'Rp 150.000',
            'rating': '4.9',
            'reviews': 245,
            'facilities': ['Parkir', 'Kantin', 'AC', 'Shower'],
            'available': true,
          },
          {
            'name': 'Sporta Futsal Center',
            'location': 'Tebet, Jakarta Selatan',
            'latitude': -6.2297,
            'longitude': 106.8467,
            'price': 120000,
            'priceText': 'Rp 120.000',
            'rating': '4.7',
            'reviews': 189,
            'facilities': ['Parkir', 'Kantin', 'Shower'],
            'available': true,
          },
          {
            'name': 'Victory Futsal Court',
            'location': 'Pancoran, Jakarta Selatan',
            'latitude': -6.2441,
            'longitude': 106.8495,
            'price': 100000,
            'priceText': 'Rp 100.000',
            'rating': '4.5',
            'reviews': 156,
            'facilities': ['Parkir', 'Kantin'],
            'available': false,
          },
          {
            'name': 'Elite Futsal Arena',
            'location': 'Senayan, Jakarta Pusat',
            'latitude': -6.2088,
            'longitude': 106.8456,
            'price': 200000,
            'priceText': 'Rp 200.000',
            'rating': '4.8',
            'reviews': 320,
            'facilities': ['Parkir', 'AC', 'Shower', 'Kantin', 'Locker'],
            'available': true,
          },
          {
            'name': 'Budget Futsal Hall',
            'location': 'Cawang, Jakarta Timur',
            'latitude': -6.2424,
            'longitude': 106.8784,
            'price': 80000,
            'priceText': 'Rp 80.000',
            'rating': '4.2',
            'reviews': 98,
            'facilities': ['Parkir'],
            'available': true,
          },
        ];
      case 'badminton':
        return [
          {
            'name': 'GOR Bulutangkis Sejahtera',
            'location': 'Tebet, Jakarta Selatan',
            'latitude': -6.2297,
            'longitude': 106.8467,
            'price': 60000,
            'priceText': 'Rp 60.000',
            'rating': '4.8',
            'reviews': 312,
            'facilities': ['Parkir', 'AC', 'Shower', 'Kantin'],
            'available': true,
          },
          {
            'name': 'Badminton Hall Premium',
            'location': 'Kemang, Jakarta Selatan',
            'latitude': -6.2615,
            'longitude': 106.8106,
            'price': 80000,
            'priceText': 'Rp 80.000',
            'rating': '4.6',
            'reviews': 198,
            'facilities': ['Parkir', 'AC', 'Shower'],
            'available': true,
          },
          {
            'name': 'Shuttle Arena Pro',
            'location': 'Kuningan, Jakarta Selatan',
            'latitude': -6.2382,
            'longitude': 106.8306,
            'price': 100000,
            'priceText': 'Rp 100.000',
            'rating': '4.9',
            'reviews': 267,
            'facilities': ['Parkir', 'AC', 'Shower', 'Kantin', 'Locker'],
            'available': false,
          },
          {
            'name': 'Community Badminton',
            'location': 'Menteng, Jakarta Pusat',
            'latitude': -6.1944,
            'longitude': 106.8294,
            'price': 45000,
            'priceText': 'Rp 45.000',
            'rating': '4.3',
            'reviews': 145,
            'facilities': ['Parkir', 'Shower'],
            'available': true,
          },
        ];
      default:
        return [
          {
            'name': '${widget.categoryName} Arena Pro',
            'location': 'Jakarta Selatan',
            'latitude': -6.2297,
            'longitude': 106.8467,
            'price': 100000,
            'priceText': 'Rp 100.000',
            'rating': '4.7',
            'reviews': 150,
            'facilities': ['Parkir', 'Shower'],
            'available': true,
          },
          {
            'name': '${widget.categoryName} Center Elite',
            'location': 'Jakarta Pusat',
            'latitude': -6.1944,
            'longitude': 106.8294,
            'price': 150000,
            'priceText': 'Rp 150.000',
            'rating': '4.8',
            'reviews': 200,
            'facilities': ['Parkir', 'AC', 'Shower'],
            'available': true,
          },
        ];
    }
  }

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _setDefaultVenues();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- GPS LOCATION METHODS ---
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

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        
        // Update venues dengan jarak real
        _updateVenuesWithDistance();
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
        
        // Jika gagal dapat lokasi, set default distance
        _setDefaultVenues();
      }
      debugPrint("Error Lokasi: $e");
    }
  }

  // --- UPDATE VENUES DENGAN JARAK REAL ---
  void _updateVenuesWithDistance() {
    if (_currentPosition == null) return;

    List<Map<String, dynamic>> venuesWithDistance = [];
    
    for (var venue in venues) {
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
    
    // Apply filters and sort dengan data yang sudah ada jarak
    _applyFiltersAndSort();
  }

  // --- SET DEFAULT VENUES JIKA GPS GAGAL ---
  void _setDefaultVenues() {
    for (var venue in venues) {
      venue['distanceText'] = '-- km';
      venue['distance'] = 999.0; // Set jarak tinggi untuk default
    }
    _applyFiltersAndSort();
  }

  // Apply search, filter, and sort
  void _applyFiltersAndSort() {
    List<Map<String, dynamic>> result = List.from(venues);

    // Apply search filter
    if (searchQuery.isNotEmpty) {
      result = result.where((venue) {
        return venue['name'].toLowerCase().contains(searchQuery.toLowerCase()) ||
               venue['location'].toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Apply availability filter
    if (selectedFilter == 'Tersedia') {
      result = result.where((venue) => venue['available'] == true).toList();
    } else if (selectedFilter == 'Rating Tinggi') {
      result = result.where((venue) => double.parse(venue['rating']) >= 4.5).toList();
    } else if (selectedFilter == 'Harga Murah') {
      result = result.where((venue) => venue['price'] <= 100000).toList();
    }

    // Apply sorting
    switch (selectedSort) {
      case 'Terdekat':
        result.sort((a, b) {
          double distanceA = a['distance'] ?? 999.0;
          double distanceB = b['distance'] ?? 999.0;
          return distanceA.compareTo(distanceB);
        });
        break;
      case 'Rating Tertinggi':
        result.sort((a, b) => double.parse(b['rating']).compareTo(double.parse(a['rating'])));
        break;
      case 'Harga Terendah':
        result.sort((a, b) => a['price'].compareTo(b['price']));
        break;
      case 'Harga Tertinggi':
        result.sort((a, b) => b['price'].compareTo(a['price']));
        break;
    }

    setState(() {
      filteredVenues = result;
    });
  }

  void _onSearchChanged(String query) {
    setState(() {
      searchQuery = query;
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Lapangan ${widget.categoryName}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: VenueSearchDelegate(
                  venues: venues,
                  categoryName: widget.categoryName,
                  categoryIcon: widget.categoryIcon,
                  categoryColor: widget.categoryColor,
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Header dengan info kategori
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: widget.categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.categoryIcon,
                    size: 30,
                    color: widget.categoryColor,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.categoryName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${filteredVenues.length} venue tersedia',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Filter dan Sort
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: _buildFilterChip('Filter', Icons.filter_list, () {
                    _showFilterBottomSheet();
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildFilterChip('Urutkan', Icons.sort, () {
                    _showSortBottomSheet();
                  }),
                ),
              ],
            ),
          ),

          // List venues
          Expanded(
            child: filteredVenues.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada venue ditemukan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Coba ubah filter atau kata kunci pencarian',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filteredVenues.length,
                    itemBuilder: (context, index) {
                      final venue = filteredVenues[index];
                      return _buildVenueCard(venue);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVenueCard(Map<String, dynamic> venue) {
    return Container(
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
          // Image placeholder
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    widget.categoryIcon,
                    size: 60,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                // Status badge
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: venue['available'] ? Colors.green : Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      venue['available'] ? 'Tersedia' : 'Penuh',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
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
                        const Icon(Icons.star, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          venue['rating'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name and distance
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        venue['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Text(
                      venue['distanceText'] ?? '-- km',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Location
                Row(
                  children: [
                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      venue['location'],
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Facilities
                Wrap(
                  spacing: 8,
                  children: (venue['facilities'] as List<String>).take(3).map((facility) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        facility,
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Price and book button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: venue['priceText'],
                                style: TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              TextSpan(
                                text: ' / jam',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${venue['reviews']} ulasan',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: venue['available'] ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const VenueDetailPage()),
                        );
                      } : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: Text(
                        venue['available'] ? 'Book' : 'Penuh',
                        style: const TextStyle(
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
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Filter Venue',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildFilterOption('Semua', selectedFilter == 'Semua'),
              _buildFilterOption('Tersedia', selectedFilter == 'Tersedia'),
              _buildFilterOption('Rating Tinggi', selectedFilter == 'Rating Tinggi'),
              _buildFilterOption('Harga Murah', selectedFilter == 'Harga Murah'),
            ],
          ),
        );
      },
    );
  }

  void _showSortBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Urutkan Berdasarkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildSortOption('Terdekat', selectedSort == 'Terdekat'),
              _buildSortOption('Rating Tertinggi', selectedSort == 'Rating Tertinggi'),
              _buildSortOption('Harga Terendah', selectedSort == 'Harga Terendah'),
              _buildSortOption('Harga Tertinggi', selectedSort == 'Harga Tertinggi'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterOption(String title, bool isSelected) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primaryBlue) : null,
      onTap: () {
        setState(() {
          selectedFilter = title;
        });
        Navigator.pop(context);
        _applyFiltersAndSort(); // Apply filter immediately
      },
    );
  }

  Widget _buildSortOption(String title, bool isSelected) {
    return ListTile(
      title: Text(title),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primaryBlue) : null,
      onTap: () {
        setState(() {
          selectedSort = title;
        });
        Navigator.pop(context);
        _applyFiltersAndSort(); // Apply sort immediately
      },
    );
  }
}

// ==========================================
// SEARCH DELEGATE FOR VENUE SEARCH
// ==========================================

class VenueSearchDelegate extends SearchDelegate<String> {
  final List<Map<String, dynamic>> venues;
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;

  VenueSearchDelegate({
    required this.venues,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
  });

  @override
  String get searchFieldLabel => 'Cari venue ${categoryName.toLowerCase()}...';

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredVenues = venues.where((venue) {
      return venue['name'].toLowerCase().contains(query.toLowerCase()) ||
             venue['location'].toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (query.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Cari venue ${categoryName.toLowerCase()}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketik nama venue atau lokasi',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    if (filteredVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada hasil untuk "$query"',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Coba kata kunci lain',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredVenues.length,
      itemBuilder: (context, index) {
        final venue = filteredVenues[index];
        return _buildSearchResultCard(context, venue);
      },
    );
  }

  Widget _buildSearchResultCard(BuildContext context, Map<String, dynamic> venue) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            categoryIcon,
            color: categoryColor,
            size: 24,
          ),
        ),
        title: Text(
          venue['name'],
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    venue['location'],
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ),
                Text(
                  venue['distanceText'] ?? '-- km',
                  style: const TextStyle(
                    color: Color(0xFF0047FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 14),
                const SizedBox(width: 4),
                Text(
                  venue['rating'],
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 16),
                Text(
                  venue['priceText'],
                  style: const TextStyle(
                    color: Color(0xFF0047FF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: venue['available'] ? Colors.green : Colors.red,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            venue['available'] ? 'Tersedia' : 'Penuh',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        onTap: () {
          // Handle venue selection
          close(context, venue['name']);
        },
      ),
    );
  }
}