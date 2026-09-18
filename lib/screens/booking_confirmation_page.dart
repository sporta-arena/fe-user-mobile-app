import 'dart:math' as math;
import 'dart:ui' show FontFeature;
import 'dart:async';
import '../utils/waktu_wib.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'keterangan_biaya.dart';
import '../services/promo_service.dart';
import '../theme/app_tokens.dart';
import '../widgets/sampul_venue.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/payment_method_service.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'e_ticket_page.dart';
import '../utils/sisipan_bawah.dart';

class BookingConfirmationPage extends StatefulWidget {
  final int fieldId;
  final String venueName;
  final String venueAddress;
  final String fieldName;

  /// Foto sampul venue, kalau mitranya sudah mengunggah.
  final String? venueImageUrl;

  /// Jenis lapangan, dipakai memilih ikon pengganti foto.
  final String? fieldType;
  final String selectedDate; // Format: YYYY-MM-DD
  final List<String> selectedTimeSlots; // Changed to List
  final int price;

  const BookingConfirmationPage({
    super.key,
    required this.fieldId,
    required this.venueName,
    // Dulu alamat ini punya nilai bawaan "Jl. Sudirman No. 123, Jakarta
    // Selatan". Alamat karangan pada layar yang dipakai orang untuk
    // memastikan mau ke mana adalah kesalahan yang mahal.
    required this.venueAddress,
    required this.fieldName,
    this.venueImageUrl,
    this.fieldType,
    required this.selectedDate,
    required this.selectedTimeSlots,
    required this.price,
  });

  @override
  State<BookingConfirmationPage> createState() =>
      _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  // Controllers untuk form input
  final TextEditingController _notesController = TextEditingController();

  // State
  bool _isLoading = false;
  String _selectedPaymentMethod = "QRIS";
  bool _refundPolicyAccepted =
      false; // State untuk acknowledgment refund policy

  /// Kode promo yang sudah lolos pemeriksaan server, kalau ada.
  HasilPromo? _promo;
  int _potongan = 0;
  final _promoController = TextEditingController();
  String? _promoGalat;
  bool _memeriksaPromo = false;

  // Tarif biaya: HARUS sama dengan backend (BookingService::PLATFORM_FEE_RATE
  // dan PLATFORM_FEE_CAP di be-main). Sebelumnya di sini 5% tanpa batas,
  // sementara server memakai 8% dengan batas Rp 20.000: layar ini
  // menampilkan total yang berbeda dari yang benar-benar ditagihkan,
  // kurang Rp 3.056 pada booking Rp 100.000, dan lebih Rp 17.360 pada
  // booking Rp 750.000.
  static const double _platformFeePercent = 0.08;
  static const int _platformFeeCap = 20000;

  // Payment method data with fees
  /// Metode pembayaran, diisi dari server saat layar dibuka.
  ///
  /// Dulu daftar ini ditulis keras di sini bersama salinan biayanya.
  /// Isinya tiga belas metode padahal backend hanya bisa membuat lima:
  /// lima Virtual Account belum ada kodenya, LinkAja belum punya biaya,
  /// dan Alfamart serta Indomaret bahkan tidak dikenal backend. Pelanggan
  /// bisa memilih jalan buntu, dan biaya yang tampil tidak dijamin sama
  /// dengan yang ditagih.
  List<Map<String, dynamic>> _paymentMethods = [];
  bool _memuatMetode = true;
  String? _galatMetode;

  /// Muat ulang daftar metode beserta biayanya.
  ///
  /// WAJIB dipanggil lagi setiap potongan berubah. `serverFee` dihitung
  /// server dari `jumlah` yang dikirim saat daftar ini diminta, jadi
  /// begitu promo dipakai angkanya jadi milik harga yang lama: layar
  /// menampilkan biaya admin dari 162.000 sementara server menagih dari
  /// 140.400. Selisihnya kecil, tapi akibatnya totalnya berubah sendiri
  /// setelah pemesan menekan Bayar — hal yang paling tidak boleh terjadi
  /// di layar ini.
  Future<void> _muatMetodePembayaran() async {
    setState(() {
      _memuatMetode = true;
      _galatMetode = null;
    });
    try {
      final daftar = await PaymentMethodService.ambil(
        jumlah: _fieldPrice + _platformFee,
        idLapangan: widget.fieldId,
      );
      if (!mounted) return;
      setState(() {
        _paymentMethods = daftar
            .map(
              (m) => <String, dynamic>{
                'id': m.kode.toUpperCase(),
                'title': m.label,
                'subtitle': m.keterangan,
                'kategori': m.kategori,
                // Biaya dari server, bukan dihitung ulang di sini.
                'serverFee': m.biaya,
                'feeType': m.jenisBiaya == 'percentage' ? 'percent' : 'flat',
                'feeValue': m.jenisBiaya == 'percentage'
                    ? m.nilaiBiaya / 100
                    : m.nilaiBiaya,
                'icon': m.ikon,
              },
            )
            .toList();
        if (_paymentMethods.isNotEmpty &&
            !_paymentMethods.any((m) => m['id'] == _selectedPaymentMethod)) {
          _selectedPaymentMethod = _paymentMethods.first['id'] as String;
        }
        _memuatMetode = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _galatMetode = e.toString().replaceFirst('Exception: ', '');
        _memuatMetode = false;
      });
    }
  }

  // Duration is calculated from selected time slots
  int get _durationHours => widget.selectedTimeSlots.length;

  @override
  void dispose() {
    _notesController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  // Get selected payment method data
  @override
  void initState() {
    super.initState();
    _muatMetodePembayaran();
  }

  /// Nilai sementara selagi daftar metode dari server belum termuat.
  ///
  /// Layar ini membaca 'icon', 'title', 'subtitle', dan 'feeValue' dengan
  /// cast langsung di enam tempat. Sebelumnya getter di bawah
  /// mengembalikan map KOSONG saat daftarnya belum ada, sehingga
  /// `null as IconData` melempar dan layarnya merah selama beberapa saat
  /// sampai jawaban server datang.
  ///
  /// Bukan data karangan: QRIS memang selalu tersedia dan tarifnya sudah
  /// ditetapkan Bank Indonesia, jadi angkanya benar walau server belum
  /// menjawab. Begitu daftar aslinya masuk, map ini tidak dipakai lagi.
  static const Map<String, dynamic> _metodeSementara = {
    'id': 'QRIS',
    'title': 'QRIS',
    'subtitle': 'Scan QR via e-wallet atau m-banking',
    'kategori': 'qris',
    'feeType': 'percent',
    'feeValue': 0.007,
    'icon': Icons.qr_code_2,
  };

  Map<String, dynamic> get _selectedPaymentData {
    if (_paymentMethods.isEmpty) return _metodeSementara;
    return _paymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethod,
      orElse: () => _paymentMethods.first,
    );
  }

  /// Nilai biaya apa adanya, tanpa memaksakan tipe.
  ///
  /// Server mengirim `fee_value` sebagai angka biasa: 0.7 untuk
  /// persentase, 4000 untuk flat. JSON tidak membedakan int dan double,
  /// jadi membacanya lewat `num` adalah satu-satunya cara yang tidak
  /// bergantung pada kebetulan.
  static double _nilaiBiaya(Map<String, dynamic> method) {
    final nilai = method['feeValue'];
    return nilai is num ? nilai.toDouble() : 0;
  }

