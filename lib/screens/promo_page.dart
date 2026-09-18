import 'package:flutter/material.dart';

import '../models/banner_promo.dart';
import '../services/promo_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/lembar_promo.dart';

/// Semua promo yang sedang berjalan.
///
/// Daftarnya dari /promos, bukan dari banner: promo tanpa banner —
/// kode yang dibagikan lewat WhatsApp, misalnya — tetap harus bisa
/// ditemukan di sini.
class PromoPage extends StatefulWidget {
  const PromoPage({super.key});

  @override
  State<PromoPage> createState() => _PromoPageState();
}

class _PromoPageState extends State<PromoPage> {
  List<RingkasPromo> _promo = const [];
  bool _memuat = true;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    final hasil = await PromoBerjalan.ambil();
    if (!mounted) return;
    setState(() {
      _promo = hasil;
      _memuat = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        elevation: 0,
        title: Text(
          'Promo Berjalan',
          style: TextStyle(
            color: context.c.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: context.c.ink),
      ),
      body: SafeArea(
        top: false,
        child: _memuat
            ? Center(child: CircularProgressIndicator(color: context.c.accent))
            : _promo.isEmpty
            ? _kosong()
            : RefreshIndicator(
                onRefresh: _muat,
                color: context.c.accent,
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: _promo.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (_, i) => _kartu(_promo[i]),
                ),
              ),
      ),
    );
  }

  Widget _kosong() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_offer_outlined, size: 44, color: context.c.inkDim),
            const SizedBox(height: 14),
            Text(
              'Belum ada promo berjalan',
              style: TextStyle(
                color: context.c.ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Promo baru muncul di sini begitu ada yang dibuka. '
              'Cek lagi nanti ya.',
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.inkSoft, fontSize: 13.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kartu(RingkasPromo p) {
    return GestureDetector(
      onTap: () => tampilkanLembarPromo(context, p),
      child: Container(
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.c.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (p.gambarUrl != null && p.gambarUrl!.isNotEmpty)
              SizedBox(
                height: 130,
                width: double.infinity,
                child: Image.network(
                  p.gambarUrl!,
                  fit: BoxFit.cover,
                  // Promo tanpa gambar dan promo yang gambarnya gagal
                  // dimuat sama-sama tetap terbaca: keterangannya ada di
                  // bawah, bukan di dalam gambarnya.
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.judul,
                    style: TextStyle(
                      color: context.c.ink,
                      fontSize: 15.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Kodenya TIDAK ditampilkan di kartu.
                  //
                  // Kode yang terbaca sekilas di daftar akan diketik
                  // ulang dari ingatan, dan salah ketik terbaca sebagai
                  // "promonya tidak berlaku". Di lembar rincian ia
                  // muncul besar dengan tombol salin — satu ketukan,
                  // tanpa peluang salah. Kartu ini cukup mengatakan
                  // promonya ada dan berapa potongannya.
                  Text(
                    'Potongan ${p.potonganTeks}',
                    style: TextStyle(
                      color: context.c.accent,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (p.berlakuSampai != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Berlaku sampai ${p.berlakuSampai}',
                      style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
