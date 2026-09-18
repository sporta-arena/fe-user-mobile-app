import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/banner_promo.dart';
import '../theme/app_tokens.dart';
import '../utils/sisipan_bawah.dart';

/// Rincian promo: kode yang bisa disalin, potongannya, dan syaratnya.
///
/// Satu tempat, dipakai beranda dan layar Semua Promo. Kalau keduanya
/// menggambar sendiri, cepat atau lambat salah satunya ketinggalan saat
/// bentuk datanya berubah.
Future<void> tampilkanLembarPromo(BuildContext context, RingkasPromo p) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + context.sisipanBawah),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              p.judul,
              style: TextStyle(
                color: context.c.ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (p.deskripsi != null && p.deskripsi!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                p.deskripsi!,
                style: TextStyle(color: context.c.inkSoft, fontSize: 13.5),
              ),
            ],
            const SizedBox(height: 16),

            // Kodenya bisa disalin, bukan cuma dibaca. Mengetik ulang
            // kode berhuruf besar di ponsel itu tempat salah ketik, dan
            // salah ketik terbaca sebagai "promonya tidak berlaku".
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: p.kode));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Kode ${p.kode} disalin'),
                    backgroundColor: context.c.ok,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: context.c.accentSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: context.c.accent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.kode,
                            style: TextStyle(
                              color: context.c.ink,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Potongan ${p.potonganTeks}',
                            style: TextStyle(
                              color: context.c.accent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.copy_rounded, color: context.c.accent, size: 20),
                  ],
                ),
              ),
            ),

            if (p.berlakuSampai != null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.event_outlined, color: context.c.inkDim, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Berlaku sampai ${p.berlakuSampai}',
                    style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                  ),
                ],
              ),
            ],

            if (p.syarat.isNotEmpty) ...[
              const SizedBox(height: 18),
              Text(
                'Syarat',
                style: TextStyle(
                  color: context.c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              ...p.syarat.map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: context.c.accent,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          t,
                          style: TextStyle(
                            color: context.c.inkSoft,
                            fontSize: 13,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 18),
            Text(
              'Masukkan kodenya di halaman pembayaran.',
              style: TextStyle(color: context.c.inkDim, fontSize: 12.5),
            ),
          ],
        ),
      ),
    ),
  );
}
