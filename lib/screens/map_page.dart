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

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  // Default center: Jakarta, used until venues/location load.
  static const LatLng _fallbackCenter = LatLng(-6.2088, 106.8456);

  List<model.Venue> _venues = [];
  model.Venue? _selected;
  bool _loading = true;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadVenues(), _loadLocation()]);
    if (mounted) {
      setState(() => _loading = false);
      _fitToContent();
    }
  }

  Future<void> _loadVenues() async {
    try {
      final result = await VenueService.getVenues();
      if (result.success && result.venues != null) {
        _venues = result.venues!
            .where((v) => v.latitude != null && v.longitude != null)
            .toList();
      }
    } catch (_) {}
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
                  MarkerLayer(markers: [
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
                  ]),
                MarkerLayer(markers: _venues.map(_buildMarker).toList()),
              ],
            ),

            // Top bar
            _topBar(),

            // Recenter button
            Positioned(
              right: 16,
              bottom: _selected != null ? 188 : 28,
              child: FloatingActionButton(
                heroTag: 'recenter',
                backgroundColor: context.c.raised,
                onPressed: _fitToContent,
                child: Icon(Icons.my_location_rounded,
                    color: context.c.accent),
              ),
            ),

            // Selected venue card
            if (_selected != null) _venueCard(_selected!),

            if (_loading)
              Center(
                child: CircularProgressIndicator(color: context.c.accent),
              ),
          ],
        ),
      ),
    );
  }

  Marker _buildMarker(model.Venue v) {
    final isSel = _selected?.id == v.id;
    return Marker(
      point: LatLng(v.latitude!, v.longitude!),
      width: 44,
      height: 44,
      alignment: Alignment.topCenter,
      child: GestureDetector(
        onTap: () {
          setState(() => _selected = v);
          _mapController.move(LatLng(v.latitude!, v.longitude!),
              _mapController.camera.zoom < 14 ? 14 : _mapController.camera.zoom);
        },
        child: Icon(
          Icons.location_on,
          size: isSel ? 44 : 36,
          color: context.c.accent,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 6)],
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _circleBtn(Icons.arrow_back_rounded, () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
      bottom: 28,
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
                        Icon(Icons.location_on_outlined,
                            size: 14, color: context.c.inkSoft),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            formatKota(v.city),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: context.c.inkSoft, fontSize: 12),
                          ),
                        ),
                        if (v.averageRating != null) ...[
                          Icon(Icons.star_rounded,
                              size: 15, color: context.c.accent),
                          const SizedBox(width: 2),
                          Text(
                            v.averageRating!.toStringAsFixed(1),
                            style: TextStyle(
                                color: context.c.ink,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded,
                  color: context.c.inkSoft),
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
      child: Icon(Icons.stadium_rounded,
          color: context.c.inkSoft, size: 26),
    );
  }
}
