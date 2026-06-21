import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../models/field_type.dart';
import '../services/field_type_service.dart';
import 'category_venues_page.dart';

class AllCategoriesPage extends StatefulWidget {
  const AllCategoriesPage({Key? key}) : super(key: key);

  @override
  State<AllCategoriesPage> createState() => _AllCategoriesPageState();
}

class _AllCategoriesPageState extends State<AllCategoriesPage> {
  List<FieldType> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final types = await FieldTypeService.getFieldTypes();

    if (mounted) {
      setState(() {
        _categories = types;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        systemOverlayStyle: SystemUiOverlayStyle.light,
        title: const Text(
          'Semua Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.onDark,
          ),
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.onDark),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => FieldTypeService.getFieldTypes(forceRefresh: true).then((types) {
            setState(() => _categories = types);
          }),
          color: AppColors.brandYellow,
          backgroundColor: AppColors.surface,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.brandYellow,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pilih kategori olahraga untuk melihat venue terdekat',
                          style: TextStyle(
                            color: AppColors.onDark,
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
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.brandYellow,
                          ),
                        )
                      : _categories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.category_outlined,
                                    size: 64,
                                    color: AppColors.onDarkMuted,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Tidak ada kategori tersedia',
                                    style: TextStyle(
                                      color: AppColors.onDarkMuted,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                                childAspectRatio: 1.1,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                return _buildCategoryCard(context, category);
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, FieldType category) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryVenuesPage(
              categoryName: category.label,
              categoryIcon: category.icon,
              categoryColor: category.color,
              fieldType: category.value,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon dengan background warna
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.brandYellow.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category.icon,
                size: 30,
                color: AppColors.brandYellow,
              ),
            ),

            const SizedBox(height: 12),

            // Nama kategori
            Text(
              category.label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.onDark,
              ),
            ),

            // Venue count (if available)
            if (category.venueCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${category.venueCount} venue',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onDarkMuted,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
