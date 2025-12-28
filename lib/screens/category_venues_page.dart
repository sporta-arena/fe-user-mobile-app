import 'package:flutter/material.dart';
import '../constants/colors.dart';

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

  // Data dummy venues berdasarkan kategori
  List<Map<String, dynamic>> get venues {
    switch (widget.categoryName.toLowerCase()) {
      case 'futsal':
        return [
          {
            'name': 'Futsal Arena Champions',
            'location': 'Kemang, Jakarta Selatan',
            'distance': '1.2 km',
            'price': 'Rp 150.000',
            'rating': '4.9',
            'reviews': 245,
            'facilities': ['Parkir', 'Kantin', 'AC', 'Shower'],
            'available': true,
          },
          {
            'name': 'Sporta Futsal Center',
            'location': 'Tebet, Jakarta Selatan',
            'distance': '2.1 km',
            'price': 'Rp 120.000',
            'rating': '4.7',
            'reviews': 189,
            'facilities': ['Parkir', 'Kantin', 'Shower'],
            'available': true,
          },
          {
            'name': 'Victory Futsal Court',
            'location': 'Pancoran, Jakarta Selatan',
            'distance': '3.5 km',
            'price': 'Rp 100.000',
            'rating': '4.5',
            'reviews': 156,
            'facilities': ['Parkir', 'Kantin'],
            'available': false,
          },
        ];
      case 'badminton':
        return [
          {
            'name': 'GOR Bulutangkis Sejahtera',
            'location': 'Tebet, Jakarta Selatan',
            'distance': '0.8 km',
            'price': 'Rp 60.000',
            'rating': '4.8',
            'reviews': 312,
            'facilities': ['Parkir', 'AC', 'Shower', 'Kantin'],
            'available': true,
          },
          {
            'name': 'Badminton Hall Premium',
            'location': 'Kemang, Jakarta Selatan',
            'distance': '1.5 km',
            'price': 'Rp 80.000',
            'rating': '4.6',
            'reviews': 198,
            'facilities': ['Parkir', 'AC', 'Shower'],
            'available': true,
          },
        ];
      default:
        return [
          {
            'name': '${widget.categoryName} Arena Pro',
            'location': 'Jakarta Selatan',
            'distance': '1.0 km',
            'price': 'Rp 100.000',
            'rating': '4.7',
            'reviews': 150,
            'facilities': ['Parkir', 'Shower'],
            'available': true,
          },
        ];
    }
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
              // Implementasi search
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
                        '${venues.length} venue tersedia',
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
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: venues.length,
              itemBuilder: (context, index) {
                final venue = venues[index];
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
                      venue['distance'],
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
                                text: venue['price'],
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
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Booking ${venue['name']}...'),
                            backgroundColor: AppColors.primaryBlue,
                          ),
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
      },
    );
  }
}