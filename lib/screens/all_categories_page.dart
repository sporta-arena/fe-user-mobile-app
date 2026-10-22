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
      appBar: AppBar(
        title: const Text('Semua Kategori'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () =>
              FieldTypeService.getFieldTypes(forceRefresh: true).then((types) {
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
                                // Turun dari 1.1: nama dua baris butuh
                                // tinggi sedikit lebih.
                                childAspectRatio: 0.98,
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
              categoryColor: context.c.kategori(category.indeksWarna),
              fieldType: category.value,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.c.line),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ubin kuning pucat bergaris kuning dengan ikon hitam, sama
            // dengan baris kategori di beranda. Warna per cabang tinggal
            // titik kecil di pojok: cukup untuk membedakan dua puluh
            // empat cabang tanpa membuat halamannya jadi pelangi.
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: context.c.accentSoft,
                    border: Border.all(color: context.c.accentLine),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(category.icon, size: 30, color: context.c.ink),
                ),
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: context.c.kategori(category.indeksWarna),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Nama kategori
            // Nama panjang seperti "Yoga & Pilates" atau "Panjat
            // Tebing" tidak muat satu baris di lebar setengah layar.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                category.label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: context.c.ink,
                ),
              ),
            ),

            // Venue count (if available)
            if (category.venueCount > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${category.venueCount} venue',
                  style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
