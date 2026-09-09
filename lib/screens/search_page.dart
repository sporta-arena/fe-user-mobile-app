import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../services/venue_service.dart';
import '../models/venue.dart';
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
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        backgroundColor: context.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: context.c.raised,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.c.line),
          ),
          child: TextField(
            controller: _searchController,
            onSubmitted: _searchVenues,
            style: TextStyle(color: context.c.ink),
            decoration: InputDecoration(
              hintText: "Cari venue...",
              hintStyle: TextStyle(color: context.c.inkSoft),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              suffixIcon: IconButton(
                icon: Icon(Icons.search, color: context.c.inkSoft),
                onPressed: () => _searchVenues(_searchController.text),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.c.accent))
          : _venues.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off, size: 64, color: context.c.inkSoft),
                      const SizedBox(height: 16),
                      Text(
                        _searchController.text.isEmpty
                            ? "Ketik untuk mencari venue"
                            : "Tidak ada venue ditemukan",
                        style: TextStyle(color: context.c.inkSoft),
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
          color: context.c.raised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.c.line),
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
                        color: context.c.accent.withValues(alpha: 0.15),
                        child: Icon(Icons.sports, color: context.c.accent),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: context.c.accent.withValues(alpha: 0.15),
                      child: Icon(Icons.sports, color: context.c.accent),
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
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: context.c.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 14, color: context.c.inkSoft),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.address,
                          style: TextStyle(color: context.c.inkSoft, fontSize: 12),
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
                        Icon(Icons.star, size: 14, color: context.c.accent),
                        const SizedBox(width: 2),
                        Text(
                          venue.averageRating!.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: context.c.ink),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        venue.city,
                        style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.c.inkSoft),
          ],
        ),
      ),
    );
  }
}
