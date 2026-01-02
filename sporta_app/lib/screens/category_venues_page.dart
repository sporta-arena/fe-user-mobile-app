import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/colors.dart';
import '../services/venue_service.dart';
import '../models/venue.dart' as model;
import '../models/field.dart';
import 'venue_detail_page.dart';

class CategoryVenuesPage extends StatefulWidget {
  final String categoryName;
  final IconData categoryIcon;
  final Color categoryColor;
  final bool showAllVenues;
  final String? fieldType;

  const CategoryVenuesPage({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    this.showAllVenues = false,
    this.fieldType,
  }) : super(key: key);

  @override
  State<CategoryVenuesPage> createState() => _CategoryVenuesPageState();
}

class _CategoryVenuesPageState extends State<CategoryVenuesPage> {
  // Filter state
  String selectedFilter = 'Semua';
  String selectedSort = 'nearest';
  RangeValues priceRange = const RangeValues(0, 500000);
  Set<String> selectedFacilities = {};
  Set<String> selectedCities = {};

  // Search
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';

  // View mode
  bool isGridView = false;

  // Data
  List<model.Venue> _apiVenues = [];
  List<model.Venue> _filteredVenues = [];
  bool _isLoading = true;
  String? _errorMessage;

  // Location
  Position? _currentPosition;
  bool _isLoadingLocation = false;

  // Available filters from data
  Set<String> _availableCities = {};
  Set<String> _availableFacilities = {};
  double _minPrice = 0;
  double _maxPrice = 500000;

