import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'booking_confirmation_page.dart';
import '../services/favorite_service.dart';
import '../services/venue_service.dart';
import '../models/venue.dart' as model;
import '../models/field.dart' as field_model;
import '../constants/colors.dart';

class VenueDetailPage extends StatefulWidget {
  final int venueId;
  final String? venueName;

  const VenueDetailPage({
    super.key,
    required this.venueId,
    this.venueName,
  });

  @override
  State<VenueDetailPage> createState() => _VenueDetailPageState();
}

class _VenueDetailPageState extends State<VenueDetailPage> {
  // --- STATE VARIABLES ---
  DateTime _selectedDate = DateTime.now();
  List<String> _selectedTimeSlots = [];
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isLoading = true;
  String? _errorMessage;

  // --- IMAGE CAROUSEL ---
  final PageController _imagePageController = PageController();
  List<String> _venueImages = [];

  // --- DATA FROM API ---
  model.Venue? _venue;
  List<field_model.Field> _fields = [];
  field_model.Field? _selectedField;
  List<field_model.TimeSlot> _availableSlots = [];
  bool _isLoadingSlots = false;

  // --- FAVORITE SERVICE ---
  final FavoriteService _favoriteService = FavoriteService();

  // --- LOCATION ---
  Position? _currentPosition;
  String _distanceText = '';

  @override
  void initState() {
    super.initState();
    _loadVenueDetail();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _calculateDistance();
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  void _calculateDistance() {
    if (_currentPosition == null || _venue == null) return;
    if (_venue!.latitude == null || _venue!.longitude == null) return;

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _venue!.latitude!,
      _venue!.longitude!,
    );

    setState(() {
      if (distance < 1000) {
        _distanceText = '${distance.round()} m dari lokasi Anda';
      } else {
        _distanceText = '${(distance / 1000).toStringAsFixed(1)} km dari lokasi Anda';
      }
    });
  }

  Future<void> _loadVenueDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final venueResult = await VenueService.getVenueDetail(widget.venueId);

