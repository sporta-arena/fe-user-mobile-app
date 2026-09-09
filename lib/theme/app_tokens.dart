import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// ═══════════════════════════════════════════════════════════════════
/// SPORTAGO — token warna
/// ───────────────────────────────────────────────────────────────────
/// Satu set token semantik, dua set nilai (terang & gelap). Nilainya
/// disamakan dengan `globals.css` di fe-web supaya kedua permukaan
/// benar-benar satu merek, bukan cuma mirip.
///
/// Aturannya sama seperti di web: widget TIDAK menyebut warna literal.
/// Widget menyebut PERAN — permukaan, teks, garis, aksen — dan lapisan
/// ini yang menentukan nilainya menurut tema aktif.
///
/// Dipakai lewat `context.c`, contoh:
///
///   Container(color: context.c.raised)
///   Text('...', style: TextStyle(color: context.c.inkSoft))
/// ═══════════════════════════════════════════════════════════════════
@immutable
class SportagoColors extends ThemeExtension<SportagoColors> {
  const SportagoColors({
    required this.surface,
    required this.raised,
    required this.sunken,
    required this.hoverSurface,
    required this.inverse,
    required this.onInverse,
    required this.ink,
    required this.inkSoft,
    required this.inkDim,
    required this.onAccent,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accentHover,
    required this.accentSoft,
    required this.accentLine,
    required this.ok,
    required this.okSoft,
    required this.warn,
    required this.warnSoft,
    required this.danger,
    required this.dangerSoft,
    required this.info,
    required this.infoSoft,
  });

  /// Permukaan — dari yang paling belakang ke paling depan.
  final Color surface; // latar layar
  final Color raised; // kartu, panel, sheet
  final Color sunken; // bidang masuk ke dalam
  final Color hoverSurface; // keadaan ditekan / disorot
  final Color inverse; // blok kontras, tooltip
  final Color onInverse;

  /// Teks.
  final Color ink; // isi utama
  final Color inkSoft; // penjelas
  final Color inkDim; // meta, placeholder
  final Color onAccent; // teks di atas warna aksen

  /// Garis.
  final Color line;
  final Color lineStrong;

  /// Aksen merek. Hijau lapangan waktu terang, volt waktu gelap —
  /// satu warna aksi per tema, bukan dua yang berebut.
  final Color accent;
  final Color accentHover;
  final Color accentSoft;
  final Color accentLine;

  /// Status.
  final Color ok;
  final Color okSoft;
  final Color warn;
  final Color warnSoft;
  final Color danger;
  final Color dangerSoft;
  final Color info;
  final Color infoSoft;

  // ── Nilai yang TIDAK pernah ikut tema ────────────────────────────

  /// Tirai di atas foto. Foto tidak berganti tema, jadi tirainya juga
  /// tidak. Di web ini sempat salah — tirai ditulis pakai token yang
  /// ikut tema, dan gambarnya kebelah separuh terang separuh gelap.
  static const Color scrim = Color(0xFF080C0A);

  /// Benar-benar putih — untuk teks/ikon di atas foto.
  static const Color pure = Color(0xFFFFFFFF);

  /// Volt asli. Dipakai HANYA di tempat yang memang selalu gelap
  /// (splash, konten di atas foto), bukan sebagai warna aksi umum.
  static const Color volt = Color(0xFFC5F400);

  /// Palet KONTEN — untuk membedakan kategori, bukan untuk menyatakan
  /// keadaan. Kartu komunitas, kartu event, dan ikon judul bagian pakai
  /// ini.
  ///
  /// Kenapa dipisah dari token status: memakai `danger` untuk badge
  /// "Populer" membuat label netral terbaca sebagai peringatan, dan
  /// memaksa banyak kategori ke sedikit token status membuat dua
  /// kategori berbeda tampil dengan warna yang sama.
  ///
  /// Nuansanya sengaja diturunkan saturasinya supaya berdampingan
  /// dengan hijau/volt tanpa saling berteriak.
  static const List<Color> kategoriTerang = [
    Color(0xFF1F6F54), // hijau laut
    Color(0xFF2A6F97), // biru petang
    Color(0xFF8A5A2B), // tembaga
    Color(0xFF6A4C93), // ungu tua
    Color(0xFF9A5B08), // amber tua
    Color(0xFF14746F), // teal tua
  ];

