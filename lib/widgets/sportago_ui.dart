import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════
/// Komponen bersama tampilan mitra
/// ───────────────────────────────────────────────────────────────────
/// Bahasa visualnya diturunkan dari pembuka (splash, onboarding,
/// Masuk): bidang hijau pekat dengan teks putih dan aksen volt di atas,
/// kartu putih lega di atas latar abu muda di bawahnya.
///
/// Halaman memakai komponen ini, bukan menggambar ulang gradien,
/// bayangan, dan sudutnya sendiri. Dulu tiap halaman punya versinya
/// masing-masing, dan perbedaan kecil itulah yang membuat aplikasinya
/// terasa tidak satu tangan.
/// ═══════════════════════════════════════════════════════════════════

/// Nada sebuah status. Warnanya diambil dari token, bukan ditulis di
/// tiap pemakai.
enum Nada { netral, aksen, ok, warn, danger, info }

extension NadaWarna on Nada {
  Color fg(SportagoColors c) => switch (this) {
        Nada.netral => c.inkSoft,
        Nada.aksen => c.accent,
        Nada.ok => c.ok,
        Nada.warn => c.warn,
        Nada.danger => c.danger,
        Nada.info => c.info,
      };

  Color bg(SportagoColors c) => switch (this) {
        Nada.netral => c.sunken,
        Nada.aksen => c.accentSoft,
        Nada.ok => c.okSoft,
        Nada.warn => c.warnSoft,
        Nada.danger => c.dangerSoft,
        Nada.info => c.infoSoft,
      };
}

/// Kepala halaman hijau pekat untuk akar tiap tab.
///
/// [foto] opsional: foto venue yang sama keluarganya dengan pembuka,
/// diredupkan supaya teks tetap jadi yang terbaca duluan. [bawah] untuk
/// isi tambahan di dalam kepala, misalnya ringkasan angka.
class KepalaPekat extends StatelessWidget {
  const KepalaPekat({
    super.key,
    required this.judul,
    this.atas,
    this.subjudul,
    this.aksi = const [],
    this.foto,
    this.bawah,
    this.bawahTembus = false,
    this.jarakBawah = 28,
  });

  final String judul;

  /// Baris kecil di atas judul, misalnya sapaan atau nama venue.
  final String? atas;
  final String? subjudul;
  final List<Widget> aksi;
  final String? foto;
  final Widget? bawah;

  /// [bawah] dibentangkan sampai tepi layar, tanpa bantalan kiri-kanan.
  /// Untuk deretan yang digeser mendatar: isinya yang memberi bantalan
  /// sendiri, supaya yang terpotong di tepi terbaca "masih ada lagi".
  final bool bawahTembus;

  /// Ruang di bawah isi. Dibesarkan kalau ada kartu yang menumpang ke
  /// tepi bawah kepala.
  final double jarakBawah;

  @override
  Widget build(BuildContext context) {
    final media = context.c.onMedia;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      child: DecoratedBox(
        decoration: const BoxDecoration(color: SportagoColors.pekat),
        child: Stack(
          children: [
            if (foto != null)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.45,
                  child: Image.asset(
                    foto!,
                    fit: BoxFit.cover,
                    excludeFromSemantics: true,
                  ),
                ),
              ),
            if (foto != null)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        SportagoColors.pekat.withValues(alpha: 0.35),
                        SportagoColors.pekat.withValues(alpha: 0.95),
                      ],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 14,
                bottom: jarakBawah,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (atas != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Text(
                                    atas!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: media.inkSoft,
                                    ),
                                  ),
                                ),
                              Text(
                                judul,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.8,
                                  height: 1.15,
                                  color: media.ink,
                                ),
                              ),
                              if (subjudul != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    subjudul!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      height: 1.45,
                                      color: media.inkSoft,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        ...aksi,
                      ],
                    ),
                  ),
                  if (bawah != null) ...[
                    const SizedBox(height: 20),
                    Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: bawahTembus ? 0 : 20),
                      child: bawah!,
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

/// Tombol ikon bulat untuk di atas bidang pekat.
class TombolIkonPekat extends StatelessWidget {
  const TombolIkonPekat({
    super.key,
    required this.ikon,
    required this.onTap,
    this.lencana,
    this.tooltip,
  });

  final IconData ikon;
  final VoidCallback onTap;

  /// Angka kecil di pojok (notifikasi, pesan). Null atau 0 = tanpa.
  final int? lencana;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tombol = Material(
      color: SportagoColors.pure.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(ikon, color: SportagoColors.pure, size: 22),
        ),
      ),
    );
    final isi = (lencana ?? 0) <= 0
        ? tombol
        : Stack(
            clipBehavior: Clip.none,
            children: [
              tombol,
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 18, minHeight: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  decoration: BoxDecoration(
                    color: SportagoColors.volt,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: SportagoColors.pekat, width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    lencana! > 99 ? '99+' : '$lencana',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: SportagoColors.pekat,
                    ),
                  ),
                ),
              ),
            ],
          );
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: tooltip == null ? isi : Tooltip(message: tooltip!, child: isi),
    );
  }
}

