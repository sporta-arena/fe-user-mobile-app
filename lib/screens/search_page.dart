import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import '../services/venue_service.dart';
import '../models/venue.dart';
import '../constants/colors.dart';
import 'venue_detail_page.dart';

class SearchPage extends StatefulWidget {
  final String keyword;

  const SearchPage({super.key, required this.keyword});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Venue> _venues = [];
  bool _isLoading = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.keyword;
    if (widget.keyword.isNotEmpty) {
      _searchVenues(widget.keyword);
    }
  }

  Future<void> _searchVenues(String query) async {
    if (query.isEmpty) {
      setState(() => _venues = []);
      return;
    }

    setState(() => _isLoading = true);

    final result = await VenueService.getVenues(search: query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _venues = result.venues ?? [];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _searchVenues,
            style: const TextStyle(color: AppColors.onDark),
            decoration: InputDecoration(
              hintText: "Cari venue...",
              hintStyle: const TextStyle(color: AppColors.onDarkMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search, color: AppColors.onDarkMuted),
                onPressed: () => _searchVenues(_searchController.text),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
          : _venues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: AppColors.onDarkMuted),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? "Ketik untuk mencari venue"
                            : "Tidak ada venue ditemukan",
                        style: const TextStyle(color: AppColors.onDarkMuted),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _venues.length,
                  itemBuilder: (context, index) {
                    return _buildVenueCard(_venues[index]);
                  },
                ),
    );
  }

  Widget _buildVenueCard(Venue venue) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailPage(venueId: venue.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            // Venue Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: venue.coverImageUrl != null
                  ? Image.network(
                      venue.coverImageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: AppColors.brandYellow.withValues(alpha: 0.15),
                        child: const Icon(Icons.sports, color: AppColors.brandYellow),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: AppColors.brandYellow.withValues(alpha: 0.15),
                      child: const Icon(Icons.sports, color: AppColors.brandYellow),
                    ),
            ),
            const SizedBox(width: 12),
            // Venue Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.onDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.onDarkMuted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.address,
                          style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (venue.averageRating != null) ...[
                        const Icon(Icons.star, size: 14, color: AppColors.brandYellow),
                        const SizedBox(width: 2),
                        Text(
                          venue.averageRating!.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onDark),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        venue.city,
                        style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.onDarkMuted),
          ],
        ),
      ),
    );
  }
}
