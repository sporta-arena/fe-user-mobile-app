import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PromoDetailPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final Map<String, dynamic>? promoData;

  const PromoDetailPage({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    this.promoData,
  });

  @override
  Widget build(BuildContext context) {
    final promoCode = promoData?['code'] ?? 'SPORTA50';
    final description = promoData?['description'] ?? 'Promo spesial untuk pengguna Sporta.';
    final validUntil = promoData?['validUntil'] ?? '31 Jan 2026';
    final promoType = promoData?['type'] ?? 'discount';
    final imageUrl = promoData?['image'];
    final discount = promoData?['discount'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: color,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.black87),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Promo berhasil dibagikan!")),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.6),
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Promo Badge
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getPromoTypeColor(promoType),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getPromoTypeLabel(promoType),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                        ),
                        if (discount.isNotEmpty)
                          Row(
                            children: [
                              Text(
                                "Hingga $discount",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              if (promoType != 'freebie')
                                const Text(
                                  "%",
                                  style: TextStyle(
                                    color: Colors.amber,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
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
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promo Code Card
                  Container(
                    padding: const EdgeInsets.all(20),
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
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.confirmation_number, color: color, size: 24),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Kode Promo",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    promoCode,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: promoCode));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      children: [
                                        const Icon(Icons.check_circle, color: Colors.white),
                                        const SizedBox(width: 8),
                                        Text("Kode $promoCode berhasil disalin!"),
                                      ],
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0047FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.copy, color: Color(0xFF0047FF)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 8),
                              Text(
                                "Berlaku hingga $validUntil",
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Description
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: color, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Deskripsi Promo",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          description,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Terms & Conditions
                  Container(
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            Icon(Icons.rule, color: color, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              "Syarat & Ketentuan",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSyarat("Promo berlaku untuk semua pengguna Sporta."),
                        _buildSyarat("Minimum transaksi booking Rp 100.000."),
                        _buildSyarat("Berlaku untuk semua venue di aplikasi."),
                        _buildSyarat("Tidak dapat digabung dengan promo lain."),
                        _buildSyarat("Periode promo: hingga $validUntil."),
                        _buildSyarat("Sporta berhak membatalkan promo sewaktu-waktu."),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text("Promo $promoCode berhasil diaktifkan!"),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0047FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_offer, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    "PAKAI PROMO SEKARANG",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getPromoTypeColor(String type) {
    switch (type) {
      case 'discount':
        return Colors.red;
      case 'cashback':
        return Colors.green;
      case 'freebie':
        return Colors.purple;
      default:
        return const Color(0xFF0047FF);
    }
  }

  String _getPromoTypeLabel(String type) {
    switch (type) {
      case 'discount':
        return 'DISKON';
      case 'cashback':
        return 'CASHBACK';
      case 'freebie':
        return 'GRATIS';
      default:
        return 'PROMO';
    }
  }

  Widget _buildSyarat(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            child: const Icon(Icons.check_circle, color: Colors.green, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// ALL PROMOS PAGE
// ==========================================
class AllPromosPage extends StatelessWidget {
  const AllPromosPage({super.key});

  static final List<Map<String, dynamic>> _allPromos = [
    {
      'id': '1',
      'badge': 'Waktu Terbatas!',
      'title': 'Diskon Spesial',
      'discount': '30',
      'subtitle': 'Semua lapangan | S&K Berlaku',
      'description': 'Dapatkan diskon hingga 30% untuk semua lapangan olahraga. Promo berlaku untuk booking di hari kerja (Senin-Jumat) jam 08:00-15:00.',
      'validUntil': '31 Jan 2026',
      'code': 'SPORTA30',
      'type': 'discount',
      'image': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=600',
    },
    {
      'id': '2',
      'badge': 'Member Baru',
      'title': 'Gratis Booking',
      'discount': '1x',
      'subtitle': 'Booking pertama gratis | S&K Berlaku',
      'description': 'Khusus member baru! Nikmati gratis 1x booking untuk pengalaman pertamamu di Sporta. Daftar sekarang dan langsung main!',
      'validUntil': '28 Feb 2026',
      'code': 'NEWMEMBER',
      'type': 'freebie',
      'image': 'https://images.unsplash.com/photo-1551958219-acbc608c6377?w=600',
    },
    {
      'id': '3',
      'badge': 'Weekend Deal',
      'title': 'Cashback',
      'discount': '20',
      'subtitle': 'Sabtu & Minggu | S&K Berlaku',
      'description': 'Main di weekend lebih hemat! Dapatkan cashback 20% untuk setiap booking di hari Sabtu dan Minggu. Cashback masuk ke Sporta Points.',
      'validUntil': '15 Jan 2026',
      'code': 'WEEKEND20',
      'type': 'cashback',
      'image': 'https://images.unsplash.com/photo-1459865264687-595d652de67e?w=600',
    },
    {
      'id': '4',
      'badge': 'Flash Sale',
      'title': 'Diskon Malam',
      'discount': '40',
      'subtitle': 'Jam 20:00-23:00 | S&K Berlaku',
      'description': 'Promo khusus untuk booking malam hari! Dapatkan diskon hingga 40% untuk slot jam 20:00 - 23:00.',
      'validUntil': '20 Jan 2026',
      'code': 'NIGHT40',
      'type': 'discount',
      'image': 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?w=600',
    },
    {
      'id': '5',
      'badge': 'Promo Grup',
      'title': 'Booking Bareng',
      'discount': '25',
      'subtitle': 'Min. 3 jam | S&K Berlaku',
      'description': 'Booking minimal 3 jam sekaligus dan dapatkan diskon 25%! Cocok untuk turnamen atau latihan tim.',
      'validUntil': '31 Jan 2026',
      'code': 'GRUPHEMAT',
      'type': 'discount',
      'image': 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?w=600',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Semua Promo",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allPromos.length,
        itemBuilder: (context, index) {
          final promo = _allPromos[index];
          return _buildPromoCard(context, promo);
        },
      ),
    );
  }

  Widget _buildPromoCard(BuildContext context, Map<String, dynamic> promo) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PromoDetailPage(
              title: promo['title']!,
              subtitle: promo['subtitle']!,
              color: const Color(0xFF0047FF),
              promoData: promo,
            ),
          ),
        );
      },
      child: Container(
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
          children: [
            // Image
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                image: DecorationImage(
                  image: NetworkImage(promo['image']!),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.5),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getPromoTypeColor(promo['type']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        promo['badge']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Row(
                      children: [
                        Text(
                          promo['title']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "${promo['discount']}${promo['type'] != 'freebie' ? '%' : ''}",
                          style: const TextStyle(
                            color: Colors.amber,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          promo['subtitle']!,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.access_time, size: 14, color: Colors.orange.shade600),
                            const SizedBox(width: 4),
                            Text(
                              "s/d ${promo['validUntil']}",
                              style: TextStyle(
                                color: Colors.orange.shade600,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0047FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      "Lihat",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getPromoTypeColor(String type) {
    switch (type) {
      case 'discount':
        return Colors.red;
      case 'cashback':
        return Colors.green;
      case 'freebie':
        return Colors.purple;
      default:
        return const Color(0xFF0047FF);
    }
  }
}