/// Kartu putih standar: sudut 20, garis tipis, tanpa bayangan tebal.
class Kartu extends StatelessWidget {
  const Kartu({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.warna,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  /// Latar pengganti, misalnya [SportagoColors.pekat] untuk kartu sorot.
  final Color? warna;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final bentuk = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: warna == null ? BorderSide(color: c.line) : BorderSide.none,
    );
    return Material(
      color: warna ?? c.raised,
      shape: bentuk,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

/// Judul bagian dengan tautan aksi opsional di kanan.
class JudulBagian extends StatelessWidget {
  const JudulBagian(
    this.judul, {
    super.key,
    this.aksi,
    this.onAksi,
    this.padding = const EdgeInsets.fromLTRB(4, 8, 4, 12),
  });

  final String judul;
  final String? aksi;
  final VoidCallback? onAksi;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              judul,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: context.c.ink,
              ),
            ),
          ),
          if (aksi != null)
            InkWell(
              onTap: onAksi,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Text(
                  aksi!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: context.c.accent,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ikon di dalam kotak bersudut, warna mengikuti [nada].
class UbinIkon extends StatelessWidget {
  const UbinIkon(
    this.ikon, {
    super.key,
    this.nada = Nada.aksen,
    this.ukuran = 44,
  });

  final IconData ikon;
  final Nada nada;
  final double ukuran;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: ukuran,
      height: ukuran,
      decoration: BoxDecoration(
        color: nada.bg(c),
        borderRadius: BorderRadius.circular(ukuran * 0.32),
      ),
      child: Icon(ikon, color: nada.fg(c), size: ukuran * 0.5),
    );
  }
}

/// Label status kecil berbentuk pil.
class ChipStatus extends StatelessWidget {
  const ChipStatus(this.label, {super.key, this.nada = Nada.netral});

  final String label;
  final Nada nada;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: nada.bg(c),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: nada.fg(c),
        ),
      ),
    );
  }
}

/// Satu angka ringkasan: label kecil di atas, angka tebal di bawah.
///
/// [diPekat] untuk angka yang duduk di atas bidang hijau pekat.
class AngkaStat extends StatelessWidget {
  const AngkaStat({
    super.key,
    required this.label,
    required this.nilai,
    this.ikon,
    this.catatan,
    this.diPekat = false,
  });

  final String label;
  final String nilai;
  final IconData? ikon;
  final String? catatan;
  final bool diPekat;

  @override
  Widget build(BuildContext context) {
    final c = diPekat ? context.c.onMedia : context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (ikon != null) ...[
              Icon(ikon,
                  size: 15, color: diPekat ? SportagoColors.volt : c.accent),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: c.inkSoft,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            nilai,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: c.ink,
            ),
          ),
        ),
        if (catatan != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              catatan!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: c.inkDim,
              ),
            ),
          ),
      ],
    );
  }
}

/// Keadaan kosong: ikon, judul, penjelasan, dan aksi opsional.
class KeadaanKosong extends StatelessWidget {
  const KeadaanKosong({
    super.key,
    required this.ikon,
    required this.judul,
    this.pesan,
    this.aksi,
    this.onAksi,
  });

  final IconData ikon;
  final String judul;
  final String? pesan;
  final String? aksi;
  final VoidCallback? onAksi;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UbinIkon(ikon, ukuran: 64),
          const SizedBox(height: 16),
          Text(
            judul,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: c.ink,
            ),
          ),
          if (pesan != null) ...[
            const SizedBox(height: 6),
            Text(
              pesan!,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                height: 1.5,
                color: c.inkSoft,
              ),
            ),
          ],
          if (aksi != null && onAksi != null) ...[
            const SizedBox(height: 20),
            FilledButton(onPressed: onAksi, child: Text(aksi!)),
          ],
        ],
      ),
    );
  }
}

/// Spanduk pemberitahuan di dalam halaman: verifikasi, rekening belum
/// diisi, venue ditolak, dan sejenisnya.
///
/// Dulu tiap spanduk menulis kuning/merahnya sendiri dengan kode warna
/// literal, jadi "peringatan" di Beranda dan di form venue tidak pernah
/// persis sama. Warnanya sekarang dari [nada].
class Spanduk extends StatelessWidget {
  const Spanduk({
    super.key,
    required this.judul,
    this.pesan,
    this.ikon,
    this.nada = Nada.warn,
    this.aksi,
    this.onAksi,
    this.onTap,
  });

  final String judul;
  final String? pesan;
  final IconData? ikon;
  final Nada nada;
  final String? aksi;
  final VoidCallback? onAksi;
  final VoidCallback? onTap;

  IconData get _ikonBawaan => switch (nada) {
        Nada.danger => Icons.error_outline_rounded,
        Nada.ok => Icons.check_circle_outline_rounded,
        Nada.info => Icons.info_outline_rounded,
        _ => Icons.warning_amber_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fg = nada.fg(c);
    return Material(
      color: nada.bg(c),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: fg.withValues(alpha: 0.25)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(ikon ?? _ikonBawaan, color: fg, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    if (pesan != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        pesan!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.45,
                          color: c.inkSoft,
                        ),
                      ),
                    ],
                    if (aksi != null && onAksi != null) ...[
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: onAksi,
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '$aksi  →',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(Icons.chevron_right_rounded, color: c.inkDim),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bilah tombol yang menempel di bawah form: putih, garis tipis di
/// atas, aman dari bilah navigasi sistem.
///
/// Dipasang di `Scaffold.bottomNavigationBar`, bukan di ujung isi yang
/// digulir, supaya tombol simpan selalu terlihat tanpa menggulir ke
/// bawah form yang panjang.
class BilahAksiBawah extends StatelessWidget {
  const BilahAksiBawah({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.raised,
        border: Border(top: BorderSide(color: c.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: child,
        ),
      ),
    );
  }
}