  static const List<Color> kategoriGelap = [
    Color(0xFF5FD3A8),
    Color(0xFF6CB6E0),
    Color(0xFFD9A05B),
    Color(0xFFB59BE0),
    Color(0xFFE0A312),
    Color(0xFF5FC9C4),
  ];

  /// Warna kategori ke-[i], berputar kalau indeksnya melebihi palet.
  Color kategori(int i) {
    final daftar = ink == light.ink ? kategoriTerang : kategoriGelap;
    return daftar[i % daftar.length];
  }

  // ── Tema terang ──────────────────────────────────────────────────
  static const SportagoColors light = SportagoColors(
    surface: Color(0xFFFBFCFB),
    raised: Color(0xFFFFFFFF),
    sunken: Color(0xFFF2F5F3),
    hoverSurface: Color(0xFFEDF1EE),
    inverse: Color(0xFF101E17),
    onInverse: Color(0xFFF4F7F5),
    ink: Color(0xFF101E17),
    inkSoft: Color(0xFF4A5C52),
    inkDim: Color(0xFF7B8A82),
    onAccent: Color(0xFFFFFFFF),
    line: Color(0xFFDEE7E1),
    lineStrong: Color(0xFFC3D2C9),
    accent: Color(0xFF00733F),
    accentHover: Color(0xFF005730),
    accentSoft: Color(0xFFEAF4EE),
    accentLine: Color(0xFFA9CDB8),
    ok: Color(0xFF12703F),
    okSoft: Color(0xFFE6F4EC),
    warn: Color(0xFF9A5B08),
    warnSoft: Color(0xFFFDF3E3),
    danger: Color(0xFFB3261E),
    dangerSoft: Color(0xFFFDECEB),
    info: Color(0xFF0F5F76),
    infoSoft: Color(0xFFE6F2F6),
  );

  // ── Tema gelap ───────────────────────────────────────────────────
  static const SportagoColors dark = SportagoColors(
    surface: Color(0xFF0A0B0E),
    raised: Color(0xFF131519),
    sunken: Color(0xFF08090B),
    hoverSurface: Color(0xFF1B1E24),
    inverse: Color(0xFFF4F7F5),
    onInverse: Color(0xFF101E17),
    ink: Color(0xFFE9ECEF),
    inkSoft: Color(0xFF98A1AB),
    inkDim: Color(0xFF69727C),
    onAccent: Color(0xFF0A0B0E),
    line: Color(0xFF262A31),
    lineStrong: Color(0xFF363B44),
    accent: volt,
    accentHover: Color(0xFFD7FF3D),
    accentSoft: Color(0xFF1A1F08),
    accentLine: Color(0xFF3F4D0A),
    ok: Color(0xFF48D18A),
    okSoft: Color(0xFF10251A),
    warn: Color(0xFFE0A312),
    warnSoft: Color(0xFF251C08),
    danger: Color(0xFFFF6B62),
    dangerSoft: Color(0xFF2A1210),
    info: Color(0xFF4CC4E6),
    infoSoft: Color(0xFF0B2028),
  );

  /// Dipakai di atas foto: permukaan selalu gelap, tapi aksennya tetap
  /// satu keluarga dengan tema halaman. Di web, memaku volt di sini
  /// bikin panel foto kuning sementara form di sebelahnya hijau.
  SportagoColors get onMedia => SportagoColors(
        surface: dark.surface,
        raised: dark.raised,
        sunken: dark.sunken,
        hoverSurface: dark.hoverSurface,
        inverse: dark.inverse,
        onInverse: dark.onInverse,
        ink: const Color(0xFFF2F5F3),
        inkSoft: const Color(0xFFC8D0CB),
        inkDim: const Color(0xFF9AA5A0),
        onAccent: dark.onAccent,
        line: dark.line,
        lineStrong: dark.lineStrong,
        // Terang cukup untuk terbaca di atas foto, tapi tetap sekeluarga
        // dengan aksen halaman.
        accent: accent == light.accent ? const Color(0xFF3ECF7E) : volt,
        accentHover:
            accent == light.accent ? const Color(0xFF5BDD94) : dark.accentHover,
        accentSoft: dark.accentSoft,
        accentLine: dark.accentLine,
        ok: dark.ok,
        okSoft: dark.okSoft,
        warn: dark.warn,
        warnSoft: dark.warnSoft,
        danger: dark.danger,
        dangerSoft: dark.dangerSoft,
        info: dark.info,
        infoSoft: dark.infoSoft,
      );