  // Calculate payment gateway fee based on selected method
  int get _paymentGatewayFee {
    final method = _selectedPaymentData;
    // Angka dari server adalah yang benar-benar akan ditagih; hitungan
    // di bawah hanya cadangan kalau daftarnya belum sempat termuat.
    final dariServer = method['serverFee'];
    if (dariServer is int) return dariServer;
    if (method['feeType'] == 'percent') {
      // Dasarnya (harga lapangan + platform fee), sama seperti
      // BookingService di backend: bukan harga lapangan saja.
      return ((_fieldPrice + _platformFee) * _nilaiBiaya(method)).round();
    } else {
      // Metode biaya flat (Virtual Account) baru ada sejak VA
      // terpasang, jadi cabang ini tidak pernah tereksekusi sebelumnya
      // dan `as int`-nya lolos begitu saja. `fee_value` dibaca sebagai
      // double di PaymentMethodService, jadi cast itu langsung meledak
      // "type 'double' is not a subtype of type 'int'".
      return _nilaiBiaya(method).round();
    }
  }

  // Get fee label for display
  String get _paymentGatewayFeeLabel {
    final method = _selectedPaymentData;
    if (method['feeType'] == 'percent') {
      final percent = (_nilaiBiaya(method) * 100).toStringAsFixed(1);
      return "Biaya Admin ($percent%)";
    } else {
      return "Biaya Admin";
    }
  }

  /// Label biaya platform, mengikuti tarif yang benar-benar dipakai.
  ///
  /// Dulu tertulis mati "(5%)", dua kali salah: tarifnya 8%, dan pada
  /// booking besar biayanya kena batas Rp 20.000 sehingga persentase apa
  /// pun jadi menyesatkan. Contoh: 2 jam x Rp 180.000 menampilkan
  /// "(5%)" di sebelah angka Rp 20.000, padahal 5% dari 360.000 adalah
  /// Rp 18.000.
  String get _labelBiayaPlatform {
    final penuh = (_fieldPrice * _platformFeePercent).round();
    if (penuh > _platformFeeCap) {
      return 'Biaya Platform (maks ${_formatCurrency(_platformFeeCap)})';
    }
    final persen = (_platformFeePercent * 100).toStringAsFixed(0);
    return 'Biaya Platform ($persen%)';
  }

  // Calculate prices
  //
  // `_hargaLapangan` harga kotor; `_fieldPrice` subtotal SESUDAH
  // potongan promo. Semua turunannya — biaya platform, biaya gateway,
  // total — membaca `_fieldPrice`, jadi urutan hitungnya sama persis
  // dengan server: potongan dulu, baru 8% dari sisanya. Kalau app
  // menghitung dari harga kotor, angka di layar berbeda dari yang
  // ditagih dan pemesan melihat totalnya berubah sendiri setelah bayar.
  int get _hargaLapangan => widget.price * _durationHours;
  int get _fieldPrice => math.max(0, _hargaLapangan - _potongan);
  int get _platformFee =>
      math.min((_fieldPrice * _platformFeePercent).round(), _platformFeeCap);
  int get _totalPrice => _fieldPrice + _platformFee + _paymentGatewayFee;

  Future<void> _terapkanPromo() async {
    final kode = _promoController.text.trim();
    if (kode.isEmpty) return;

    setState(() {
      _memeriksaPromo = true;
      _promoGalat = null;
    });

    try {
      final hasil = await PromoService.cek(
        kode: kode,
        fieldId: widget.fieldId,
        tanggal: widget.selectedDate,
        jamMulai: widget.selectedTimeSlots.first,
        durasiJam: _durationHours,
      );
      if (!mounted) return;
      setState(() {
        _promo = hasil;
        _potongan = hasil.potongan.round();
        _promoGalat = null;
      });
      // Biaya gateway dihitung dari jumlah sesudah potongan.
      await _muatMetodePembayaran();
    } on PromoDitolak catch (e) {
      if (!mounted) return;
      setState(() {
        _promo = null;
        _potongan = 0;
        _promoGalat = e.pesan;
      });
    } finally {
      if (mounted) setState(() => _memeriksaPromo = false);
    }
  }

  Future<void> _lepasPromo() async {
    setState(() {
      _promo = null;
      _potongan = 0;
      _promoGalat = null;
      _promoController.clear();
    });
    await _muatMetodePembayaran();
  }