  @override
  void initState() {
    super.initState();
    _loadVenuesFromApi();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVenuesFromApi() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await VenueService.getVenues();

      if (result.success && result.venues != null) {
        List<model.Venue> venues = result.venues!;

        // Fetch fields jika belum ada
        if (venues.isNotEmpty && venues.first.fields == null) {
          venues = await _loadVenuesWithFields(venues);
        }

        // Extract available filters
        _extractFiltersFromVenues(venues);

        setState(() {
          _apiVenues = venues;
          _isLoading = false;
        });
        _applyFiltersAndSort();
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.message ?? 'Gagal memuat data venue';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<List<model.Venue>> _loadVenuesWithFields(List<model.Venue> venues) async {
    List<model.Venue> venuesWithFields = [];

    for (var venue in venues) {
      try {
        final fieldsResult = await VenueService.getVenueFields(venue.id);
        if (fieldsResult.success && fieldsResult.fields != null) {
          venuesWithFields.add(model.Venue(
            id: venue.id,
            partnerId: venue.partnerId,
            name: venue.name,
            phone: venue.phone,
            address: venue.address,
            city: venue.city,
            description: venue.description,
            facilities: venue.facilities,
            openHour: venue.openHour,
            closeHour: venue.closeHour,
            latitude: venue.latitude,
            longitude: venue.longitude,
            coverImage: venue.coverImage,
            coverImageUrl: venue.coverImageUrl,
            status: venue.status,
            createdAt: venue.createdAt,
            updatedAt: venue.updatedAt,
            partner: venue.partner,
            fields: fieldsResult.fields,
            averageRating: venue.averageRating,
            reviewCount: venue.reviewCount,
          ));
        } else {
          venuesWithFields.add(venue);
        }
      } catch (e) {
        venuesWithFields.add(venue);
      }
    }

    return venuesWithFields;
  }

  void _extractFiltersFromVenues(List<model.Venue> venues) {
    Set<String> cities = {};
    Set<String> facilities = {};
    double minPrice = double.infinity;
    double maxPrice = 0;

    for (var venue in venues) {
      cities.add(venue.city);
      facilities.addAll(venue.facilities);

      if (venue.fields != null) {
        for (var field in venue.fields!) {
          if (field.pricePerHour < minPrice) minPrice = field.pricePerHour;
          if (field.pricePerHour > maxPrice) maxPrice = field.pricePerHour;
        }
      }
    }

    setState(() {
      _availableCities = cities;
      _availableFacilities = facilities;
      if (minPrice != double.infinity) {
        _minPrice = minPrice;
        _maxPrice = maxPrice;
        priceRange = RangeValues(_minPrice, _maxPrice);
      }
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw 'GPS mati';

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw 'Izin lokasi ditolak';
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Izin lokasi ditolak permanen';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _currentPosition = position;
          _isLoadingLocation = false;
        });
        _applyFiltersAndSort();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  double _calculateDistance(model.Venue venue) {
    if (_currentPosition == null || venue.latitude == null || venue.longitude == null) {
      return 999.0;
    }

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      venue.latitude!,
      venue.longitude!,
    );

    return distance / 1000;
  }

  String _formatDistance(double distanceKm) {
    if (distanceKm >= 999) return '';
    if (distanceKm < 1) return '${(distanceKm * 1000).round()} m';
    return '${distanceKm.toStringAsFixed(1)} km';
  }

  String _getCategoryType(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'futsal': return 'futsal';
      case 'badminton': return 'badminton';
      case 'basket':
      case 'basketball': return 'basketball';
      case 'voli':
      case 'volleyball': return 'volleyball';
      case 'tenis':
      case 'tennis': return 'tennis';
      case 'mini soccer':
      case 'mini_soccer': return 'mini_soccer';
      case 'padel': return 'padel';
      case 'renang':
      case 'swimming': return 'swimming';
      case 'golf': return 'golf';
      case 'billiard': return 'billiard';
      default: return categoryName.toLowerCase().replaceAll(' ', '_');
    }
  }

  double? _getLowestPrice(model.Venue venue) {
    if (venue.fields == null || venue.fields!.isEmpty) return null;
    double lowest = double.infinity;
    for (var field in venue.fields!) {
      if (field.pricePerHour < lowest) lowest = field.pricePerHour;
    }
    return lowest == double.infinity ? null : lowest;
  }

  void _applyFiltersAndSort() {
    List<model.Venue> result = List.from(_apiVenues);

    // Filter by category/field type
    if (!widget.showAllVenues) {
      String categoryType = widget.fieldType ?? _getCategoryType(widget.categoryName);
      result = result.where((venue) {
        if (venue.fields == null || venue.fields!.isEmpty) return false;
        return venue.fields!.any((field) =>
          field.type.toLowerCase() == categoryType.toLowerCase()
        );
      }).toList();
    }

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      result = result.where((venue) {
        return venue.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
               venue.address.toLowerCase().contains(searchQuery.toLowerCase()) ||
               venue.city.toLowerCase().contains(searchQuery.toLowerCase());
      }).toList();
    }

    // Filter by cities
    if (selectedCities.isNotEmpty) {
      result = result.where((venue) => selectedCities.contains(venue.city)).toList();
    }

    // Filter by facilities
    if (selectedFacilities.isNotEmpty) {
      result = result.where((venue) {
        return selectedFacilities.every((f) => venue.facilities.contains(f));
      }).toList();
    }

    // Filter by price range
    result = result.where((venue) {
      final price = _getLowestPrice(venue);
      if (price == null) return true;
      return price >= priceRange.start && price <= priceRange.end;
    }).toList();

    // Apply sorting
    switch (selectedSort) {
      case 'nearest':
        result.sort((a, b) => _calculateDistance(a).compareTo(_calculateDistance(b)));
        break;
      case 'price_low':
        result.sort((a, b) {
          final priceA = _getLowestPrice(a) ?? double.infinity;
          final priceB = _getLowestPrice(b) ?? double.infinity;
          return priceA.compareTo(priceB);
        });
        break;
      case 'price_high':
        result.sort((a, b) {
          final priceA = _getLowestPrice(a) ?? 0;
          final priceB = _getLowestPrice(b) ?? 0;
          return priceB.compareTo(priceA);
        });
        break;
      case 'rating':
        result.sort((a, b) {
          final ratingA = a.averageRating ?? 0;
          final ratingB = b.averageRating ?? 0;
          return ratingB.compareTo(ratingA);
        });
        break;
    }

    setState(() {
      _filteredVenues = result;
    });
  }