      if (venueResult.success && venueResult.venue != null) {
        setState(() {
          _venue = venueResult.venue;
          _isFavorite = _favoriteService.isFavorite(_venue!.id.toString());

          // Setup images - use cover image + generate gallery placeholders
          _venueImages = [];
          if (_venue!.coverImageUrl != null) {
            _venueImages.add(_venue!.coverImageUrl!);
          }
          // Add placeholder images for demo (in production, these would come from API)
          // You can add more images from venue.galleryImages when available
        });
        _calculateDistance();

        final fieldsResult = await VenueService.getVenueFields(widget.venueId);
        if (fieldsResult.success && fieldsResult.fields != null) {
          setState(() {
            _fields = fieldsResult.fields!;
            if (_fields.isNotEmpty) {
              _selectedField = _fields.first;
            }
          });

          if (_selectedField != null) {
            _loadAvailableSlots();
          }
        }

        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = venueResult.message ?? 'Gagal memuat data venue';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _loadAvailableSlots() async {
    if (_selectedField == null) return;

    setState(() => _isLoadingSlots = true);

    final dateStr = _selectedDate.toString().split(' ')[0];
    final result = await VenueService.getAvailableSlots(_selectedField!.id, dateStr);

    if (mounted) {
      setState(() {
        _isLoadingSlots = false;
        if (result.success && result.slots != null) {
          _availableSlots = result.slots!;
        } else {
          _availableSlots = [];
        }
        _selectedTimeSlots = [];
      });
    }
  }

  void _toggleFavorite() {
    if (_venue == null) return;

    final venue = FavoriteVenue(
      id: _venue!.id.toString(),
      name: _venue!.name,
      address: _venue!.address,
      rating: 4.5,
      pricePerHour: _selectedField?.pricePerHour.toInt() ?? 0,
      category: _selectedField?.type ?? 'Sport',
    );

    _favoriteService.toggleFavorite(venue);
    setState(() {
      _isFavorite = !_isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isFavorite ? "Ditambahkan ke favorit" : "Dihapus dari favorit"
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: _isFavorite ? Colors.green : Colors.grey,
      ),
    );
  }

  // Open maps for navigation
  Future<void> _openMapsNavigation() async {
    if (_venue?.latitude == null || _venue?.longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lokasi venue tidak tersedia')),
      );
      return;
    }

    final lat = _venue!.latitude!;
    final lng = _venue!.longitude!;
    final label = Uri.encodeComponent(_venue!.name);

    // Try Google Maps first, then Apple Maps
    final googleMapsUrl = 'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&destination_place_id=$label';
    final appleMapsUrl = 'https://maps.apple.com/?daddr=$lat,$lng&dirflg=d';

    if (Platform.isIOS) {
      // On iOS, show choice
      _showMapChoiceDialog(googleMapsUrl, appleMapsUrl);
    } else {
      // On Android, use Google Maps
      if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
        await launchUrl(Uri.parse(googleMapsUrl), mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showMapChoiceDialog(String googleUrl, String appleUrl) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Buka dengan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(Icons.location_on, color: Colors.red[600], size: 28),
                      Positioned(
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              title: const Text('Google Maps'),
              subtitle: Text('Buka di aplikasi Google Maps', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () async {
                Navigator.pop(context);
                if (await canLaunchUrl(Uri.parse(googleUrl))) {
                  await launchUrl(Uri.parse(googleUrl), mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.green[400]!,
                      Colors.green[600]!,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.explore, color: Colors.white, size: 24),
                ),
              ),
              title: const Text('Apple Maps'),
              subtitle: Text('Buka di aplikasi Apple Maps', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
              onTap: () async {
                Navigator.pop(context);
                if (await canLaunchUrl(Uri.parse(appleUrl))) {
                  await launchUrl(Uri.parse(appleUrl), mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(widget.venueName ?? 'Detail Venue'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(_errorMessage!, style: TextStyle(color: Colors.grey[600])),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadVenueDetail,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: _buildBottomBar(),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildImageCarousel(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderInfo(),
                    const SizedBox(height: 24),
                    _buildDescriptionSection(),
                    const SizedBox(height: 24),
                    _buildLocationSection(),
                    const SizedBox(height: 24),
                    if (_venueImages.isNotEmpty) ...[
                      _buildGallerySection(),
                      const SizedBox(height: 24),
                    ],
                    const Divider(),
                    const SizedBox(height: 20),

                    if (_fields.length > 1) ...[
                      const Text("Pilih Lapangan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      _buildFieldSelector(),
                      const SizedBox(height: 24),
                    ],

                    const Text("Pilih Jadwal Main", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),

                    Text("Tanggal", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    _buildDatePicker(),
                    const SizedBox(height: 24),

                    Text("Jam Tersedia", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    _buildTimeSlotGrid(),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    final images = _venueImages.isNotEmpty
        ? _venueImages
        : [_venue?.coverImageUrl ?? ''];

    return SliverAppBar(
      expandedHeight: 280.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            // Image PageView
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => _currentImageIndex = index);
              },
              itemBuilder: (context, index) {
                final imageUrl = images[index];
                return imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: const Center(
                            child: Icon(Icons.image, size: 80, color: Colors.white54),
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.primaryBlue.withOpacity(0.3),
                        child: const Center(
                          child: Icon(Icons.image, size: 80, color: Colors.white54),
                        ),
                      );
              },
            ),
            // Image indicators
            if (images.length > 1)
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                    (index) => Container(
                      width: _currentImageIndex == index ? 24 : 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _currentImageIndex == index
                            ? AppColors.primaryBlue
                            : Colors.white.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            // Image counter
            Positioned(
              bottom: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${images.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _venue?.name ?? 'Venue',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on_outlined, color: Colors.grey[600], size: 16),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _venue?.address ?? '',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ],
        ),
        if (_distanceText.isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.near_me, color: AppColors.primaryBlue, size: 16),
              const SizedBox(width: 4),
              Text(
                _distanceText,
                style: const TextStyle(
                  color: AppColors.primaryBlue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(Icons.access_time, color: Colors.grey[600], size: 16),
            const SizedBox(width: 4),
            Text(
              _venue?.formattedOpenHours ?? '',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Tentang Arena", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 8),
        Text(
          _venue?.description ?? 'Tidak ada deskripsi',
          style: TextStyle(color: Colors.grey[700], height: 1.5),
        ),
        const SizedBox(height: 20),
        const Text("Fasilitas", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: (_venue?.facilities ?? []).map((facility) =>
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatFacility(facility),
                style: TextStyle(color: AppColors.primaryBlue, fontSize: 12, fontWeight: FontWeight.w500),
              ),
            )
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    final hasLocation = _venue?.latitude != null && _venue?.longitude != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Lokasi Venue", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            if (hasLocation)
              TextButton.icon(
                onPressed: _openMapsNavigation,
                icon: const Icon(Icons.directions, size: 18),
                label: const Text('Petunjuk Arah'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryBlue,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: hasLocation ? _openMapsNavigation : null,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Stack(
              children: [
                // Map placeholder with grid pattern
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: CustomPaint(
                      size: const Size(double.infinity, 180),
                      painter: _MapGridPainter(),
                    ),
                  ),
                ),
                // Center marker
                if (hasLocation)
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            _venue?.name ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.location_on,
                          color: AppColors.primaryBlue,
                          size: 40,
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                // Overlay button
                Positioned(
                  bottom: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Buka Maps',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Address overlay
                Positioned(
                  bottom: 12,
                  left: 12,
                  right: 100,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_venue?.address ?? ''}, ${_venue?.city ?? ''}',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 11,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGallerySection() {
    // For demo, we'll show the cover image and generate placeholders
    // In production, this would come from venue.galleryImages
    final images = _venueImages;
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Galeri Foto", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            TextButton(
              onPressed: () => _showFullGallery(),
              child: Text(
                'Lihat Semua',
                style: TextStyle(color: AppColors.primaryBlue),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: images.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showImageViewer(index),
                child: Container(
                  width: 120,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      images[index],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.image, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showFullGallery() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Galeri Foto',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _venueImages.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _showImageViewer(index);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        _venueImages[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.image, color: Colors.grey[400], size: 40),
                        ),
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

  void _showImageViewer(int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _ImageViewerPage(
          images: _venueImages,
          initialIndex: initialIndex,
          venueName: _venue?.name ?? 'Venue',
        ),
      ),
    );
  }

  Widget _buildFieldSelector() {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _fields.length,
        itemBuilder: (context, index) {
          final field = _fields[index];
          final isSelected = _selectedField?.id == field.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedField = field;
                _selectedTimeSlots = [];
              });
              _loadAvailableSlots();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
              ),
              child: Center(
                child: Text(
                  field.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDatePicker() {
    List<String> dayNames = ["Sen", "Sel", "Rab", "Kam", "Jum", "Sab", "Min"];

    return SizedBox(
      height: 85,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (context, index) {
          DateTime date = DateTime.now().add(Duration(days: index));
          bool isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedDate = date;
                _selectedTimeSlots = [];
              });
              _loadAvailableSlots();
            },
            child: Container(
              width: 70,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayNames[date.weekday - 1],
                    style: TextStyle(
                      fontSize: 14,
                      color: isSelected ? Colors.white : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSlotPassed(String slotTime) {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final selectedDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);

    if (selectedDate.isAfter(todayDate)) return false;
    if (selectedDate.isBefore(todayDate)) return true;

    try {
      final timeParts = slotTime.split(':');
      final slotHour = int.parse(timeParts[0]);
      final slotMinute = int.parse(timeParts[1]);
      final slotDateTime = DateTime(now.year, now.month, now.day, slotHour, slotMinute);
      return now.isAfter(slotDateTime);
    } catch (e) {
      return false;
    }
  }

  Widget _buildTimeSlotGrid() {
    if (_isLoadingSlots) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );
    }

    if (_availableSlots.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 12),
              Text(
                'Tidak ada slot tersedia',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedTimeSlots.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: AppColors.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dipilih: ${_selectedTimeSlots.length} jam (${_selectedTimeSlots.join(", ")})',
                    style: const TextStyle(
                      color: AppColors.primaryBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Text(
          'Pilih jam yang diinginkan (bisa pilih lebih dari 1)',
          style: TextStyle(color: Colors.grey[500], fontSize: 12),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _availableSlots.length,
          itemBuilder: (context, index) {
            final slot = _availableSlots[index];
            final slotTime = slot.startTime.substring(0, 5);
            bool isAvailable = slot.available && !_isSlotPassed(slotTime);
            bool isSelected = _selectedTimeSlots.contains(slotTime);
            bool isPassed = _isSlotPassed(slotTime);

            Color bgColor;
            Color textColor;
            Color borderColor;

            if (!isAvailable) {
              bgColor = Colors.grey[200]!;
              textColor = Colors.grey[400]!;
              borderColor = Colors.transparent;
            } else if (isSelected) {
              bgColor = AppColors.primaryBlue;
              textColor = Colors.white;
              borderColor = AppColors.primaryBlue;
            } else {
              bgColor = Colors.white;
              textColor = Colors.black87;
              borderColor = Colors.grey.shade300;
            }

            return GestureDetector(
              onTap: isAvailable ? () {
                setState(() {
                  if (_selectedTimeSlots.contains(slotTime)) {
                    _selectedTimeSlots.remove(slotTime);
                  } else {
                    _selectedTimeSlots.add(slotTime);
                    _selectedTimeSlots.sort();
                  }
                });
              } : null,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderColor),
                ),
                child: Text(
                  slotTime,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    decoration: (!slot.available || isPassed) ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final price = _selectedField?.pricePerHour.toInt() ?? 0;
    final totalPrice = price * _selectedTimeSlots.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedTimeSlots.isEmpty
                        ? "Total Harga"
                        : "Total (${_selectedTimeSlots.length} jam)",
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  Text(
                    _selectedTimeSlots.isEmpty
                        ? "Rp 0"
                        : "Rp ${_formatPrice(totalPrice.toDouble())}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedTimeSlots.isEmpty || _selectedField == null ? null : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingConfirmationPage(
                        fieldId: _selectedField!.id,
                        venueName: _venue?.name ?? '',
                        venueAddress: _venue?.address ?? '',
                        fieldName: _selectedField!.name,
                        selectedDate: _selectedDate.toString().split(' ')[0],
                        selectedTimeSlots: _selectedTimeSlots,
                        price: price,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  disabledBackgroundColor: Colors.grey[300],
                ),
                child: const Text(
                  "BOOKING SEKARANG",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  String _formatFacility(String facility) {
    return facility
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
        .join(' ');
  }
}

// Map Grid Painter for location placeholder
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..strokeWidth = 1;

    // Draw grid lines
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Full screen image viewer
class _ImageViewerPage extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String venueName;

  const _ImageViewerPage({
    required this.images,
    required this.initialIndex,
    required this.venueName,
  });

  @override
  State<_ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<_ImageViewerPage> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${_currentIndex + 1} / ${widget.images.length}',
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.images.length,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
        },
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Image.network(
                widget.images[index],
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.image,
                  color: Colors.white54,
                  size: 100,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
