import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'search_page.dart';
import 'all_categories_page.dart';
import 'category_venues_page.dart';
import 'venue_detail_page.dart';
import 'notifications_page.dart';
import 'map_page.dart';
import 'discover_page.dart';
import 'transactions_page.dart';
import 'profile_page.dart';

import '../services/venue_service.dart';
import '../services/field_type_service.dart';
import '../models/venue.dart' as model;
import '../models/field_type.dart';
import '../constants/colors.dart';

class HomePage extends StatefulWidget {
  /// Tab to open initially (0=Home, 1=Discover, 2=Transaksi, 3=Profile).
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
    DiscoverPage(),
    TransactionsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
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
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.explore_rounded, Icons.explore_outlined, 'Discover'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Transaksi'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
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
                          color: sel ? AppColors.brandYellow : AppColors.onDarkMuted,
                          size: 24),
                      const SizedBox(height: 4),
                      Text(label,
                          style: TextStyle(
                            color: sel
                                ? AppColors.brandYellow
                                : AppColors.onDarkMuted,
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
  String _address = "Mencari lokasi…";
  List<model.Venue> _venues = [];
  List<FieldType> _fieldTypes = [];
  bool _loadingVenues = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
    _loadFieldTypes();
    _getLocation();
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
            color: AppColors.brandYellow,
            backgroundColor: AppColors.surface,
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
                _venueSection("Nearby from you", _venues),
                const SizedBox(height: 24),
                _venueSection("Popular", _venues.reversed.toList()),
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
              onTap: _getLocation,
              child: Row(
                children: [
                  const Icon(Icons.location_on_rounded,
                      color: AppColors.brandYellow, size: 20),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _address,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.onDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded,
                      color: AppColors.onDark, size: 22),
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
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.onDark, size: 22),
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
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: const Row(
            children: [
              Icon(Icons.search_rounded, color: AppColors.onDarkMuted, size: 22),
              SizedBox(width: 10),
              Text("Cari arena",
                  style: TextStyle(color: AppColors.onDarkMuted, fontSize: 15)),
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
                color: AppColors.brandYellow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.grid_view_rounded,
                  color: AppColors.ink, size: 20),
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
              categoryColor: type.color,
            ),
          ),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: [
              Icon(type.icon, color: AppColors.brandYellow, size: 18),
              const SizedBox(width: 8),
              Text(type.label,
                  style: const TextStyle(
                      color: AppColors.onDark,
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
                  style: const TextStyle(
                      color: AppColors.onDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w700)),
              GestureDetector(
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchPage(keyword: ""))),
                child: const Text("Lihat semua",
                    style: TextStyle(
                        color: AppColors.brandYellow,
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
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.brandYellow))
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
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text("Belum ada venue.",
            style: TextStyle(color: AppColors.onDarkMuted)),
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
          color: AppColors.brandYellow,
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_rounded, color: AppColors.ink, size: 20),
            SizedBox(width: 8),
            Text("Map",
                style: TextStyle(
                    color: AppColors.ink,
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
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: _image(),
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
                          style: const TextStyle(
                            color: AppColors.onDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.star_rounded,
                          color: AppColors.brandYellow, size: 16),
                      const SizedBox(width: 2),
                      Text(
                        rating != null ? rating.toStringAsFixed(1) : "Baru",
                        style: const TextStyle(
                          color: AppColors.onDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.onDarkMuted, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.onDarkMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _facilities(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _image() {
    final url = venue.coverImageUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        height: 120,
        width: 216,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      height: 120,
      width: 216,
      color: const Color(0xFF222226),
      child: const Icon(Icons.stadium_rounded,
          color: AppColors.onDarkMuted, size: 40),
    );
  }

  Widget _facilities() {
    final icons = venue.facilities.take(4).map(_facilityIcon).toList();
    if (icons.isEmpty) {
      return Text(
        "${venue.openHour} - ${venue.closeHour}",
        style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 11),
      );
    }
    return Row(
      children: [
        for (final ic in icons)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(ic, color: AppColors.onDarkMuted, size: 16),
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
