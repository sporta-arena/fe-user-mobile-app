import 'package:flutter/material.dart';

import '../models/banner_promo.dart';
import '../services/promo_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/lembar_promo.dart';
import '../widgets/sportago_ui.dart';

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
      appBar: AppBar(elevation: 0, title: const Text('Promo Berjalan')),
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
    return const Center(
      child: KeadaanKosong(
        ikon: Icons.local_offer_outlined,
        judul: 'Belum ada promo berjalan',
        pesan: 'Promo baru muncul di sini begitu ada yang dibuka. '
            'Cek lagi nanti ya.',
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
              // 2:1, sama dengan carousel di beranda. Rasio yang sama di
              // dua tempat berarti satu ukuran yang bisa diberitahukan ke
              // tim design, dan gambarnya tidak terpotong di mana pun.
              AspectRatio(
                aspectRatio: 2,
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
                  // Potongannya pil kuning merek berteks hitam: angka
                  // inilah yang dicari, jadi ia yang paling mencolok.
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: SportagoColors.kuning,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Potongan ${p.potonganTeks}',
                      style: TextStyle(
                        color: SportagoColors.light.ink,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
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