  /// Kolom kode promo.
  ///
  /// Kodenya diperiksa ke server sebelum menekan Bayar supaya
  /// potongannya terlihat di rincian biaya lebih dulu. Tanpa itu pemesan
  /// baru tahu kodenya ditolak setelah pemesanannya gagal seluruhnya —
  /// bukan cuma promonya.
  Widget _kolomPromo() {
    if (_promo != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.c.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.c.accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.local_offer_rounded, color: context.c.accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _promo!.kode,
                    style: TextStyle(
                      color: context.c.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_promo!.judul.isNotEmpty)
                    Text(
                      _promo!.judul,
                      style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                    ),
                ],
              ),
            ),
            TextButton(
              onPressed: _lepasPromo,
              child: Text(
                'Lepas',
                style: TextStyle(
                  color: context.c.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.c.raised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _promoGalat != null
                        ? context.c.danger
                        : context.c.line,
                  ),
                ),
                child: TextField(
                  controller: _promoController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(color: context.c.ink),
                  onSubmitted: (_) => _terapkanPromo(),
                  decoration: InputDecoration(
                    hintText: 'Punya kode promo?',
                    hintStyle: TextStyle(color: context.c.inkDim, fontSize: 14),
                    prefixIcon: Icon(
                      Icons.local_offer_outlined,
                      color: context.c.inkDim,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _memeriksaPromo ? null : _terapkanPromo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.accent,
                  foregroundColor: context.c.onAccent,
                  minimumSize: const Size(88, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _memeriksaPromo
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.c.onAccent,
                        ),
                      )
                    : const Text(
                        'Pakai',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
        if (_promoGalat != null) ...[
          const SizedBox(height: 8),
          Text(
            _promoGalat!,
            style: TextStyle(color: context.c.danger, fontSize: 12.5),
          ),
        ],
      ],
    );
  }

  void _showPaymentMethodSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: context.c.raised,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Pilih Metode Pembayaran",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Biaya admin bervariasi per metode",
                style: TextStyle(color: context.c.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 0, 16, context.sisipanBawah),
                  children: [
                    if (_memuatMetode)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_galatMetode != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            Text(
                              _galatMetode!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: context.c.inkSoft),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _muatMetodePembayaran,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Coba lagi'),
                            ),
                          ],
                        ),
                      )
                    else
                    // Seksi mengikuti kategori yang dikirim server.
                    // Kategori yang belum punya metode tidak digambar,
                    // jadi judul kosong tidak pernah muncul.
                    ...[
                      for (final k in const [
                        ('qris', 'QRIS', Icons.qr_code_2),
                        ('ewallet', 'E-Wallet', Icons.account_balance_wallet),
                        ('va', 'Virtual Account', Icons.account_balance),
                      ])
                        if (_paymentMethods.any(
                          (m) => m['kategori'] == k.$1,
                        )) ...[
                          _buildSectionHeader(k.$2, k.$3),
                          ..._paymentMethods
                              .where((m) => m['kategori'] == k.$1)
                              .map(_buildPaymentOption),
                          const SizedBox(height: 16),
                        ],
                    ],

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: context.c.accent),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: context.c.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];
    final feeText = _getFeeText(method);

    return InkWell(
      onTap: () {
        setState(() => _selectedPaymentMethod = method['id'] as String);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? context.c.accent.withValues(alpha: 0.15)
              : context.c.raised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.c.accent : context.c.line,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.c.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                method['icon'] as IconData,
                color: context.c.inkSoft,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method['title'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method['subtitle'] as String,
                    style: TextStyle(color: context.c.inkSoft, fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isSelected)
                  Icon(Icons.check_circle, color: context.c.accent, size: 20)
                else
                  Icon(Icons.circle_outlined, color: context.c.line, size: 20),
                const SizedBox(height: 4),
                Text(
                  feeText,
                  style: TextStyle(
                    color: context.c.inkSoft,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getFeeText(Map<String, dynamic> method) {
    if (method['feeType'] == 'percent') {
      final percent = (_nilaiBiaya(method) * 100).toStringAsFixed(1);
      return "Biaya $percent%";
    } else {
      return "Biaya ${_formatCurrency(_nilaiBiaya(method).round())}";
    }
  }

  Future<void> _createBooking() async {
    // Check if logged in
    if (AuthService.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Silakan login terlebih dahulu"),
          backgroundColor: context.c.danger,
        ),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await BookingService.createBooking(
        fieldId: widget.fieldId,
        bookingDate: widget.selectedDate,
        startTime: widget.selectedTimeSlots.first,
        durationHours: _durationHours,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        paymentMethod: _selectedPaymentMethod,
        promoCode: _promo?.kode,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        if (result.success && result.booking != null) {
          // Navigate to payment waiting page with booking data
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => BookingCreatedPage(
                booking: result.booking!,
                payment: result.payment,
                basePrice: _fieldPrice,
                platformFee: _platformFee,
                adminFee: _paymentGatewayFee,
                totalPrice: _totalPrice,
                paymentMethod: _selectedPaymentMethod,
                paymentMethodLabel: _selectedPaymentData['title'] as String,
              ),
            ),
          );
        } else {
          // Show error
          String errorMessage = result.message ?? 'Gagal membuat booking';
          if (result.errors != null) {
            final errors = result.errors!.values.expand((e) => e).join('\n');
            errorMessage = '$errorMessage\n$errors';
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: context.c.danger,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: context.c.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.c.accent),
                  SizedBox(height: 16),
                  Text(
                    'Membuat booking...',
                    style: TextStyle(color: context.c.ink),
                  ),
                ],
              ),
            )
          : AnnotatedRegion<SystemUiOverlayStyle>(
              value: gayaOverlay(context),
              child: SafeArea(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Padding(
                    // Sisi bawah 24, bukan 100. Angka 100 dulu dipasang
                    // untuk menghindari bilah "Bayar Sekarang", padahal
                    // bilah itu bottomNavigationBar milik Scaffold, yang
                    // ruangnya sudah disisihkan di luar badan layar. Jadi
                    // yang tersisa cuma ruang kosong sejauh satu bilah
                    // penuh di bawah centang persetujuan.
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- HEADER ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Icon(
                                Icons.arrow_back,
                                size: 24,
                                color: context.c.ink,
                              ),
                            ),
                            Text(
                              "Konfirmasi Booking",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: context.c.ink,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showOptionsBottomSheet,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: context.c.raised,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: context.c.line),
                                ),
                                child: Icon(
                                  Icons.more_horiz,
                                  size: 20,
                                  color: context.c.ink,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- VENUE INFO CARD ---
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Sampul venue.
                            //
                            // Dulu di sini terpasang satu foto rumput dari
                            // Unsplash, sama untuk venue mana pun, bahkan
                            // untuk lapangan badminton dalam ruangan.
                            SampulVenue(
                              nama: widget.venueName,
                              urlGambar: widget.venueImageUrl,
                              olahraga: widget.fieldType,
                              lebar: 80,
                              tinggi: 80,
                              ukuranInisial: 22,
                              radius: BorderRadius.circular(12),
                            ),
                            const SizedBox(width: 16),
                            // Venue Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          widget.venueName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: context.c.ink,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        color: context.c.inkSoft,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          widget.venueAddress,
                                          style: TextStyle(
                                            color: context.c.inkSoft,
                                            fontSize: 12,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: _formatCurrency(widget.price),
                                          style: TextStyle(
                                            color: context.c.accent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        TextSpan(
                                          text: " /jam",
                                          style: TextStyle(
                                            color: context.c.inkSoft,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // --- TANGGAL ---
                        Text(
                          "Tanggal Booking",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.c.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: context.c.raised,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.c.line),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 18,
                                color: context.c.inkSoft,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                widget.selectedDate,
                                style: TextStyle(
                                  color: context.c.ink,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // --- JAM TERPILIH ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Jam Terpilih",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.c.ink,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.c.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${_durationHours} jam",
                                style: TextStyle(
                                  color: context.c.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.selectedTimeSlots.map((slot) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.c.accent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                // `slot` menyimpan nilai mentah dari API
                                // (UTC) karena itu yang dikirim balik saat
                                // membuat booking. Yang digeser ke WIB
                                // hanya labelnya.
                                WaktuWib.tampil(slot),
                                style: TextStyle(
                                  color: context.c.onAccent,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),
                        Divider(color: context.c.line),
                        const SizedBox(height: 24),

                        // --- PAYMENT INFORMATION ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Informasi Pembayaran",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.c.ink,
                              ),
                            ),
                            GestureDetector(
                              onTap: _showPaymentMethodSheet,
                              child: Text(
                                "Ubah",
                                style: TextStyle(
                                  color: context.c.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: _showPaymentMethodSheet,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: context.c.raised,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.c.line),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: context.c.surface,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _selectedPaymentData['icon'] as IconData,
                                    color: context.c.accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _selectedPaymentData['title'] as String,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: context.c.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _selectedPaymentData['subtitle']
                                            as String,
                                        style: TextStyle(
                                          color: context.c.inkSoft,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: context.c.inkSoft,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Payment gateway fee info
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.c.raised,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: context.c.line),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: context.c.accent,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.c.inkSoft,
                                    ),
                                    children: [
                                      const TextSpan(
                                        text: 'Biaya admin payment gateway: ',
                                      ),
                                      TextSpan(
                                        text: _formatCurrency(
                                          _paymentGatewayFee,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: keteranganBiayaGateway(
                                          tipeBiaya:
                                              _selectedPaymentData['feeType']
                                                  as String?,
                                          nilai: _nilaiBiaya(
                                            _selectedPaymentData,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // --- CATATAN ---
                        Text(
                          "Catatan (Opsional)",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: context.c.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: context.c.raised,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: context.c.line),
                          ),
                          child: TextField(
                            controller: _notesController,
                            style: TextStyle(color: context.c.ink),
                            decoration: InputDecoration(
                              hintText: "Tambahkan catatan...",
                              hintStyle: TextStyle(
                                color: context.c.inkSoft,
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: context.c.raised,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            maxLines: 2,
                          ),
                        ),

                        const SizedBox(height: 24),
                        Divider(color: context.c.line),
                        const SizedBox(height: 24),

                        // Kolom promo tepat di atas rincian biaya, bukan
                        // di dekat catatan: potongannya muncul sebagai
                        // baris di rincian di bawahnya, jadi sebab dan
                        // akibatnya terbaca dalam satu tarikan mata.
                        _kolomPromo(),
                        const SizedBox(height: 24),

                        // --- SUMMARY OF CHARGE ---
                        Text(
                          "Rincian Biaya",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: context.c.ink,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSummaryRow(
                          "Harga Lapangan (${widget.fieldName})",
                          _formatCurrency(_hargaLapangan),
                        ),
                        if (_potongan > 0) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'Potongan ${_promo?.kode ?? ""}'.trim(),
                                  style: TextStyle(
                                    color: context.c.accent,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Text(
                                '-${_formatCurrency(_potongan)}',
                                style: TextStyle(
                                  color: context.c.accent,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                          _labelBiayaPlatform,
                          _formatCurrency(_platformFee),
                        ),
                        const SizedBox(height: 10),
                        _buildSummaryRow(
                          _paymentGatewayFeeLabel,
                          _formatCurrency(_paymentGatewayFee),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: context.c.line),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Pembayaran",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: context.c.ink,
                              ),
                            ),
                            Text(
                              _formatCurrency(_totalPrice),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: context.c.accent,
                              ),
                            ),
                          ],
                        ),

                        // --- REFUND POLICY INFO ---
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.c.warn.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: context.c.warn.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                color: context.c.warn,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Tidak Ada Pengembalian Dana",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: context.c.warn,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      // Sportago tidak punya jalur refund: tidak ada
                                      // tombolnya di sisi pemesan, dan tidak ada di sisi
                                      // mitra. Menuliskannya terus terang di sini, di atas
                                      // centang persetujuan, supaya keputusan membayar
                                      // diambil dengan tahu itu. Teks lama menjanjikan
                                      // harga lapangan kembali — janji yang tidak ada yang
                                      // bisa menepatinya.
                                      "Pembayaran yang sudah berhasil tidak dapat dikembalikan, termasuk jika kamu batal datang. Pastikan tanggal, jam, dan lapangan sudah benar sebelum membayar.",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: context.c.inkSoft,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // --- REFUND POLICY CHECKBOX ---
                        const SizedBox(height: 12),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _refundPolicyAccepted = !_refundPolicyAccepted;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: Checkbox(
                                    value: _refundPolicyAccepted,
                                    onChanged: (value) {
                                      setState(() {
                                        _refundPolicyAccepted = value ?? false;
                                      });
                                    },
                                    activeColor: context.c.accent,
                                    checkColor: context.c.onAccent,
                                    side: BorderSide(
                                      color: context.c.line,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Saya mengerti pembayaran ini tidak bisa dikembalikan",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: context.c.inkSoft,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

      // --- BOTTOM BAR ---
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.c.raised,
          border: Border(top: BorderSide(color: context.c.line)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Warning jika belum centang
              if (!_refundPolicyAccepted)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.c.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: context.c.danger,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Centang dulu pernyataan di atas untuk melanjutkan",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.c.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_refundPolicyAccepted)
                      ? null
                      : _createBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    disabledBackgroundColor: context.c.line,
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: context.c.onAccent,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          "Bayar Sekarang",
                          style: TextStyle(
                            color: context.c.onAccent,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.c.inkSoft, fontSize: 14),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: context.c.ink,
          ),
        ),
      ],
    );
  }

  void _showOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        // Lembarnya menempel ke tepi bawah layar, jadi baris terakhir
        // ("Batalkan") jatuh tepat di belakang bilah navigasi. Sisipan
        // dipasang sebagai padding di dalam, bukan SafeArea di luar,
        // supaya latar putihnya tetap penuh sampai tepi dan tidak
        // menyisakan celah tembus ke layar di belakangnya.
        padding: EdgeInsets.only(bottom: context.sisipanBawah),
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.c.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Opsi Lainnya',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.c.ink,
              ),
            ),
            const SizedBox(height: 20),
            _buildOptionItem(
              icon: Icons.help_outline_rounded,
              iconColor: context.c.accent,
              iconBgColor: context.c.accent.withValues(alpha: 0.15),
              title: 'Bantuan',
              subtitle: 'Panduan cara booking',
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog();
              },
            ),
            _buildOptionItem(
              icon: Icons.article_outlined,
              iconColor: context.c.warn,
              iconBgColor: context.c.warn.withValues(alpha: 0.1),
              title: 'Syarat & Ketentuan',
              subtitle: 'Kebijakan pemesanan',
              onTap: () {
                Navigator.pop(context);
                _showTermsDialog();
              },
            ),
            _buildOptionItem(
              icon: Icons.share_rounded,
              iconColor: context.c.ok,
              iconBgColor: context.c.ok.withValues(alpha: 0.1),
              title: 'Bagikan',
              subtitle: 'Bagikan info booking',
              onTap: () {
                Navigator.pop(context);
                _shareBookingInfo();
              },
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: context.c.line),
            ),
            _buildOptionItem(
              icon: Icons.close_rounded,
              iconColor: context.c.danger,
              iconBgColor: context.c.danger.withValues(alpha: 0.1),
              title: 'Batalkan',
              subtitle: 'Batal dan kembali',
              onTap: () {
                Navigator.pop(context);
                _showCancelConfirmation();
              },
              isDestructive: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isDestructive ? context.c.danger : context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: context.c.inkSoft, size: 20),
          ],
        ),
      ),
    );
  }

  void _showCancelConfirmation() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: context.c.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.c.dangerSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: context.c.danger,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Batalkan Booking?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Apakah kamu yakin ingin membatalkan proses booking ini? Data yang sudah diisi tidak akan tersimpan.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.inkSoft,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: context.c.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Tidak',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.c.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back from booking page
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.c.danger,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Ya, Batalkan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => Column(
            children: [
              // Handle Bar
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.c.line,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.c.accent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.support_agent_rounded,
                        color: context.c.onAccent,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pusat Bantuan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: context.c.ink,
                            ),
                          ),
                          Text(
                            'Kami siap membantu kamu',
                            style: TextStyle(
                              fontSize: 13,
                              color: context.c.inkSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.c.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: context.c.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Divider(height: 1, color: context.c.line),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    24,
                    24,
                    24 + context.sisipanBawah,
                  ),
                  children: [
                    // Cara Booking Section
                    _buildHelpSection(
                      icon: Icons.menu_book_rounded,
                      iconColor: context.c.accent,
                      title: 'Cara Booking',
                      child: Column(
                        children: [
                          _buildHelpStep(
                            1,
                            'Pastikan data booking sudah benar',
                            Icons.fact_check_outlined,
                          ),
                          _buildHelpStep(
                            2,
                            'Pilih metode pembayaran yang tersedia',
                            Icons.payment_outlined,
                          ),
                          _buildHelpStep(
                            3,
                            'Klik tombol "Bayar Sekarang"',
                            Icons.touch_app_outlined,
                          ),
                          // 10, bukan 15. config/payment.php menahan
                          // slot 10 menit untuk SEMUA metode (qris,
                          // ewallet, va, card), dan Syarat & Ketentuan di
                          // layar yang sama sudah menulis 10 sejak
                          // dicocokkan ke backend. Dua angka berbeda di
                          // satu layar, dan yang ini yang salah.
                          _buildHelpStep(
                            4,
                            'Selesaikan pembayaran dalam 10 menit',
                            Icons.timer_outlined,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // FAQ Section
                    _buildHelpSection(
                      icon: Icons.quiz_outlined,
                      iconColor: context.c.warn,
                      title: 'FAQ',
                      child: Column(
                        children: [
                          _buildFaqItem(
                            'Bagaimana jika pembayaran gagal?',
                            'Silakan ulangi proses pembayaran atau pilih metode pembayaran lain.',
                          ),
                          // Butir "Apakah bisa reschedule?" dibuang. Kata
                          // "reschedule" tidak muncul di mana pun di app
                          // ini selain pada jawabannya sendiri: fiturnya
                          // memang belum ada, jadi yang dijanjikan
                          // adalah sesuatu yang tidak bisa ditepati.
                          _buildFaqItem(
                            'Bagaimana cara membatalkan booking?',
                            'Pembatalan hanya bisa dilakukan selama pemesanan '
                                'belum dibayar, lewat halaman "Pesanan Saya". '
                                'Kalau dibiarkan, pemesanan yang belum dibayar batal '
                                'sendiri setelah 10 menit.',
                          ),
                          _buildFaqItem(
                            'Uang saya bisa kembali kalau batal datang?',
                            'Tidak. Pembayaran yang sudah berhasil tidak '
                                'dikembalikan, jadi pastikan jadwalnya sudah pasti '
                                'sebelum membayar.',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Contact Section
                    _buildHelpSection(
                      icon: Icons.headset_mic_rounded,
                      iconColor: context.c.ok,
                      title: 'Hubungi Kami',
                      child: Column(
                        children: [
                          // Tinggal satu, dan yang ini benar-benar ada.
                          //
                          // Sebelumnya di sini ada tiga baris yang semuanya
                          // onTap kosong: WhatsApp '0812-3456-7890' (nomor
                          // contoh), Email 'help@sporta.id' (domainnya pun
                          // salah — mereknya sportago.id), dan Live Chat
                          // "Chat dengan CS" padahal tidak ada meja CS;
                          // obrolan di app ini antara pemesan dan pengelola
                          // lapangan soal satu booking, bukan layanan bantuan.
                          //
                          // Alamat ini sama dengan yang dipakai halaman
                          // Tentang, dan disalin ke papan klip seperti di
                          // sana, bukan membuka mailto: yang gagal diam-diam
                          // kalau perangkatnya tidak punya aplikasi surel.
                          _buildContactItem(
                            Icons.email_rounded,
                            'Email',
                            'support@sportago.id',
                            context.c.accent,
                            () => _salinKePapanKlip(
                              context,
                              'support@sportago.id',
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Dulu di sini ada kotak "Jam Operasional CS
                    // Senin - Minggu: 08:00 - 22:00 WIB" lengkap dengan
                    // lencana hijau "Online". Tidak ada meja CS, jadi
                    // tidak ada jam operasinya, dan lencana itu menyala
                    // hijau terus tanpa ada yang menyalakannya.
                    //
                    // Diganti keterangan yang bisa dipegang: surel
                    // dijawab manual, jadi jawabannya tidak instan.
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: context.c.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: context.c.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.c.warn.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.mark_email_read_outlined,
                              color: context.c.warn,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Balasan lewat email',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: context.c.ink,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Dibalas manual, biasanya dalam 1 hari kerja. '
                                  'Sertakan kode booking kamu ya.',
                                  style: TextStyle(
                                    color: context.c.inkSoft,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHelpSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.c.ink,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.c.line),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    );
  }

  Widget _buildHelpStep(int number, String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: context.c.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: context.c.onAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: context.c.ink, fontSize: 14),
            ),
          ),
          Icon(icon, size: 18, color: context.c.inkSoft),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.help_outline, size: 18, color: context.c.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  question,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: context.c.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: TextStyle(
                color: context.c.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Salin alamat bantuan ke papan klip.
  ///
  /// Disamakan dengan halaman Tentang, bukan membuka `mailto:`:
  /// url_launcher gagal diam-diam kalau perangkatnya tidak punya
  /// aplikasi surel terpasang, dan pemesan cuma melihat ketukannya
  /// tidak melakukan apa-apa — persis keluhan yang bikin baris ini
  /// diperbaiki.
  void _salinKePapanKlip(BuildContext context, String teks) {
    Clipboard.setData(ClipboardData(text: teks));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$teks disalin'),
        backgroundColor: context.c.ok,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildContactItem(
    IconData icon,
    String title,
    String value,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: context.c.ink,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: context.c.inkSoft),
          ],
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: context.c.line),
        ),
        title: Row(
          children: [
            Icon(Icons.description_outlined, color: context.c.accent),
            SizedBox(width: 10),
            Text(
              'Syarat & Ketentuan',
              style: TextStyle(fontSize: 18, color: context.c.ink),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Angka di bawah ini dicocokkan dengan kode backend pada
              // 11 Sep 2026, bukan disalin dari draf lama. Empat dari
              // enam butir sebelumnya keliru: batas bayar ditulis 15
              // menit padahal 10, ada aturan "batal 2 jam sebelum main"
              // yang tidak pernah ada, tenggat refund 3-5 hari kerja
              // tanpa dasar, dan biaya platform ditulis 5% padahal 8%.
              // Syarat yang salah lebih buruk daripada tidak ada syarat:
              // pelanggan mengambil keputusan berdasarkan angka itu.
              _buildTermItem(
                '1',
                'Pembayaran harus diselesaikan dalam 10 menit setelah pemesanan dibuat.',
              ),
              _buildTermItem(
                '2',
                'Pemesanan yang belum dibayar otomatis dibatalkan setelah batas waktu itu lewat.',
              ),
              _buildTermItem(
                '3',
                'Selama belum dibayar, pemesanan bisa kamu batalkan sendiri.',
              ),
              // Butir 4 & 5 disatukan dan diluruskan 18 Sep 2026.
              // Sebelumnya tertulis pembatalan "diajukan ke pemilik
              // venue", padahal tidak ada tombolnya di app mitra dan
              // tidak ada di app pemesan. Yang berlaku: sekali bayar
              // berhasil, tidak ada pengembalian.
              _buildTermItem(
                '4',
                'Setelah pembayaran berhasil, pemesanan tidak dapat dibatalkan dan pembayaran tidak dikembalikan.',
              ),
              _buildTermItem(
                '5',
                'Harga lapangan, biaya platform (8%, maksimal Rp 20.000), dan biaya pembayaran sama-sama tidak dikembalikan.',
              ),
              _buildTermItem(
                '6',
                'Harap datang 10 menit sebelum jadwal bermain.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup', style: TextStyle(color: context.c.accent)),
          ),
        ],
      ),
    );
  }

  Widget _buildTermItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: context.c.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: context.c.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.c.inkSoft,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _shareBookingInfo() {
    final bookingInfo =
        '''
🏟️ Booking Lapangan - Sportago

📍 ${widget.venueName}
🏃 ${widget.fieldName}
📅 ${widget.selectedDate}
⏰ ${widget.selectedTimeSlots.map(WaktuWib.tampil).join(", ")} (${_durationHours} jam)

💰 Total: ${_formatCurrency(_totalPrice)}

Download Sportago App untuk booking lapangan olahraga!
''';

    // Sebelumnya di sini cuma ada snackbar "Info booking disalin ke
    // clipboard!" dengan `Share.share` dibiarkan jadi komentar. Jadi
    // tombolnya mengaku menyalin sesuatu yang tidak pernah ke mana-mana.
    // Paketnya sudah terpasang dan sudah dipakai di halaman e-ticket.
    Share.share(bookingInfo);
  }

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }
}

// =========================================================
// BOOKING CREATED PAGE - Shows after successful booking creation
// With payment status polling and success animation
// =========================================================
class BookingCreatedPage extends StatefulWidget {
  final Booking booking;
  final Map<String, dynamic>? payment;
  final int? basePrice;
  final int? platformFee;
  final int? adminFee;
  final int? totalPrice;
  final String? paymentMethod;
  final String? paymentMethodLabel;

  const BookingCreatedPage({
    super.key,
    required this.booking,
    this.payment,
    this.basePrice,
    this.platformFee,
    this.adminFee,
    this.totalPrice,
    this.paymentMethod,
    this.paymentMethodLabel,
  });

  @override
  State<BookingCreatedPage> createState() => _BookingCreatedPageState();
}

class _BookingCreatedPageState extends State<BookingCreatedPage>
    with SingleTickerProviderStateMixin {
  // Timers
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  // State
  String _countdown = "00:15:00";
  bool _isExpired = false;
  bool _isPaid = false;
  bool _isCheckingStatus = false;
  Booking? _currentBooking;

  // Controllernya dipakai sebagai penunda sebelum popup sukses, bukan
  // untuk menganimasikan apa pun. Dua Tween yang dulu ada di sini
  // (_scaleAnimation, _opacityAnimation) tidak pernah dibaca widget mana
  // pun, begitu juga _showSuccessAnimation.
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Start countdown timer
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateCountdown();
    });

    // Start polling payment status every 5 seconds
    _startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_isPaid && !_isExpired) {
        _checkPaymentStatus();
      }
    });
  }

  Future<void> _checkPaymentStatus() async {
    if (!mounted || _isCheckingStatus) return;

    setState(() => _isCheckingStatus = true);

    try {
      final result = await BookingService.getBookingDetail(_currentBooking!.id);

      if (mounted && result.success && result.booking != null) {
        final booking = result.booking!;
        setState(() {
          _currentBooking = booking;
          _isCheckingStatus = false;
        });

        // Check if payment is successful
        if (booking.status == 'confirmed' || booking.status == 'paid') {
          _onPaymentSuccess();
        } else if (booking.status == 'cancelled' ||
            booking.status == 'expired') {
          if (mounted) setState(() => _isExpired = true);
          _pollingTimer?.cancel();
        }
      } else {
        if (mounted) setState(() => _isCheckingStatus = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCheckingStatus = false);
      }
    }
  }

  void _onPaymentSuccess() {
    if (!mounted) return;

    _pollingTimer?.cancel();
    _countdownTimer?.cancel();

    setState(() => _isPaid = true);

    // Play animation
    _animationController.forward().then((_) {
      // Show success popup after animation
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showSuccessPopup();
      });
    });
  }

  /// Tombol uji: menandai pembayaran berhasil lewat server.
  ///
  /// Dulu fungsi ini langsung memanggil `_onPaymentSuccess()` tanpa
  /// menyentuh API, layar menyatakan "Pembayaran Berhasil, booking
  /// dikonfirmasi" padahal di server booking-nya masih `pending` dan
  /// akan kedaluwarsa sepuluh menit kemudian. Sekarang ia memakai
  /// endpoint simulasi yang sama dengan yang dipakai web, jadi tampilan
  /// dan server sepakat.
  Future<void> _simulatePaymentSuccess() async {
    final hasil = await BookingService.simulatePayment(widget.booking.id);

    if (!mounted) return;

    if (!hasil.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(hasil.message ?? 'Simulasi pembayaran gagal'),
          backgroundColor: context.c.danger,
        ),
      );
      return;
    }

    // Backend mencoba API simulasi gateway dulu supaya webhook aslinya ikut
    // terpicu; kalau tidak bisa, ia menandai lunas langsung di basis data.
    // Dua hal itu membuktikan hal yang sangat berbeda, jadi bedanya harus
    // sampai ke layar. Dulu dua-duanya sama-sama berakhir "berhasil", dan
    // penguji tidak punya cara tahu gateway-nya benar-benar dipakai atau
    // dilewati.
    if (hasil.simulatedByGateway == false) {
      // Peringatannya harus dibaca dulu, bukan lewat snackbar yang langsung
      // tertimbun dialog "Pembayaran Berhasil". Yang penting justru bahwa
      // keberhasilan ini TIDAK membuktikan apa pun soal gateway.
      await _dialogGatewayDilewati(hasil.alasanGatewayDilewati);
      if (!mounted) return;
    }

    _onPaymentSuccess();
  }

  Future<void> _dialogGatewayDilewati(String? alasan) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.c.raised,
        icon: Icon(
          Icons.warning_amber_rounded,
          color: context.c.warn,
          size: 40,
        ),
        title: Text(
          'Payment gateway dilewati',
          style: TextStyle(color: context.c.ink, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking ini ditandai lunas langsung di basis data. Payment '
              'gateway tidak ikut diuji sama sekali.',
              style: TextStyle(color: context.c.inkSoft, height: 1.45),
            ),
            if (alasan != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.c.sunken,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  alasan,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.c.inkSoft,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Mengerti', style: TextStyle(color: context.c.accent)),
          ),
        ],
      ),
    );
  }

  void _showSuccessPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: context.c.line),
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with animation
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [context.c.ok, context.c.ok],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: context.c.ok.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Booking kamu sudah dikonfirmasi.\nSampai jumpa di lapangan!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.inkSoft,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: context.c.okSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _currentBooking?.bookingCode ?? '',
                  style: TextStyle(
                    color: context.c.ok,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ETicketPage(booking: _currentBooking!),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.confirmation_number_outlined,
                        color: context.c.onAccent,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Lihat E-Tiket',
                        style: TextStyle(
                          color: context.c.onAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HomePageWithTab(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: context.c.line),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: Text(
                    'Kembali ke Beranda',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: context.c.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateCountdown() {
    if (!mounted || _isPaid) return;

    DateTime? expiresAt;

    if (widget.payment != null && widget.payment!['expires_at'] != null) {
      try {
        expiresAt = DateTime.parse(widget.payment!['expires_at'].toString());
      } catch (e) {
        // fallback
      }
    }

    expiresAt ??= widget.booking.expiresAt;

    if (expiresAt != null) {
      final remaining = expiresAt.difference(DateTime.now());
      if (remaining.isNegative) {
        if (mounted) {
          setState(() {
            _countdown = "00:00:00";
            _isExpired = true;
          });
        }
        _countdownTimer?.cancel();
        _pollingTimer?.cancel();
      } else {
        final hours = remaining.inHours.toString().padLeft(2, '0');
        final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _countdown = "$hours:$minutes:$seconds");
      }
    }
  }

  String _formatCurrencyInt(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }

  Booking get booking => _currentBooking ?? widget.booking;
  Map<String, dynamic>? get payment => widget.payment;

  /// Kategori cara bayar yang menentukan instruksi mana yang ditampilkan.
  ///
  /// Dulu percabangannya `paymentMethod.startsWith('VA_')`, jadi cuma ada
  /// dua kemungkinan: Virtual Account, atau QRIS. Setiap e-wallet (OVO,
  /// GoPay, DANA, ShopeePay, LinkAja) jatuh ke "selain VA" dan disuguhi
  /// layar QRIS, padahal e-wallet tidak pernah menghasilkan QR: yang
  /// dikembalikan adalah tautan checkout ke aplikasi dompetnya.
  String get _kategoriBayar {
    final kode = (widget.paymentMethod ?? '').toUpperCase();
    if (kode.startsWith('VA_')) return 'va';
    if (kode == 'QRIS') return 'qris';
    // Server mengirim tautan checkout hanya untuk e-wallet, jadi
    // keberadaannya sekaligus jadi penanda yang paling bisa dipercaya.
    if (_tautanEwallet != null) return 'ewallet';
    return 'qris';
  }

  /// Tautan bayar e-wallet, deeplink ke aplikasinya kalau ada.
  ///
  /// Server mengisi tiga kunci di `actions`. Deeplink didahulukan karena
  /// langsung membuka aplikasi dompet di HP; checkout web dipakai kalau
  /// deeplinknya tidak dikirim.
  ///
  /// Duitku mengembalikan satu tautan pembayaran, dan backend menaruhnya
  /// di ketiga kunci itu. Urutan ini tetap benar: yang terambil alamat
  /// yang sama, dan halaman Duitku sendiri yang meneruskan pelanggan ke
  /// aplikasi dompetnya.
  String? get _tautanEwallet {
    final p = payment;
    if (p == null) return null;
    final actions = p['actions'];
    if (actions is Map) {
      for (final kunci in const [
        'mobile_deeplink_checkout_url',
        'mobile_web_checkout_url',
        'desktop_web_checkout_url',
      ]) {
        final nilai = actions[kunci];
        if (nilai is String && nilai.isNotEmpty) return nilai;
      }
    }
    final checkout = p['checkout_url'];
    if (checkout is String && checkout.isNotEmpty) return checkout;
    return null;
  }

  Future<void> _bukaTautanEwallet() async {
    final tautan = _tautanEwallet;
    if (tautan == null) return;
    final uri = Uri.tryParse(tautan);
    if (uri == null) return;

    final bisa = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!bisa && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada aplikasi yang bisa membuka $tautan')),
      );
    }
  }

  /// Instruksi pembayaran sesuai cara bayar yang benar-benar dipilih.
  /// Keadaan pemesanan, nominal, dan sisa waktu dalam satu tarikan baca.
  ///
  /// Dulu bagian ini berupa lingkaran ikon 64px dengan bayangan sebar
  /// 30px dan gradien dari satu warna ke warna yang sama persis. Tidak
  /// ada satu pun informasi di dalamnya; ia cuma memakan layar di posisi
  /// paling berharga. Sekarang tempat itu diisi yang benar-benar dicari
  /// pelanggan: statusnya, jumlah yang harus dibayar, dan sisa waktunya.
  Widget _kepalaStatus(BuildContext context, int total) {
    final Color warna = _isPaid
        ? context.c.ok
        : (_isExpired ? context.c.danger : context.c.warn);
    final String judul = _isPaid
        ? 'Pembayaran diterima'
        : (_isExpired ? 'Waktu pembayaran habis' : 'Menunggu pembayaran');
    final IconData ikon = _isPaid
        ? Icons.check_circle_rounded
        : (_isExpired ? Icons.cancel_rounded : Icons.schedule_rounded);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(ikon, size: 20, color: warna),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                judul,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: warna,
                ),
              ),
            ),
            // Sisa waktu duduk sebaris dengan statusnya karena keduanya
            // satu pikiran: "bayar sebelum sekian". Dulu ia berupa angka
            // 32px di dalam kotak berwarna warnSoft di atas latar
            // warnSoft juga, jadi kotaknya tak terlihat sama sekali.
            if (!_isPaid && !_isExpired)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: context.c.warnSoft,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _countdown,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: context.c.warn,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          _formatCurrencyInt(total),
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: context.c.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isPaid
              ? 'Lapangan sudah diamankan untuk kamu.'
              : (_isExpired
                    ? 'Slotnya sudah dilepas. Silakan pesan ulang.'
                    : 'Transfer dengan nominal yang sama persis.'),
          style: TextStyle(fontSize: 13, color: context.c.inkSoft),
        ),
        if (_isCheckingStatus && !_isPaid) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              SizedBox(
                width: 13,
                height: 13,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.c.info,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mengecek status pembayaran...',
                style: TextStyle(fontSize: 12, color: context.c.info),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Satu-satunya blok yang ditinggikan di halaman ini.
  ///
  /// Kartu di sini bukan hiasan: ia menandai bagian yang harus
  /// dikerjakan pelanggan sekarang. Karena hanya blok ini yang punya
  /// latar terangkat, matanya langsung jatuh ke sini.
  Widget _blokCaraBayar(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.line),
      ),
      child: _instruksiPembayaran(context),
    );
  }

  /// Ringkasan pemesanan sebagai daftar biasa, tanpa kartu.
  ///
  /// Isinya bukan sesuatu yang perlu dikerjakan, cuma dicocokkan sekilas,
  /// jadi ia sengaja rata dengan halaman. Kalau semua blok diberi kartu
  /// dan garis yang sama seperti sebelumnya, tidak ada yang menonjol dan
  /// pelanggan harus membaca semuanya untuk tahu mana yang penting.
  Widget _ringkasanPemesanan(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detail pemesanan',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
            color: context.c.inkDim,
          ),
        ),
        const SizedBox(height: 12),
        // Kode pemesanan dinaikkan: inilah yang ditanyakan petugas
        // lapangan, dan dulu ia cuma satu baris di antara lima baris
        // lain yang bentuknya sama persis.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                booking.bookingCode,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: context.c.ink,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: booking.bookingCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Kode pemesanan disalin'),
                    backgroundColor: context.c.ok,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.copy_rounded,
                size: 18,
                color: context.c.inkSoft,
              ),
              tooltip: 'Salin kode pemesanan',
            ),
          ],
        ),
        const SizedBox(height: 6),
        _barisRingkas(context, booking.field?.venue?.name ?? '-'),
        _barisRingkas(context, booking.field?.name ?? '-'),
        _barisRingkas(
          context,
          '${booking.bookingDate} - ${booking.formattedTime} (${booking.durationHours} jam)',
        ),
      ],
    );
  }

  Widget _barisRingkas(BuildContext context, String teks) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        teks,
        style: TextStyle(fontSize: 13, color: context.c.inkSoft, height: 1.4),
      ),
    );
  }

  /// Rincian biaya yang bisa dibuka, bukan yang selalu terbentang.
  ///
  /// Pelanggan sudah menyetujui angka ini di layar sebelumnya. Dibentang
  /// lagi di sini, empat baris itu cuma menambah panjang halaman dan
  /// menyaingi bagian yang benar-benar perlu dikerjakan. Tetap bisa
  /// dibuka karena rincian biaya adalah hak pelanggan untuk diperiksa,
  /// bukan sesuatu yang boleh disembunyikan.
  Widget _rincianBiaya(
    BuildContext context, {
    required int total,
    required int lapangan,
    required int platform,
    required int admin,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Total pembayaran',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.c.ink,
              ),
            ),
            Text(
              _formatCurrencyInt(total),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: context.c.ink,
              ),
            ),
          ],
        ),
        children: [
          _buildPriceRow('Harga lapangan', lapangan),
          const SizedBox(height: 8),
          _buildPriceRow('Biaya platform', platform),
          const SizedBox(height: 8),
          _buildPriceRow('Biaya admin', admin),
        ],
      ),
    );
  }

  Widget _instruksiPembayaran(BuildContext context) {
    final kategori = _kategoriBayar;
    final label = widget.paymentMethodLabel ?? 'QRIS';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        children: [
          _lencanaCaraBayar(context, kategori, label),
          const SizedBox(height: 16),
          if (kategori == 'va')
            _blokVirtualAccount(context)
          else if (kategori == 'ewallet')
            _blokEwallet(context, label)
          else
            _blokQris(context),
          if (kDebugMode) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _simulatePaymentSuccess,
                icon: const Icon(
                  Icons.bug_report,
                  color: Colors.white,
                  size: 18,
                ),
                label: const Text(
                  'TEST: Tandai Lunas (coba lewat gateway dulu)',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _lencanaCaraBayar(
    BuildContext context,
    String kategori,
    String label,
  ) {
    final (ikon, warna, warnaLembut) = switch (kategori) {
      'va' => (
        Icons.account_balance,
        context.c.kategori(3),
        context.c.kategori(3).withValues(alpha: 0.12),
      ),
      'ewallet' => (
        Icons.account_balance_wallet,
        context.c.kategori(0),
        context.c.kategori(0).withValues(alpha: 0.12),
      ),
      _ => (Icons.qr_code_2, context.c.info, context.c.infoSoft),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: warnaLembut,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: warna),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 16, color: warna),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: warna,
            ),
          ),
        ],
      ),
    );
  }

  Widget _blokQris(BuildContext context) {
    final qr = payment?['qr_string'];

    // QR yang tidak ada tidak boleh disamarkan jadi kotak hitam. Dulu di
    // sini selalu digambar Icon(Icons.qr_code_2) setinggi 120px, ikon
    // Material biasa, lalu stringnya dicetak sebagai teks di bawahnya.
    // Hasilnya mustahil dipindai, bahkan waktu Xendit mengirim QR asli.
    if (qr is! String || qr.isEmpty) {
      return _pesanGagal(
        context,
        'Kode QR belum diterima dari server. Coba tekan "Cek Status '
        'Pembayaran", atau buat ulang pemesanan.',
      );
    }

    return Column(
      children: [
        Text(
          'Scan QR untuk bayar:',
          style: TextStyle(fontSize: 12, color: context.c.inkSoft),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // QR wajib gelap di atas terang apa pun temanya, jadi warnanya
            // dipatok, bukan diambil dari token.
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.c.line),
          ),
          child: QrImageView(
            data: qr,
            version: QrVersions.auto,
            size: 220,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Scan dengan aplikasi e-wallet atau m-banking',
          style: TextStyle(fontSize: 11, color: context.c.inkSoft),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _blokEwallet(BuildContext context, String label) {
    if (_tautanEwallet == null) {
      return _pesanGagal(
        context,
        'Tautan pembayaran $label belum diterima dari server. Coba tekan '
        '"Cek Status Pembayaran", atau buat ulang pemesanan.',
      );
    }

    return Column(
      children: [
        Text(
          'Selesaikan pembayaran di aplikasi $label:',
          style: TextStyle(fontSize: 12, color: context.c.inkSoft),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _bukaTautanEwallet,
            icon: Icon(Icons.open_in_new, size: 18, color: context.c.onAccent),
            label: Text(
              'Bayar dengan $label',
              style: TextStyle(
                color: context.c.onAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.c.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Setelah membayar, kembali ke sini lalu tekan "Cek Status '
          'Pembayaran".',
          style: TextStyle(fontSize: 11, color: context.c.inkSoft),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _blokVirtualAccount(BuildContext context) {
    final nomor = payment?['virtual_account_no'] ?? payment?['va_number'];

    // Nomor VA contoh tidak boleh ditampilkan. Baris lama memakai
    // `?? "8800 1234 5678 9012"`, nomor karangan yang kalau ditransfer
    // beneran uangnya entah ke mana.
    if (nomor is! String || nomor.isEmpty) {
      return _pesanGagal(
        context,
        'Nomor Virtual Account belum diterima dari server. Coba tekan '
        '"Cek Status Pembayaran", atau buat ulang pemesanan.',
      );
    }

    final bank = payment?['bank'];

    return Column(
      children: [
        Text(
          bank is String && bank.isNotEmpty
              ? 'Nomor Virtual Account $bank:'
              : 'Nomor Virtual Account:',
          style: TextStyle(fontSize: 12, color: context.c.inkSoft),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: context.c.sunken,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: context.c.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: SelectableText(
                  nomor,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: context.c.ink,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: nomor));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nomor VA disalin!')),
                  );
                },
                child: Icon(Icons.copy, size: 20, color: context.c.accent),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Transfer sesuai nominal ke nomor VA di atas',
          style: TextStyle(fontSize: 11, color: context.c.inkSoft),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _pesanGagal(BuildContext context, String pesan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.c.warnSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.c.warn),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, size: 18, color: context.c.warn),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              pesan,
              style: TextStyle(
                fontSize: 12,
                color: context.c.warn,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Use passed values or fallback to booking data
    final displayTotalPrice = widget.totalPrice ?? booking.totalPrice.toInt();
    final displayBasePrice = widget.basePrice ?? booking.totalPrice.toInt();
    final displayPlatformFee = widget.platformFee ?? 0;
    final displayAdminFee = widget.adminFee ?? 0;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: Text(
          // Dulu judulnya selalu "Booking Berhasil" sementara badan
          // halaman berbunyi "Menunggu Pembayaran". Dua kalimat yang
          // saling membantah di satu layar membuat pelanggan ragu
          // apakah uangnya sudah masuk atau belum.
          _isPaid ? 'Pemesanan Selesai' : 'Selesaikan Pembayaran',
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.c.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        // Bilah navigasi menumpuk di atas isi layar sejak
        // targetSdk 35. top:false karena AppBar sudah
        // menyisihkan bagian atasnya sendiri.
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Halaman ini punya SATU tugas selagi belum dibayar:
              // memberi tahu ke mana uangnya ditransfer dan berapa lama
              // waktunya. Sebelum ini urutannya kebalik: lingkaran ikon
              // 64px tanpa informasi, lalu dua kartu detail, dan nomor
              // Virtual Account justru terkubur paling bawah di dalam
              // kotak peringatan. Yang paling dicari pelanggan jadi yang
              // paling susah ditemukan.
              //
              // Sekarang urutannya: keadaan + sisa waktu, lalu cara bayar,
              // baru rincian. Kartu juga tidak lagi seragam; hanya blok
              // pembayaran yang ditinggikan, sisanya rata dengan halaman
              // supaya perbedaannya berarti.
              _kepalaStatus(context, displayTotalPrice),

              if (!_isPaid) ...[
                const SizedBox(height: 20),
                _blokCaraBayar(context),
              ],

              const SizedBox(height: 28),
              _ringkasanPemesanan(context),

              const SizedBox(height: 20),
              _rincianBiaya(
                context,
                total: displayTotalPrice,
                lapangan: displayBasePrice,
                platform: displayPlatformFee,
                admin: displayAdminFee,
              ),

              const SizedBox(height: 24),

              // Action Buttons - Show different buttons based on payment status
              if (_isPaid) ...[
                // When paid, show button to view e-ticket
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ETicketPage(booking: _currentBooking!),
                        ),
                        (route) => false,
                      );
                    },
                    icon: Icon(
                      Icons.confirmation_number_outlined,
                      color: context.c.onAccent,
                      size: 20,
                    ),
                    label: Text(
                      "Lihat E-Tiket",
                      style: TextStyle(
                        color: context.c.onAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomePageWithTab(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.c.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      "Kembali ke Beranda",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.c.ink,
                      ),
                    ),
                  ),
                ),
              ] else if (_isExpired) ...[
                // When expired, show button to create new booking
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomePageWithTab(initialIndex: 0),
                        ),
                        (route) => false,
                      );
                    },
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: context.c.onAccent,
                      size: 20,
                    ),
                    label: Text(
                      "Buat Booking Baru",
                      style: TextStyle(
                        color: context.c.onAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomePageWithTab(initialIndex: 1),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.c.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      "Lihat Pesanan Saya",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.c.ink,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // When pending, show manual check button and my orders
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isCheckingStatus
                        ? null
                        : () {
                            _checkPaymentStatus();
                          },
                    icon: _isCheckingStatus
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: 20,
                          ),
                    label: Text(
                      _isCheckingStatus
                          ? "Mengecek..."
                          : "Cek Status Pembayaran",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.warn,
                      disabledBackgroundColor: context.c.warn,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HomePageWithTab(initialIndex: 1),
                        ),
                        (route) => false,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: context.c.line),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Text(
                      "Lihat Pesanan Saya",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: context.c.ink,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const HomePageWithTab(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text(
                    "Kembali ke Beranda",
                    style: TextStyle(
                      color: context.c.inkSoft,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, int amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: context.c.inkSoft, fontSize: 14),
          ),
        ),
        Text(
          _formatCurrencyInt(amount),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: context.c.ink,
          ),
        ),
      ],
    );
  }
}
