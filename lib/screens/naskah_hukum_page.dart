import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../theme/app_tokens.dart';

/// Pembaca naskah hukum, hanya untuk dibaca.
///
/// Sebelumnya tautan "Syarat & Ketentuan" dan "Kebijakan Privasi" di
/// layar daftar tidak melakukan apa pun saat disentuh, padahal di
/// sebelahnya tertulis "Saya menyetujui". Meminta orang menyetujui
/// naskah yang tidak bisa dibukanya adalah persetujuan yang tidak
/// berarti apa-apa, dan tidak akan berdiri sebagai bukti kalau suatu
/// saat dipersoalkan.
///
/// Dibuka di dalam aplikasi, bukan dilempar ke browser: mengeluarkan
/// orang dari layar pendaftaran di tengah jalan adalah cara paling
/// mudah kehilangan mereka.
class NaskahHukumPage extends StatefulWidget {
  const NaskahHukumPage({
    super.key,
    required this.slug,
    required this.judul,
  });

  /// `partner-terms` atau `privacy`, sama dengan yang dipakai server.
  final String slug;
  final String judul;

  @override
  State<NaskahHukumPage> createState() => _NaskahHukumPageState();
}

class _NaskahHukumPageState extends State<NaskahHukumPage> {
  String? _isi;
  String? _versi;
  bool _memuat = true;
  bool _gagal = false;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _gagal = false;
    });

    try {
      final respons = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/legal/${widget.slug}'),
        headers: const {'Accept': 'application/json'},
      );

      if (!mounted) return;

      if (respons.statusCode != 200) {
        setState(() {
          _memuat = false;
          _gagal = true;
        });

        return;
      }

      final isi = jsonDecode(respons.body);
      final data = (isi['data'] ?? isi) as Map<String, dynamic>;

      setState(() {
        _isi = data['body'] as String?;
        _versi = data['version'] as String?;
        _memuat = false;
        _gagal = _isi == null || _isi!.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
        _gagal = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        title: Text(widget.judul),
        backgroundColor: context.c.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(child: _badan()),
    );
  }

  Widget _badan() {
    if (_memuat) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_gagal) {
      // Naskah yang gagal dimuat tidak diganti teks cadangan: yang
      // ditampilkan harus benar-benar naskah yang berlaku, bukan
      // salinan lama yang kebetulan ada di aplikasi.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: context.c.inkDim),
              const SizedBox(height: 12),
              Text(
                'Naskah gagal dimuat. Periksa sambungan internet Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.c.inkSoft),
              ),
              const SizedBox(height: 12),
              TextButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_versi != null) ...[
            Text(
              'Versi $_versi',
              style: TextStyle(fontSize: 12, color: context.c.inkDim),
            ),
            const SizedBox(height: 14),
          ],
          HtmlWidget(
            _isi!,
            textStyle: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: context.c.ink,
            ),
          ),
        ],
      ),
    );
  }
}
