import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
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
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: Text(
          'Semua Kategori',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: context.c.ink,
          ),
        ),
        backgroundColor: context.c.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: context.c.ink),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => FieldTypeService.getFieldTypes(forceRefresh: true).then((types) {
            setState(() => _categories = types);
          }),
          color: context.c.accent,
          backgroundColor: context.c.raised,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.c.raised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.c.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: context.c.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Pilih kategori olahraga untuk melihat venue terdekat',
                          style: TextStyle(
                            color: context.c.ink,
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
                      ? Center(
                          child: CircularProgressIndicator(
                            color: context.c.accent,
                          ),
                        )
                      : _categories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.category_outlined,
                                    size: 64,
                                    color: context.c.inkSoft,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Tidak ada kategori tersedia',
                                    style: TextStyle(
                                      color: context.c.inkSoft,
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
          color: context.c.raised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.c.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon dengan background warna
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: context.c.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                category.icon,
                size: 30,
                color: context.c.accent,
              ),
            ),

            const SizedBox(height: 12),

            // Nama kategori
            Text(
              category.label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.c.ink,
              ),
            ),

            // Venue count (if available)
            if (category.venueCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${category.venueCount} venue',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.c.inkSoft,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