  void _resetFilters() {
    setState(() {
      selectedSort = 'nearest';
      priceRange = RangeValues(_minPrice, _maxPrice);
      selectedFacilities = {};
      selectedCities = {};
    });
    _applyFiltersAndSort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildFilterChips(),
            _buildResultCount(),
            Expanded(child: _buildVenueList()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black87),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.categoryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.categoryIcon, color: widget.categoryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.showAllVenues ? 'Semua Venue' : widget.categoryName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => searchQuery = value);
          _applyFiltersAndSort();
        },
        decoration: InputDecoration(
          hintText: 'Cari venue ${widget.categoryName.toLowerCase()}...',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400]),
          suffixIcon: GestureDetector(
            onTap: _showFilterBottomSheet,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 18),
            ),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['Semua', 'Terdekat', 'Rating Tinggi', 'Harga Murah'];

    return Container(
      height: 40,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilter == filter;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedFilter = filter;
                switch (filter) {
                  case 'Terdekat':
                    selectedSort = 'nearest';
                    break;
                  case 'Rating Tinggi':
                    selectedSort = 'rating';
                    break;
                  case 'Harga Murah':
                    selectedSort = 'price_low';
                    break;
                  default:
                    selectedSort = 'nearest';
                }
              });
              _applyFiltersAndSort();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[700],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildResultCount() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Ditemukan ${_filteredVenues.length} venue',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => isGridView = false),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: !isGridView ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.view_list_rounded,
                    size: 20,
                    color: !isGridView ? AppColors.primaryBlue : Colors.grey[400],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => setState(() => isGridView = true),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isGridView ? AppColors.primaryBlue.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.grid_view_rounded,
                    size: 20,
                    color: isGridView ? AppColors.primaryBlue : Colors.grey[400],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVenueList() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadVenuesFromApi,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      );
    }

    if (_filteredVenues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
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
              'Coba ubah filter atau kata kunci',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadVenuesFromApi,
      color: AppColors.primaryBlue,
      child: isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredVenues.length,
      itemBuilder: (context, index) {
        return _buildCompactVenueCard(_filteredVenues[index]);
      },
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemCount: _filteredVenues.length,
      itemBuilder: (context, index) {
        return _buildGridVenueCard(_filteredVenues[index]);
      },
    );
  }

  Widget _buildCompactVenueCard(model.Venue venue) {
    final distance = _calculateDistance(venue);
    final distanceText = _formatDistance(distance);
    final price = _getLowestPrice(venue);

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: 80,
                height: 80,
                color: widget.categoryColor.withOpacity(0.2),
                child: venue.coverImageUrl != null
                    ? Image.network(
                        venue.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(widget.categoryIcon, color: widget.categoryColor, size: 30),
                        ),
                      )
                    : Center(
                        child: Icon(widget.categoryIcon, color: widget.categoryColor, size: 30),
                      ),
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
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          venue.city,
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      if (venue.averageRating != null) ...[
                        Icon(Icons.star, size: 14, color: Colors.amber[600]),
                        const SizedBox(width: 2),
                        Text(
                          venue.averageRating!.toStringAsFixed(1),
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (venue.reviewCount != null && venue.reviewCount! > 0)
                          Text(
                            ' (${venue.reviewCount})',
                            style: TextStyle(color: Colors.grey[400], fontSize: 11),
                          ),
                        const SizedBox(width: 8),
                      ],
                      if (distanceText.isNotEmpty) ...[
                        Icon(Icons.near_me, size: 12, color: AppColors.primaryBlue),
                        const SizedBox(width: 2),
                        Text(
                          distanceText,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Price & Bookmark
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (price != null)
                  Text(
                    'Rp ${_formatPrice(price)}',
                    style: TextStyle(
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridVenueCard(model.Venue venue) {
    final price = _getLowestPrice(venue);
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Container(
                  width: double.infinity,
                  color: widget.categoryColor.withOpacity(0.2),
                  child: venue.coverImageUrl != null
                      ? Image.network(
                          venue.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(widget.categoryIcon, color: widget.categoryColor, size: 40),
                          ),
                        )
                      : Center(
                          child: Icon(widget.categoryIcon, color: widget.categoryColor, size: 40),
                        ),
                ),
              ),
            ),
            // Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      venue.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      venue.city,
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                      maxLines: 1,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (price != null)
                          Text(
                            'Rp ${_formatPrice(price)}',
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        if (distanceText.isNotEmpty)
                          Text(
                            distanceText,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
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

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _FilterBottomSheet(
        availableCities: _availableCities,
        availableFacilities: _availableFacilities,
        selectedCities: selectedCities,
        selectedFacilities: selectedFacilities,
        selectedSort: selectedSort,
        priceRange: priceRange,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        onApply: (cities, facilities, sort, prices) {
          setState(() {
            selectedCities = cities;
            selectedFacilities = facilities;
            selectedSort = sort;
            priceRange = prices;
          });
          _applyFiltersAndSort();
        },
        onReset: _resetFilters,
      ),
    );
  }
}

// ==========================================
// FILTER BOTTOM SHEET
// ==========================================

class _FilterBottomSheet extends StatefulWidget {
  final Set<String> availableCities;
  final Set<String> availableFacilities;
  final Set<String> selectedCities;
  final Set<String> selectedFacilities;
  final String selectedSort;
  final RangeValues priceRange;
  final double minPrice;
  final double maxPrice;
  final Function(Set<String>, Set<String>, String, RangeValues) onApply;
  final VoidCallback onReset;

  const _FilterBottomSheet({
    required this.availableCities,
    required this.availableFacilities,
    required this.selectedCities,
    required this.selectedFacilities,
    required this.selectedSort,
    required this.priceRange,
    required this.minPrice,
    required this.maxPrice,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late Set<String> _cities;
  late Set<String> _facilities;
  late String _sort;
  late RangeValues _prices;

  @override
  void initState() {
    super.initState();
    _cities = Set.from(widget.selectedCities);
    _facilities = Set.from(widget.selectedFacilities);
    _sort = widget.selectedSort;
    _prices = widget.priceRange;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Venue',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kota
                  if (widget.availableCities.isNotEmpty) ...[
                    _buildSectionTitle('Kota'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableCities.map((city) {
                        final isSelected = _cities.contains(city);
                        return _buildChip(
                          label: city.toUpperCase(),
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _cities.remove(city);
                              } else {
                                _cities.add(city);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Sort
                  _buildSectionTitle('Urutkan'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildChip(
                        label: 'Terdekat',
                        isSelected: _sort == 'nearest',
                        onTap: () => setState(() => _sort = 'nearest'),
                      ),
                      _buildChip(
                        label: 'Harga Terendah',
                        isSelected: _sort == 'price_low',
                        onTap: () => setState(() => _sort = 'price_low'),
                      ),
                      _buildChip(
                        label: 'Harga Tertinggi',
                        isSelected: _sort == 'price_high',
                        onTap: () => setState(() => _sort = 'price_high'),
                      ),
                      _buildChip(
                        label: 'Rating Tertinggi',
                        isSelected: _sort == 'rating',
                        onTap: () => setState(() => _sort = 'rating'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Price Range
                  _buildSectionTitle('Rentang Harga'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Rp ${_formatPriceK(_prices.start)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                      Text(
                        'Rp ${_formatPriceK(_prices.end)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                  RangeSlider(
                    values: _prices,
                    min: widget.minPrice,
                    max: widget.maxPrice,
                    divisions: 20,
                    activeColor: AppColors.primaryBlue,
                    inactiveColor: AppColors.primaryBlue.withOpacity(0.2),
                    onChanged: (values) {
                      setState(() => _prices = values);
                    },
                  ),
                  const SizedBox(height: 20),

                  // Facilities
                  if (widget.availableFacilities.isNotEmpty) ...[
                    _buildSectionTitle('Fasilitas'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.availableFacilities.map((facility) {
                        final isSelected = _facilities.contains(facility);
                        return _buildCheckChip(
                          label: _formatFacility(facility),
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _facilities.remove(facility);
                              } else {
                                _facilities.add(facility);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onReset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryBlue,
                      side: BorderSide(color: AppColors.primaryBlue),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply(_cities, _facilities, _sort, _prices);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Terapkan Filter'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildCheckChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatPriceK(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatFacility(String facility) {
    return facility
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}
