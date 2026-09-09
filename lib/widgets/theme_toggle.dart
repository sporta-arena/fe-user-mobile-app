import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';
import '../theme/theme_controller.dart';

/// Tombol terang/gelap.
///
/// Dua bentuk: [ThemeToggle] untuk bilah atas (ikon saja), dan
/// [ThemeToggleTile] untuk daftar pengaturan (dengan label).
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final gelap = ThemeController.instance.gelapEfektif(context);
    final label = gelap ? 'Ganti ke tampilan terang' : 'Ganti ke tampilan gelap';

    return IconButton(
      tooltip: label,
      onPressed: () => ThemeController.instance.ganti(context),
      style: IconButton.styleFrom(
        backgroundColor: c.raised,
        foregroundColor: c.inkSoft,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: c.lineStrong),
        ),
      ),
      // Ikonnya berganti dengan pemudaran + putaran kecil: gerakan yang
      // menjawab aksi, bukan hiasan.
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        transitionBuilder: (anak, animasi) => RotationTransition(
          turns: Tween(begin: 0.75, end: 1.0).animate(animasi),
          child: FadeTransition(opacity: animasi, child: anak),
        ),
        child: Icon(
          gelap ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          key: ValueKey(gelap),
          size: 20,
        ),
      ),
    );
  }
}

/// Baris pengaturan dengan tiga pilihan tegas: Sistem / Terang / Gelap.
/// Di halaman pengaturan, pilihan "ikut sistem" perlu bisa dipilih
/// kembali — itu tidak mungkin lewat tombol dua keadaan.
class ThemeToggleTile extends StatelessWidget {
  const ThemeToggleTile({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance,
      builder: (context, mode, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                'Tampilan',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
            ),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('Sistem'),
                  icon: Icon(Icons.brightness_auto_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Terang'),
                  icon: Icon(Icons.light_mode_outlined, size: 18),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Gelap'),
                  icon: Icon(Icons.dark_mode_outlined, size: 18),
                ),
              ],
              selected: {mode},
              showSelectedIcon: false,
              onSelectionChanged: (pilihan) =>
                  ThemeController.instance.setel(pilihan.first),
              style: SegmentedButton.styleFrom(
                backgroundColor: c.raised,
                foregroundColor: c.inkSoft,
                selectedBackgroundColor: c.accentSoft,
                selectedForegroundColor:
                    context.isDark ? c.accent : c.accentHover,
                side: BorderSide(color: c.lineStrong),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(
                mode == ThemeMode.system
                    ? 'Mengikuti setelan perangkat kamu.'
                    : 'Pilihanmu dipakai terus, apa pun setelan perangkat.',
                style: TextStyle(fontSize: 13, color: c.inkDim),
              ),
            ),
          ],
        );
      },
    );
  }
}
