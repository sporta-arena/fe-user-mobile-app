import 'package:flutter/material.dart';
import '../constants/colors.dart';
import 'category_venues_page.dart';

class AllCategoriesPage extends StatelessWidget {
  const AllCategoriesPage({Key? key}) : super(key: key);

  // Data kategori olahraga
  final List<Map<String, dynamic>> categories = const [
    {'title': 'Futsal', 'icon': Icons.sports_soccer, 'color': Colors.green, 'venues': 45},
    {'title': 'Badminton', 'icon': Icons.sports_tennis, 'color': Colors.blue, 'venues': 32},
    {'title': 'Basket', 'icon': Icons.sports_basketball, 'color': Colors.orange, 'venues': 18},
    {'title': 'Renang', 'icon': Icons.pool, 'color': Colors.cyan, 'venues': 12},
    {'title': 'Gym', 'icon': Icons.fitness_center, 'color': Colors.red, 'venues': 28},
    {'title': 'Tenis', 'icon': Icons.sports_tennis, 'color': Colors.purple, 'venues': 15},
    {'title': 'Voli', 'icon': Icons.sports_volleyball, 'color': Colors.indigo, 'venues': 22},
    {'title': 'Ping Pong', 'icon': Icons.sports_tennis, 'color': Colors.teal, 'venues': 19},
    {'title': 'Billiard', 'icon': Icons.sports_esports, 'color': Colors.brown, 'venues': 8},
    {'title': 'Bowling', 'icon': Icons.sports_cricket, 'color': Colors.deepOrange, 'venues': 6},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'Semua Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Pilih kategori olahraga untuk melihat venue terdekat',
                        style: TextStyle(
                          color: AppColors.primaryBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Grid kategori
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return _buildCategoryCard(context, category);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () {
        // Navigasi ke halaman venue berdasarkan kategori
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryVenuesPage(
              categoryName: category['title'],
              categoryIcon: category['icon'],
              categoryColor: category['color'],
            ),
          ),
        );
      },
      child: Container(
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon dengan background warna
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: (category['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category['icon'],
                size: 30,
                color: category['color'],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Nama kategori
            Text(
              category['title'],
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 4),
            
            // Jumlah venue
            Text(
              '${category['venues']} venue',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Indikator "Tersedia"
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tersedia',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}