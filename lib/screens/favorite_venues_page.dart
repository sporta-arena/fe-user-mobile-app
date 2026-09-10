import 'package:flutter/material.dart';

import '../services/favorite_service.dart';
import '../theme/app_tokens.dart';
import '../utils/tampilan_venue.dart';
import '../widgets/sampul_venue.dart';
import 'venue_detail_page.dart';

/// Daftar venue yang ditandai hati.
///
/// Halaman ini yang membuat ikon hati di detail venue berarti: sebelum
/// ada layar ini, tidak ada satu pun tempat yang membaca daftarnya.
class FavoriteVenuesPage extends StatefulWidget {
  const FavoriteVenuesPage({super.key});

  @override
  State<FavoriteVenuesPage> createState() => _FavoriteVenuesPageState();
}

class _FavoriteVenuesPageState extends State<FavoriteVenuesPage> {
  final FavoriteService _service = FavoriteService();

  @override
  void initState() {
    super.initState();
    _service.addListener(_perbarui);
  }

  @override
  void dispose() {
    _service.removeListener(_perbarui);
    super.dispose();
  }

  void _perbarui() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final daftar = _service.favorites;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        backgroundColor: context.c.surface,
        elevation: 0,
        title: Text(
          'Venue Favorit',
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: context.c.ink, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: daftar.isEmpty ? _kosong(context) : _isi(context, daftar),
    );
  }

  Widget _kosong(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 56, color: context.c.inkSoft),
            const SizedBox(height: 16),
            Text(
              'Belum ada venue favorit',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: context.c.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ketuk ikon hati di halaman venue untuk menyimpannya di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.inkSoft, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _isi(BuildContext context, List<FavoriteVenue> daftar) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: daftar.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final v = daftar[i];
        return _kartu(context, v);
      },
    );
  }

  Widget _kartu(BuildContext context, FavoriteVenue v) {
    final id = int.tryParse(v.id);

    return Container(
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.line),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: id == null
              ? null
              : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VenueDetailPage(venueId: id),
                    ),
                  ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SampulVenue(
                  nama: v.name,
                  urlGambar: v.imageUrl,
                  olahraga: v.category,
                  lebar: 64,
                  tinggi: 64,
                  ukuranInisial: 18,
                  radius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        v.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: context.c.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        v.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(ikonOlahraga(v.category),
                              size: 14, color: context.c.inkSoft),
                          const SizedBox(width: 4),
                          Text(
                            // Rating cuma muncul kalau memang ada.
                            // '0.0' terbaca sebagai "dinilai nol",
                            // padahal artinya "belum pernah dinilai".
                            v.rating == null
                                ? 'Belum ada ulasan'
                                : '${v.rating!.toStringAsFixed(1)} rating',
                            style: TextStyle(
                                fontSize: 12, color: context.c.inkSoft),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus dari favorit',
                  icon: Icon(Icons.favorite, color: context.c.danger),
                  onPressed: () => _service.removeFavorite(v.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
