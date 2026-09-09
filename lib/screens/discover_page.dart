import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'search_page.dart';
import 'venue_detail_page.dart';
import '../services/venue_service.dart';
import '../models/venue.dart' as model;
import '../constants/colors.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  List<model.Venue> _venues = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    try {
      final result = await VenueService.getVenues();
      if (result.success && result.venues != null) {
        setState(() {
          _venues = result.venues!;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _loadVenues,
        color: AppColors.brandYellow,
        backgroundColor: AppColors.surface,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              backgroundColor: AppColors.bg,
              elevation: 0,
              floating: true,
              systemOverlayStyle: gayaOverlay(context),
              title: const Text(
                'Discover',
                style: TextStyle(
                  color: AppColors.onDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Bar
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
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.search, color: AppColors.onDarkMuted),
                            SizedBox(width: 12),
                            Text(
                              "Cari venue, event, komunitas...",
                              style: TextStyle(color: AppColors.onDarkMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // === VENUE POPULER ===
                    _buildSectionHeader("Venue Populer", icon: Icons.trending_up, iconColor: Colors.red),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _venues.take(5).length,
                              itemBuilder: (context, index) {
                                return _buildVenueCard(_venues[index], "populer");
                              },
                            ),
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === EVENT & TURNAMEN ===
                    _buildSectionHeader("Event & Turnamen", icon: Icons.emoji_events, iconColor: Colors.amber),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 180,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildEventCard(
                            "Turnamen Futsal Antar Kampus",
                            "15-17 Jan 2026",
                            "GOR Sudirman",
                            Colors.green,
                            Icons.sports_soccer,
                          ),
                          _buildEventCard(
                            "Badminton Championship",
                            "22 Jan 2026",
                            "Arena Badminton Center",
                            Colors.blue,
                            Icons.sports_tennis,
                          ),
                          _buildEventCard(
                            "Basketball 3on3 Tournament",
                            "28 Jan 2026",
                            "Sportmall Kelapa Gading",
                            Colors.orange,
                            Icons.sports_basketball,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === TOP RATED ===
                    _buildSectionHeader("Top Rated", icon: Icons.star, iconColor: Colors.amber),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _venues.take(5).length,
                              itemBuilder: (context, index) {
                                return _buildVenueCard(_venues[index], "rating");
                              },
                            ),
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === CHALLENGE MINGGUAN ===
                    _buildSectionHeader("Challenge Mingguan", icon: Icons.flag, iconColor: Colors.purple),
                    const SizedBox(height: 14),
                    _buildChallengeCard(),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === ARTIKEL & TIPS ===
                    _buildSectionHeader("Artikel & Tips", icon: Icons.article, iconColor: Colors.teal),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 160,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildArticleCard(
                            "5 Tips Pemanasan Sebelum Olahraga",
                            "Kesehatan",
                            "https://images.unsplash.com/photo-1571019614242-c5c5dee9f50b?w=400",
                          ),
                          _buildArticleCard(
                            "Teknik Dasar Bermain Badminton",
                            "Tutorial",
                            "https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=400",
                          ),
                          _buildArticleCard(
                            "Nutrisi Penting untuk Atlet",
                            "Nutrisi",
                            "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=400",
                          ),
                          _buildArticleCard(
                            "Cara Mencegah Cedera Olahraga",
                            "Kesehatan",
                            "https://images.unsplash.com/photo-1597452485669-2c7bb5fef90d?w=400",
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === KOMUNITAS OLAHRAGA ===
                    _buildSectionHeader("Komunitas Olahraga", icon: Icons.groups, iconColor: Colors.indigo),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 140,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildCommunityCard("Jakarta Futsal Club", "1.2K", Colors.green, Icons.sports_soccer),
                          _buildCommunityCard("Badminton Lovers", "890", Colors.blue, Icons.sports_tennis),
                          _buildCommunityCard("Basketball Warriors", "650", Colors.orange, Icons.sports_basketball),
                          _buildCommunityCard("Swimming Jakarta", "420", Colors.cyan, Icons.pool),
                          _buildCommunityCard("Gym Bros Indonesia", "1.5K", Colors.red, Icons.fitness_center),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === VENUE BARU ===
                    _buildSectionHeader("Venue Baru", icon: Icons.new_releases, iconColor: Colors.green),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 200,
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _venues.take(4).length,
                              itemBuilder: (context, index) {
                                return _buildVenueCard(_venues[index], "new");
                              },
                            ),
                    ),

                    const SizedBox(height: 24),
                    _buildDivider(),
                    const SizedBox(height: 24),

                    // === REKOMENDASI UNTUKMU ===
                    _buildSectionHeader("Rekomendasi Untukmu", icon: Icons.recommend, iconColor: Colors.pink),
                    const SizedBox(height: 14),
                    ..._venues.take(3).map((venue) => _buildRecommendationCard(venue)),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === DIVIDER ===
  Widget _buildDivider() {
    return Container(
      width: double.infinity,
      height: 8,
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppColors.surfaceBorder,
    );
  }

  // === SECTION HEADER ===
  Widget _buildSectionHeader(String title, {IconData? icon, Color? iconColor, VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: (iconColor ?? AppColors.brandYellow).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor ?? AppColors.brandYellow, size: 18),
              ),
              const SizedBox(width: 10),
            ],
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.onDark,
              ),
            ),
          ],
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: const Text(
              "Lihat Semua",
              style: TextStyle(
                color: AppColors.brandYellow,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // === VENUE CARD ===
  Widget _buildVenueCard(model.Venue venue, String badge) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VenueDetailPage(venueId: venue.id, venueName: venue.name)),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image.network(
                    venue.coverImageUrl ?? 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
                    height: 110,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 110,
                      color: const Color(0xFF222226),
                      child: const Icon(Icons.image, color: AppColors.onDarkMuted),
                    ),
                  ),
                ),
                // Badge
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getBadgeColor(badge),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getBadgeIcon(badge), color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          _getBadgeText(badge),
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
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    venue.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.onDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppColors.brandYellow, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        venue.averageRating?.toStringAsFixed(1) ?? "4.5",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onDark),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.location_on, color: AppColors.onDarkMuted, size: 14),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          venue.city ?? "Jakarta",
                          style: const TextStyle(fontSize: 11, color: AppColors.onDarkMuted),
                          overflow: TextOverflow.ellipsis,
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

  Color _getBadgeColor(String badge) {
    switch (badge) {
      case "populer": return Colors.red;
      case "rating": return Colors.amber.shade700;
      case "new": return Colors.green;
      default: return AppColors.brandYellow;
    }
  }

  IconData _getBadgeIcon(String badge) {
    switch (badge) {
      case "populer": return Icons.trending_up;
      case "rating": return Icons.star;
      case "new": return Icons.fiber_new;
      default: return Icons.verified;
    }
  }

  String _getBadgeText(String badge) {
    switch (badge) {
      case "populer": return "Populer";
      case "rating": return "Top Rated";
      case "new": return "Baru";
      default: return "Featured";
    }
  }

  // === EVENT CARD ===
  Widget _buildEventCard(String title, String date, String location, Color color, IconData icon) {
    return GestureDetector(
      onTap: () {
        _showEventDetail(title, date, location, color);
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Daftar",
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Text(date, style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on, color: Colors.white70, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    location,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDetail(String title, String date, String location, Color color) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.7)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Icon(Icons.emoji_events, color: Colors.white, size: 60),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.onDark),
                    ),
                    const SizedBox(height: 12),
                    _buildEventInfoRow(Icons.calendar_today, "Tanggal", date),
                    _buildEventInfoRow(Icons.location_on, "Lokasi", location),
                    _buildEventInfoRow(Icons.people, "Peserta", "32 tim terdaftar"),
                    _buildEventInfoRow(Icons.monetization_on, "Biaya", "Rp 500.000 / tim"),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Pendaftaran event akan segera dibuka!"),
                              backgroundColor: AppColors.surface,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Daftar Sekarang",
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
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

  Widget _buildEventInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.onDarkMuted, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.onDarkMuted)),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.onDark)),
            ],
          ),
        ],
      ),
    );
  }

  // === CHALLENGE CARD ===
  Widget _buildChallengeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.flag, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Challenge Minggu Ini",
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      "Olahraga 3x Seminggu",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "50 Poin",
                  style: TextStyle(
                    color: Color(0xFF7C3AED),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Progress: 1/3",
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13),
                  ),
                  const Text(
                    "33%",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: 0.33,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              Text(
                "5 hari lagi",
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text(
                  "Lihat Detail",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // === ARTICLE CARD ===
  Widget _buildArticleCard(String title, String category, String imageUrl) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Membuka artikel: $title"),
            backgroundColor: AppColors.surface,
          ),
        );
      },
      child: Container(
        width: 200,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                height: 90,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 90,
                  color: const Color(0xFF222226),
                  child: const Icon(Icons.article, color: AppColors.onDarkMuted),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        color: Colors.teal,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.onDark,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // === COMMUNITY CARD ===
  Widget _buildCommunityCard(String name, String members, Color color, IconData icon) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bergabung dengan $name"),
            backgroundColor: AppColors.surface,
            action: SnackBarAction(
              label: "Gabung",
              textColor: AppColors.brandYellow,
              onPressed: () {},
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const Spacer(),
            Text(
              name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.onDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.people, size: 14, color: AppColors.onDarkMuted),
                const SizedBox(width: 4),
                Text(
                  "$members members",
                  style: const TextStyle(fontSize: 11, color: AppColors.onDarkMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // === RECOMMENDATION CARD ===
  Widget _buildRecommendationCard(model.Venue venue) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VenueDetailPage(venueId: venue.id, venueName: venue.name)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                venue.coverImageUrl ?? 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=400',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFF222226),
                  child: const Icon(Icons.image, color: AppColors.onDarkMuted),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.pink.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      "Direkomendasikan",
                      style: TextStyle(
                        color: Colors.pink,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      const Icon(Icons.star, color: AppColors.brandYellow, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        venue.averageRating?.toStringAsFixed(1) ?? "4.5",
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.onDark),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, color: AppColors.onDarkMuted, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          venue.city ?? "Jakarta",
                          style: const TextStyle(fontSize: 12, color: AppColors.onDarkMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.onDarkMuted),
          ],
        ),
      ),
    );
  }
}
