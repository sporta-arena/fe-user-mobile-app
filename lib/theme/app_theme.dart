import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_tokens.dart';

/// ═══════════════════════════════════════════════════════════════════
/// SPORTAGO: ThemeData terang & gelap
/// ───────────────────────────────────────────────────────────────────
/// Semuanya dirakit dari [SportagoColors]. Tidak ada satu pun warna
/// literal di berkas ini, kalau ada nilai yang perlu berubah, ubahnya
/// di app_tokens.dart, sekali, dan seluruh aplikasi ikut.
/// ═══════════════════════════════════════════════════════════════════
class AppTheme {
  const AppTheme._();

  /// Satu keluarga huruf untuk seluruh aplikasi. Plus Jakarta Sans
  /// dibuat Tokotype untuk identitas kota Jakarta, sama seperti di
  /// fe-web. Hierarki dibawa bobot, bukan ganti-ganti keluarga huruf.
  static TextTheme _teks(TextTheme dasar, SportagoColors c) {
    final t = GoogleFonts.plusJakartaSansTextTheme(dasar);
    return t.apply(bodyColor: c.ink, displayColor: c.ink).copyWith(
          displayLarge: t.displayLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -1.2,
            color: c.ink,
          ),
          headlineLarge: t.headlineLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.8,
            color: c.ink,
          ),
          headlineMedium: t.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: c.ink,
          ),
          titleLarge: t.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: c.ink,
          ),
          titleMedium: t.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
          bodyLarge: t.bodyLarge?.copyWith(height: 1.5, color: c.ink),
          bodyMedium: t.bodyMedium?.copyWith(height: 1.5, color: c.ink),
          bodySmall: t.bodySmall?.copyWith(height: 1.45, color: c.inkSoft),
          labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        );
  }

  static ThemeData _bangun(SportagoColors c, Brightness brightness) {
    final gelap = brightness == Brightness.dark;
    final dasar = ThemeData(brightness: brightness, useMaterial3: true);

    final skema = ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.onAccent,
      primaryContainer: c.accentSoft,
      onPrimaryContainer: gelap ? c.accent : c.accentHover,
      secondary: c.inkSoft,
      onSecondary: c.raised,
      surface: c.surface,
      onSurface: c.ink,
      surfaceContainerLowest: c.sunken,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.raised,
      surfaceContainerHigh: c.raised,
      surfaceContainerHighest: c.hoverSurface,
      onSurfaceVariant: c.inkSoft,
      outline: c.line,
      outlineVariant: c.lineStrong,
      error: c.danger,
      onError: SportagoColors.pure,
      errorContainer: c.dangerSoft,
      onErrorContainer: c.danger,
      inverseSurface: c.inverse,
      onInverseSurface: c.onInverse,
    );

    // Sudut: dibedakan menurut peran, bukan satu angka untuk semuanya.
    // Satu radius untuk segala benda adalah salah satu ciri tampilan
    // hasil generate.
    const rKartu = 20.0;
    const rKontrol = 14.0;

    return dasar.copyWith(
      colorScheme: skema,
      // Latar sedikit abu supaya kartu putih terbaca sebagai benda,
      // bukan sekadar garis tipis di atas putih.
      scaffoldBackgroundColor: gelap ? c.surface : c.sunken,
      canvasColor: c.surface,
      dividerColor: c.line,
      splashFactory: InkSparkle.splashFactory,
      extensions: <ThemeExtension<dynamic>>[c],
      textTheme: _teks(dasar.textTheme, c),

      // Bilah aplikasi hijau pekat, sama dengan pembuka dan kepala
      // dasbor. Dulu permukaan putih polos, jadi tiap halaman turunan
      // terasa seperti aplikasi lain begitu keluar dari dasbor.
      appBarTheme: AppBarTheme(
        backgroundColor: SportagoColors.pekat,
        foregroundColor: SportagoColors.pure,
        iconTheme: const IconThemeData(color: SportagoColors.pure),
        actionsIconTheme: const IconThemeData(color: SportagoColors.pure),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.4,
          color: SportagoColors.pure,
        ),
        // Bidangnya selalu gelap, jadi ikon bilah status selalu terang.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      ),

      // Struktur dibawa garis, bukan bayangan tebal.
      cardTheme: CardThemeData(
        color: c.raised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rKartu),
          side: BorderSide(color: c.line),
        ),
      ),

      dividerTheme: DividerThemeData(color: c.line, space: 1, thickness: 1),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.raised,
        hintStyle: TextStyle(color: c.inkDim),
        prefixIconColor: c.inkDim,
        suffixIconColor: c.inkDim,
        labelStyle: TextStyle(color: c.inkSoft),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rKontrol),
          borderSide: BorderSide(color: c.lineStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rKontrol),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rKontrol),
          borderSide: BorderSide(color: c.accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rKontrol),
          borderSide: BorderSide(color: c.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(rKontrol),
          borderSide: BorderSide(color: c.danger, width: 2),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          // Tombol utama hijau pekat, warna yang sama dengan bilah
          // aplikasi; hijau lapangan tetap untuk tautan dan ikon.
          backgroundColor: gelap ? c.accent : SportagoColors.pekat,
          foregroundColor: gelap ? c.onAccent : SportagoColors.pure,
          // Tombol nonaktif harus tetap TERBACA. Sebelumnya teksnya
          // disetel ke warna permukaan (putih di tema terang) di atas
          // garis pucat, labelnya jadi hilang sama sekali.
          disabledBackgroundColor: c.sunken,
          disabledForegroundColor: c.inkDim,
          elevation: 0,
          // Size.fromHeight() berarti lebar TAK TERHINGGA. Itu memaksa
          // tombol memenuhi lebar, dan meledak begitu tombolnya ada
          // di dalam Row atau wadah lain yang lebarnya tak dibatasi.
          // Yang dimau cuma tinggi sentuh yang nyaman.
          minimumSize: const Size(0, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rKontrol),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: c.ink,
          side: BorderSide(color: c.lineStrong),
          // Size.fromHeight() berarti lebar TAK TERHINGGA. Itu memaksa
          // tombol memenuhi lebar, dan meledak begitu tombolnya ada
          // di dalam Row atau wadah lain yang lebarnya tak dibatasi.
          // Yang dimau cuma tinggi sentuh yang nyaman.
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rKontrol),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: c.accent,
          textStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          // Tombol utama hijau pekat, warna yang sama dengan bilah
          // aplikasi; hijau lapangan tetap untuk tautan dan ikon.
          backgroundColor: gelap ? c.accent : SportagoColors.pekat,
          foregroundColor: gelap ? c.onAccent : SportagoColors.pure,
          // Size.fromHeight() berarti lebar TAK TERHINGGA. Itu memaksa
          // tombol memenuhi lebar, dan meledak begitu tombolnya ada
          // di dalam Row atau wadah lain yang lebarnya tak dibatasi.
          // Yang dimau cuma tinggi sentuh yang nyaman.
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(rKontrol),
          ),
        ),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: c.raised,
        selectedColor: c.accentSoft,
        side: BorderSide(color: c.lineStrong),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: c.inkSoft,
        ),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.raised,
        selectedItemColor: c.accent,
        unselectedItemColor: c.inkDim,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle:
            GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.raised,
        indicatorColor: c.accentSoft,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.raised,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: c.raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: c.ink,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14.5,
          height: 1.5,
          color: c.inkSoft,
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: SportagoColors.pekat,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: SportagoColors.pure,
          fontWeight: FontWeight.w500,
        ),
        actionTextColor: SportagoColors.volt,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rKontrol),
        ),
      ),

      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.onAccent : c.raised,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.lineStrong,
        ),
      ),

      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) =>
              s.contains(WidgetState.selected) ? c.accent : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(c.onAccent),
        side: BorderSide(color: c.lineStrong, width: 1.5),
      ),

      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? c.accent : c.lineStrong,
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.sunken,
        circularTrackColor: c.sunken,
      ),

      tabBarTheme: TabBarThemeData(
        labelColor: c.ink,
        unselectedLabelColor: c.inkDim,
        indicatorColor: c.accent,
        dividerColor: c.line,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: c.inkSoft,
        textColor: c.ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rKontrol),
        ),
      ),

      iconTheme: IconThemeData(color: c.inkSoft),
      primaryIconTheme: IconThemeData(color: c.ink),
    );
  }

  static ThemeData get light => _bangun(SportagoColors.light, Brightness.light);

  static ThemeData get dark => _bangun(SportagoColors.dark, Brightness.dark);
}