  @override
  SportagoColors copyWith({
    Color? surface,
    Color? raised,
    Color? sunken,
    Color? hoverSurface,
    Color? inverse,
    Color? onInverse,
    Color? ink,
    Color? inkSoft,
    Color? inkDim,
    Color? onAccent,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? accentHover,
    Color? accentSoft,
    Color? accentLine,
    Color? ok,
    Color? okSoft,
    Color? warn,
    Color? warnSoft,
    Color? danger,
    Color? dangerSoft,
    Color? info,
    Color? infoSoft,
  }) {
    return SportagoColors(
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      sunken: sunken ?? this.sunken,
      hoverSurface: hoverSurface ?? this.hoverSurface,
      inverse: inverse ?? this.inverse,
      onInverse: onInverse ?? this.onInverse,
      ink: ink ?? this.ink,
      inkSoft: inkSoft ?? this.inkSoft,
      inkDim: inkDim ?? this.inkDim,
      onAccent: onAccent ?? this.onAccent,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      accent: accent ?? this.accent,
      accentHover: accentHover ?? this.accentHover,
      accentSoft: accentSoft ?? this.accentSoft,
      accentLine: accentLine ?? this.accentLine,
      ok: ok ?? this.ok,
      okSoft: okSoft ?? this.okSoft,
      warn: warn ?? this.warn,
      warnSoft: warnSoft ?? this.warnSoft,
      danger: danger ?? this.danger,
      dangerSoft: dangerSoft ?? this.dangerSoft,
      info: info ?? this.info,
      infoSoft: infoSoft ?? this.infoSoft,
    );
  }

  @override
  SportagoColors lerp(ThemeExtension<SportagoColors>? other, double t) {
    if (other is! SportagoColors) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return SportagoColors(
      surface: c(surface, other.surface),
      raised: c(raised, other.raised),
      sunken: c(sunken, other.sunken),
      hoverSurface: c(hoverSurface, other.hoverSurface),
      inverse: c(inverse, other.inverse),
      onInverse: c(onInverse, other.onInverse),
      ink: c(ink, other.ink),
      inkSoft: c(inkSoft, other.inkSoft),
      inkDim: c(inkDim, other.inkDim),
      onAccent: c(onAccent, other.onAccent),
      line: c(line, other.line),
      lineStrong: c(lineStrong, other.lineStrong),
      accent: c(accent, other.accent),
      accentHover: c(accentHover, other.accentHover),
      accentSoft: c(accentSoft, other.accentSoft),
      accentLine: c(accentLine, other.accentLine),
      ok: c(ok, other.ok),
      okSoft: c(okSoft, other.okSoft),
      warn: c(warn, other.warn),
      warnSoft: c(warnSoft, other.warnSoft),
      danger: c(danger, other.danger),
      dangerSoft: c(dangerSoft, other.dangerSoft),
      info: c(info, other.info),
      infoSoft: c(infoSoft, other.infoSoft),
    );
  }
}

/// Gaya ikon bilah status yang ikut tema.
///
/// Penamaan bawaan Flutter terbalik dari dugaan — `SystemUiOverlayStyle.light`
/// berarti ikonnya GELAP (gaya untuk latar terang). Layar-layar di app ini
/// dulu memasang `.light` apa adanya karena semuanya gelap; begitu tema
/// terang menyala, jam dan baterai jadi putih di atas latar putih.
SystemUiOverlayStyle gayaOverlay(BuildContext context) {
  final gelap = Theme.of(context).brightness == Brightness.dark;
  return SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: gelap ? Brightness.light : Brightness.dark,
    statusBarBrightness: gelap ? Brightness.dark : Brightness.light,
  );
}

/// Pintasan supaya pemakaiannya sependek `context.c.ink`.
extension SportagoColorsX on BuildContext {
  SportagoColors get c =>
      Theme.of(this).extension<SportagoColors>() ?? SportagoColors.light;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
