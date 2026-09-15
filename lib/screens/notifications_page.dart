import 'package:flutter/material.dart';

import '../models/notifikasi.dart';
import '../models/tujuan_notifikasi.dart';
import '../services/notifikasi_service.dart';
import '../theme/app_tokens.dart';
import 'my_booking_page.dart';

/// Daftar notifikasi dalam aplikasi.
///
/// Sebelumnya layar ini tidak pernah memanggil apa pun: `_loadNotifications`
/// menunggu setengah detik lalu menetapkan daftar kosong, dengan
/// `// TODO: Implement API call` di atasnya. Ikon lonceng di beranda DAN
/// menu Notifikasi di Profil dua-duanya membuka layar ini, jadi setiap
/// notifikasi yang dikirim server mendarat di daftar yang selamanya
/// kosong, dan tidak ada yang tampak rusak.
///
/// Dua tab "Transaksi" dan "Info & Promo" ikut dihapus: pemisahannya
/// dulu memakai `n['type'] == 'transaction'` pada data yang tidak pernah
/// ada, dan sampai ada notifikasi promo yang benar-benar dikirim, tab
/// kedua hanya menjanjikan isi yang tidak pernah datang.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  List<Notifikasi> _daftar = [];
  bool _sedangMuat = true;

  /// Dibedakan dari daftar kosong: "gagal memuat" mengajak mencoba lagi,
  /// "belum ada notifikasi" tidak.
  bool _gagalMuat = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _sedangMuat = true;
      _gagalMuat = false;
    });

    final hasil = await NotifikasiService.ambil();
    if (!mounted) return;

    setState(() {
      _sedangMuat = false;
      if (hasil == null) {
        _gagalMuat = true;
      } else {
        _daftar = hasil.daftar;
      }
    });
  }

  Future<void> _tandaiSemua() async {
    final berhasil = await NotifikasiService.tandaiSemuaDibaca();
    if (!mounted) return;
    if (berhasil) {
      await _muat();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gagal menandai notifikasi. Coba lagi.')),
    );
  }

  Future<void> _buka(Notifikasi n) async {
    if (!n.sudahDibaca) {
      // Hasilnya tidak ditunggu: gagal menandai dibaca tidak boleh
      // menghalangi orang membuka notifikasinya.
      NotifikasiService.tandaiDibaca(n.id).then((_) {
        if (mounted) _muat();
      });
      setState(() {
        _daftar = _daftar
            .map((e) => e.id == n.id ? _salinanDibaca(e) : e)
            .toList();
      });
    }

    if (tujuanDariTautan(n.tautan) == TujuanNotifikasi.bookingSaya) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const MyBookingPage(showBackButton: true),
        ),
      );
    }
  }

  Notifikasi _salinanDibaca(Notifikasi n) => Notifikasi(
        id: n.id,
        judul: n.judul,
        isi: n.isi,
        tautan: n.tautan,
        jenis: n.jenis,
        sudahDibaca: true,
        dibuatPada: n.dibuatPada,
      );

  @override
  Widget build(BuildContext context) {
    final adaBelumDibaca = _daftar.any((n) => !n.sudahDibaca);

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: Text('Notifikasi',
            style:
                TextStyle(color: context.c.ink, fontWeight: FontWeight.bold)),
        backgroundColor: context.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: adaBelumDibaca ? _tandaiSemua : null,
            child: Text(
              'Tandai Dibaca',
              style: TextStyle(
                color: adaBelumDibaca ? context.c.accent : context.c.inkDim,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        color: context.c.accent,
        child: _isi(),
      ),
    );
  }

  Widget _isi() {
    if (_sedangMuat) {
      return Center(child: CircularProgressIndicator(color: context.c.accent));
    }
    if (_gagalMuat) {
      return _keadaanKosong(
        ikon: Icons.cloud_off_rounded,
        judul: 'Gagal memuat notifikasi',
        isi: 'Periksa koneksi kamu, lalu tarik layar ini ke bawah.',
      );
    }
    if (_daftar.isEmpty) {
      return _keadaanKosong(
        ikon: Icons.notifications_none_rounded,
        judul: 'Belum ada notifikasi',
        isi: 'Kabar soal booking dan pesan dari pengelola lapangan muncul di sini.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _daftar.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: context.c.line),
      itemBuilder: (context, i) => _kartu(_daftar[i]),
    );
  }

  Widget _kartu(Notifikasi n) {
    final bisaDibuka = tujuanDariTautan(n.tautan) != TujuanNotifikasi.tidakAda;

    return ListTile(
      onTap: () => _buka(n),
      tileColor:
          n.sudahDibaca ? context.c.surface : context.c.accentSoft,
      leading: CircleAvatar(
        backgroundColor: context.c.accentSoft,
        child: Icon(
          n.sudahDibaca
              ? Icons.notifications_none_rounded
              : Icons.notifications_active_rounded,
          color: context.c.accent,
          size: 20,
        ),
      ),
      title: Text(
        n.judul,
        style: TextStyle(
          color: context.c.ink,
          fontWeight: n.sudahDibaca ? FontWeight.w500 : FontWeight.w700,
          fontSize: 15,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (n.isi.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(n.isi,
                style: TextStyle(color: context.c.inkSoft, fontSize: 13)),
          ],
          const SizedBox(height: 6),
          Text(_waktuSingkat(n.dibuatPada),
              style: TextStyle(color: context.c.inkDim, fontSize: 11)),
        ],
      ),
      // Tanda panah hanya untuk yang benar-benar mengantar ke suatu
      // tempat, supaya tidak ada yang menekan lalu tidak terjadi apa-apa.
      trailing: bisaDibuka
          ? Icon(Icons.chevron_right, color: context.c.inkDim)
          : null,
    );
  }

  Widget _keadaanKosong({
    required IconData ikon,
    required String judul,
    required String isi,
  }) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 120),
        Icon(ikon, size: 64, color: context.c.inkDim),
        const SizedBox(height: 20),
        Center(
          child: Text(judul,
              style: TextStyle(
                  color: context.c.ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 48),
          child: Text(isi,
              textAlign: TextAlign.center,
              style: TextStyle(color: context.c.inkSoft, fontSize: 13)),
        ),
      ],
    );
  }

  String _waktuSingkat(DateTime waktu) {
    final selisih = DateTime.now().difference(waktu);
    if (selisih.inMinutes < 1) return 'Baru saja';
    if (selisih.inMinutes < 60) return '${selisih.inMinutes} menit lalu';
    if (selisih.inHours < 24) return '${selisih.inHours} jam lalu';
    if (selisih.inDays < 7) return '${selisih.inDays} hari lalu';
    return '${waktu.day}/${waktu.month}/${waktu.year}';
  }
}
