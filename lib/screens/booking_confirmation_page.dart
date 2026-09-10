import 'dart:math' as math;
import 'dart:async';
import '../utils/waktu_wib.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'home_page.dart';
import 'login_page.dart';
import 'e_ticket_page.dart';

class BookingConfirmationPage extends StatefulWidget {
  final int fieldId;
  final String venueName;
  final String venueAddress;
  final String fieldName;
  final String selectedDate; // Format: YYYY-MM-DD
  final List<String> selectedTimeSlots; // Changed to List
  final int price;

  const BookingConfirmationPage({
    super.key,
    required this.fieldId,
    required this.venueName,
    this.venueAddress = "Jl. Sudirman No. 123, Jakarta Selatan",
    required this.fieldName,
    required this.selectedDate,
    required this.selectedTimeSlots,
    required this.price,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  // Controllers untuk form input
  final TextEditingController _notesController = TextEditingController();

  // State
  bool _isLoading = false;
  String _selectedPaymentMethod = "QRIS";
  bool _refundPolicyAccepted = false; // State untuk acknowledgment refund policy

  // Tarif biaya — HARUS sama dengan backend (BookingService::PLATFORM_FEE_RATE
  // dan PLATFORM_FEE_CAP di be-main). Sebelumnya di sini 5% tanpa batas,
  // sementara server memakai 8% dengan batas Rp 20.000: layar ini
  // menampilkan total yang berbeda dari yang benar-benar ditagihkan —
  // kurang Rp 3.056 pada booking Rp 100.000, dan lebih Rp 17.360 pada
  // booking Rp 750.000.
  static const double _platformFeePercent = 0.08;
  static const int _platformFeeCap = 20000;

  // Payment method data with fees
  static final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'QRIS',
      'title': 'QRIS',
      'subtitle': 'Scan QR via e-wallet atau m-banking',
      'feeType': 'percent',
      'feeValue': 0.007, // 0.7% (MDR regulated by BI)
      'icon': Icons.qr_code_2,
    },
    {
      'id': 'VA_BCA',
      'title': 'BCA Virtual Account',
      'subtitle': 'Transfer via ATM/m-Banking BCA',
      'feeType': 'flat',
      'feeValue': 4000,
      'icon': Icons.account_balance,
    },
    {
      'id': 'VA_BNI',
      'title': 'BNI Virtual Account',
      'subtitle': 'Transfer via ATM/m-Banking BNI',
      'feeType': 'flat',
      'feeValue': 4000,
      'icon': Icons.account_balance,
    },
    {
      'id': 'VA_BRI',
      'title': 'BRI Virtual Account',
      'subtitle': 'Transfer via ATM/m-Banking BRI',
      'feeType': 'flat',
      'feeValue': 4000,
      'icon': Icons.account_balance,
    },
    {
      'id': 'VA_MANDIRI',
      'title': 'Mandiri Virtual Account',
      'subtitle': 'Transfer via ATM/m-Banking Mandiri',
      'feeType': 'flat',
      'feeValue': 4000,
      'icon': Icons.account_balance,
    },
    {
      'id': 'VA_PERMATA',
      'title': 'Permata Virtual Account',
      'subtitle': 'Transfer via ATM/m-Banking Permata',
      'feeType': 'flat',
      'feeValue': 4000,
      'icon': Icons.account_balance,
    },
    {
      'id': 'DANA',
      'title': 'DANA',
      'subtitle': 'Bayar langsung dari aplikasi DANA',
      'feeType': 'percent',
      'feeValue': 0.015, // 1.5%
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'OVO',
      'title': 'OVO',
      'subtitle': 'Bayar langsung dari aplikasi OVO',
      'feeType': 'percent',
      'feeValue': 0.015, // 1.5%
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'GOPAY',
      'title': 'GoPay',
      'subtitle': 'Bayar langsung dari aplikasi Gojek',
      'feeType': 'percent',
      'feeValue': 0.02, // 2%
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'SHOPEEPAY',
      'title': 'ShopeePay',
      'subtitle': 'Bayar langsung dari aplikasi Shopee',
      'feeType': 'percent',
      'feeValue': 0.015, // 1.5%
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'LINKAJA',
      'title': 'LinkAja',
      'subtitle': 'Bayar langsung dari aplikasi LinkAja',
      'feeType': 'percent',
      'feeValue': 0.015, // 1.5%
      'icon': Icons.account_balance_wallet,
    },
    {
      'id': 'ALFAMART',
      'title': 'Alfamart',
      'subtitle': 'Bayar tunai di gerai Alfamart',
      'feeType': 'flat',
      'feeValue': 5000,
      'icon': Icons.store,
    },
    {
      'id': 'INDOMARET',
      'title': 'Indomaret',
      'subtitle': 'Bayar tunai di gerai Indomaret',
      'feeType': 'flat',
      'feeValue': 5000,
      'icon': Icons.store,
    },
  ];

  // Duration is calculated from selected time slots
  int get _durationHours => widget.selectedTimeSlots.length;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  // Get selected payment method data
  Map<String, dynamic> get _selectedPaymentData {
    return _paymentMethods.firstWhere(
      (m) => m['id'] == _selectedPaymentMethod,
      orElse: () => _paymentMethods.first,
    );
  }

  // Calculate payment gateway fee based on selected method
  int get _paymentGatewayFee {
    final method = _selectedPaymentData;
    if (method['feeType'] == 'percent') {
      // Dasarnya (harga lapangan + platform fee), sama seperti
      // BookingService di backend — bukan harga lapangan saja.
      return ((_fieldPrice + _platformFee) * (method['feeValue'] as double))
          .round();
    } else {
      return method['feeValue'] as int;
    }
  }

  // Get fee label for display
  String get _paymentGatewayFeeLabel {
    final method = _selectedPaymentData;
    if (method['feeType'] == 'percent') {
      final percent = ((method['feeValue'] as double) * 100).toStringAsFixed(1);
      return "Biaya Admin ($percent%)";
    } else {
      return "Biaya Admin";
    }
  }


  /// Label biaya platform, mengikuti tarif yang benar-benar dipakai.
  ///
  /// Dulu tertulis mati "(5%)" — dua kali salah: tarifnya 8%, dan pada
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
  int get _fieldPrice => widget.price * _durationHours;
  int get _platformFee =>
      math.min((_fieldPrice * _platformFeePercent).round(), _platformFeeCap);
  int get _totalPrice => _fieldPrice + _platformFee + _paymentGatewayFee;

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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // QRIS Section
                    _buildSectionHeader("QRIS", Icons.qr_code_2),
                    _buildPaymentOption(_paymentMethods[0]),

                    const SizedBox(height: 16),

                    // Virtual Account Section
                    _buildSectionHeader("Virtual Account", Icons.account_balance),
                    ..._paymentMethods
                        .where((m) => m['id'].toString().startsWith('VA_'))
                        .map((m) => _buildPaymentOption(m)),

                    const SizedBox(height: 16),

                    // E-Wallet Section
                    _buildSectionHeader("E-Wallet", Icons.account_balance_wallet),
                    ..._paymentMethods
                        .where((m) => ['DANA', 'OVO', 'GOPAY', 'SHOPEEPAY', 'LINKAJA'].contains(m['id']))
                        .map((m) => _buildPaymentOption(m)),

                    const SizedBox(height: 16),

                    // Retail Section
                    _buildSectionHeader("Gerai Retail", Icons.store),
                    ..._paymentMethods
                        .where((m) => ['ALFAMART', 'INDOMARET'].contains(m['id']))
                        .map((m) => _buildPaymentOption(m)),

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
          color: isSelected ? context.c.accent.withValues(alpha: 0.15) : context.c.raised,
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
                    style: TextStyle(
                      color: context.c.inkSoft,
                      fontSize: 11,
                    ),
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
      final percent = ((method['feeValue'] as double) * 100).toStringAsFixed(1);
      return "Biaya $percent%";
    } else {
      return "Biaya ${_formatCurrency(method['feeValue'] as int)}";
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
                  Text('Membuat booking...', style: TextStyle(color: context.c.ink)),
                ],
              ),
            )
          : AnnotatedRegion<SystemUiOverlayStyle>(
            value: gayaOverlay(context),
            child: SafeArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- HEADER ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Icon(Icons.arrow_back, size: 24, color: context.c.ink),
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
                              child: Icon(Icons.more_horiz, size: 20, color: context.c.ink),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // --- VENUE INFO CARD ---
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Venue Image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: context.c.raised,
                              borderRadius: BorderRadius.circular(12),
                              image: const DecorationImage(
                                image: NetworkImage('https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=200'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Venue Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                    Icon(Icons.location_on, color: context.c.inkSoft, size: 14),
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: context.c.raised,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.c.line),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined, size: 18, color: context.c.inkSoft),
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
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      _selectedPaymentData['subtitle'] as String,
                                      style: TextStyle(
                                        color: context.c.inkSoft,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: context.c.inkSoft),
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
                            Icon(Icons.info_outline, size: 18, color: context.c.accent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                                  children: [
                                    const TextSpan(text: 'Biaya admin payment gateway: '),
                                    TextSpan(
                                      text: _formatCurrency(_paymentGatewayFee),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    TextSpan(
                                      text: _selectedPaymentData['feeType'] == 'percent'
                                          ? ' (${((_selectedPaymentData['feeValue'] as double) * 100).toStringAsFixed(1)}% dari harga lapangan)'
                                          : ' (biaya tetap)',
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
                            hintStyle: TextStyle(color: context.c.inkSoft, fontSize: 14),
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
                        _formatCurrency(_fieldPrice),
                      ),
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
                          border: Border.all(color: context.c.warn.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, color: context.c.warn, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ketentuan Refund",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: context.c.warn,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Jika terjadi pembatalan, hanya harga lapangan yang dapat dikembalikan. Biaya admin & platform tidak dapat di-refund.",
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
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
                                  side: BorderSide(color: context.c.line, width: 2),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "Saya memahami dan menyetujui ketentuan refund di atas",
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: context.c.danger.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: context.c.danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Centang persetujuan ketentuan refund untuk melanjutkan",
                          style: TextStyle(fontSize: 12, color: context.c.danger),
                        ),
                      ),
                    ],
                  ),
                ),
              
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (_isLoading || !_refundPolicyAccepted) ? null : _createBooking,
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
            style: TextStyle(
              color: context.c.inkSoft,
              fontSize: 14,
            ),
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
                    style: TextStyle(
                      fontSize: 12,
                      color: context.c.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: context.c.inkSoft,
              size: 20,
            ),
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
                      child: Icon(Icons.support_agent_rounded, color: context.c.onAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pusat Bantuan',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.c.ink),
                          ),
                          Text(
                            'Kami siap membantu kamu',
                            style: TextStyle(fontSize: 13, color: context.c.inkSoft),
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
                        child: Icon(Icons.close, size: 18, color: context.c.inkSoft),
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
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Cara Booking Section
                    _buildHelpSection(
                      icon: Icons.menu_book_rounded,
                      iconColor: context.c.accent,
                      title: 'Cara Booking',
                      child: Column(
                        children: [
                          _buildHelpStep(1, 'Pastikan data booking sudah benar', Icons.fact_check_outlined),
                          _buildHelpStep(2, 'Pilih metode pembayaran yang tersedia', Icons.payment_outlined),
                          _buildHelpStep(3, 'Klik tombol "Bayar Sekarang"', Icons.touch_app_outlined),
                          _buildHelpStep(4, 'Selesaikan pembayaran dalam 15 menit', Icons.timer_outlined),
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
                          _buildFaqItem(
                            'Apakah bisa reschedule?',
                            'Ya, reschedule bisa dilakukan maksimal H-1 sebelum jadwal main.',
                          ),
                          _buildFaqItem(
                            'Bagaimana cara membatalkan booking?',
                            'Pembatalan bisa dilakukan di halaman "Pesanan Saya" dengan ketentuan refund berlaku.',
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
                          _buildContactItem(
                            Icons.phone_rounded,
                            'WhatsApp',
                            '0812-3456-7890',
                            context.c.ok,
                            () {},
                          ),
                          _buildContactItem(
                            Icons.email_rounded,
                            'Email',
                            'help@sporta.id',
                            context.c.danger,
                            () {},
                          ),
                          _buildContactItem(
                            Icons.chat_bubble_rounded,
                            'Live Chat',
                            'Chat dengan CS',
                            context.c.accent,
                            () {},
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Operating Hours
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
                            child: Icon(Icons.access_time_filled, color: context.c.warn, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Jam Operasional CS',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.c.ink),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Senin - Minggu: 08:00 - 22:00 WIB',
                                  style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.c.ok,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Online',
                              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.c.ink),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: context.c.line),
          Padding(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
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
                style: TextStyle(color: context.c.onAccent, fontWeight: FontWeight.bold, fontSize: 13),
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
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: context.c.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 26),
            child: Text(
              answer,
              style: TextStyle(color: context.c.inkSoft, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String value, Color color, VoidCallback onTap) {
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
                  Text(title, style: TextStyle(color: context.c.inkSoft, fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.c.ink)),
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
            Text('Syarat & Ketentuan', style: TextStyle(fontSize: 18, color: context.c.ink)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTermItem('1', 'Pembayaran harus dilakukan dalam waktu 15 menit setelah booking dibuat.'),
              _buildTermItem('2', 'Booking yang tidak dibayar akan otomatis dibatalkan.'),
              _buildTermItem('3', 'Pembatalan booking dapat dilakukan maksimal 2 jam sebelum waktu main.'),
              _buildTermItem('4', 'Refund akan diproses dalam 3-5 hari kerja.'),
              _buildTermItem('5', 'Biaya platform (5%) dan biaya admin Xendit tidak dapat di-refund.'),
              _buildTermItem('6', 'Harap datang 10 menit sebelum jadwal booking.'),
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
              style: TextStyle(color: context.c.inkSoft, fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  void _shareBookingInfo() {
    final bookingInfo = '''
🏟️ Booking Lapangan - Sportago

📍 ${widget.venueName}
🏃 ${widget.fieldName}
📅 ${widget.selectedDate}
⏰ ${widget.selectedTimeSlots.map(WaktuWib.tampil).join(", ")} (${_durationHours} jam)

💰 Total: ${_formatCurrency(_totalPrice)}

Download Sportago App untuk booking lapangan olahraga!
''';

    // For now, show a snackbar. In production, use share_plus package
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Info booking disalin ke clipboard!', style: TextStyle(color: context.c.onAccent)),
        backgroundColor: context.c.accent,
        action: SnackBarAction(
          label: 'OK',
          textColor: context.c.onAccent,
          onPressed: () {},
        ),
      ),
    );

    // Note: In production, use:
    // Share.share(bookingInfo);
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: context.c.inkSoft),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: context.c.inkSoft,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.c.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, int? amount, [String? suffix]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: context.c.inkSoft)
        ),
        Text(
          suffix ?? _formatCurrency(amount!),
          style: TextStyle(fontWeight: FontWeight.w500, color: context.c.ink)
        ),
      ],
    );
  }

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";
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

class _BookingCreatedPageState extends State<BookingCreatedPage> with SingleTickerProviderStateMixin {
  // Timers
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  // State
  String _countdown = "00:15:00";
  bool _isExpired = false;
  bool _isPaid = false;
  bool _isCheckingStatus = false;
  bool _showSuccessAnimation = false;
  Booking? _currentBooking;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _currentBooking = widget.booking;

    // Setup animation
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
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
        } else if (booking.status == 'cancelled' || booking.status == 'expired') {
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

    setState(() {
      _isPaid = true;
      _showSuccessAnimation = true;
    });

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
  /// menyentuh API — layar menyatakan "Pembayaran Berhasil, booking
  /// dikonfirmasi" padahal di server booking-nya masih `pending` dan
  /// akan kedaluwarsa sepuluh menit kemudian. Sekarang ia memakai
  /// endpoint simulasi yang sama dengan yang dipakai web, jadi tampilan
  /// dan server sepakat.
  Future<void> _simulatePaymentSuccess() async {
    final hasil = await BookingService.simulatePayment(widget.booking.id);

    if (!mounted) return;

    if (hasil.success) {
      _onPaymentSuccess();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(hasil.message ?? 'Simulasi pembayaran gagal'),
        backgroundColor: context.c.danger,
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        builder: (context) => ETicketPage(booking: _currentBooking!),
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
                      Icon(Icons.confirmation_number_outlined, color: context.c.onAccent, size: 20),
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
                        builder: (context) => const HomePageWithTab(initialIndex: 0),
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
    return "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";
  }

  Booking get booking => _currentBooking ?? widget.booking;
  Map<String, dynamic>? get payment => widget.payment;

  @override
  Widget build(BuildContext context) {
    // Use passed values or fallback to booking data
    final displayTotalPrice = widget.totalPrice ?? booking.totalPrice.toInt();
    final displayBasePrice = widget.basePrice ?? booking.totalPrice.toInt();
    final displayPlatformFee = widget.platformFee ?? 0;
    final displayAdminFee = widget.adminFee ?? 0;
    final displayPaymentMethod = widget.paymentMethodLabel ?? "QRIS";
    final isVirtualAccount = widget.paymentMethod?.startsWith('VA_') ?? false;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: Text(
          "Booking Berhasil",
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.c.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status Icon - changes based on payment status
            if (_showSuccessAnimation) ...[
              // Animated success icon
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Opacity(
                      opacity: _opacityAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [context.c.ok, context.c.ok],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: context.c.ok.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Text(
                "Pembayaran Berhasil!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: context.c.ok,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Booking kamu sudah dikonfirmasi",
                style: TextStyle(
                  color: context.c.inkSoft,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ] else ...[
              // Waiting payment icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _isExpired ? context.c.dangerSoft : context.c.warnSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isExpired ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                  size: 64,
                  color: _isExpired ? context.c.danger : context.c.warn,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isExpired ? "Waktu Pembayaran Habis" : "Menunggu Pembayaran",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: _isExpired ? context.c.danger : context.c.ink,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isExpired
                    ? "Silakan buat booking baru"
                    : "Silakan selesaikan pembayaran sebelum batas waktu",
                style: TextStyle(
                  color: context.c.inkSoft,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              // Checking status indicator
              if (_isCheckingStatus) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: context.c.info,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Mengecek status pembayaran...",
                      style: TextStyle(
                        fontSize: 12,
                        color: context.c.info,
                      ),
                    ),
                  ],
                ),
              ],
            ],
            const SizedBox(height: 24),

            // Booking Details Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.c.raised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.c.line),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Detail Booking",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow("Kode Booking", booking.bookingCode),
                  _buildInfoRow("Venue", booking.field?.venue?.name ?? "-"),
                  _buildInfoRow("Lapangan", booking.field?.name ?? "-"),
                  _buildInfoRow("Tanggal", booking.bookingDate),
                  _buildInfoRow("Waktu", booking.formattedTime),
                  _buildInfoRow("Durasi", "${booking.durationHours} jam"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Price Breakdown Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.c.raised,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.c.ok),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Rincian Biaya",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: context.c.ink,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildPriceRow("Harga Lapangan (${booking.field?.name ?? 'Lapangan'})", displayBasePrice),
                  const SizedBox(height: 8),
                  // Halaman ini menampilkan angka yang sudah dihitung
                  // server, jadi tidak perlu menyebut persentase —
                  // menyebutnya justru berisiko salah saat kena batas.
                  _buildPriceRow("Biaya Platform", displayPlatformFee),
                  const SizedBox(height: 8),
                  _buildPriceRow("Biaya Admin", displayAdminFee),
                  Divider(height: 24, color: context.c.line),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Total Pembayaran",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.c.ink,
                        ),
                      ),
                      Text(
                        _formatCurrencyInt(displayTotalPrice),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          color: context.c.accent,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Payment Info Card with Countdown - Hide when paid
            if (!_isPaid)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _isExpired ? context.c.dangerSoft : context.c.warnSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isExpired ? context.c.danger : context.c.warn,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _isExpired ? Icons.timer_off : Icons.timer_outlined,
                        color: _isExpired ? context.c.danger : context.c.warn,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isExpired ? "Waktu Habis" : "Batas Pembayaran",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _isExpired ? context.c.danger : context.c.warn,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Countdown Timer
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: _isExpired ? context.c.dangerSoft : context.c.warnSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _countdown,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: _isExpired ? context.c.danger : context.c.warn,
                        ),
                      ),
                    ),
                  ),
                  if (_isExpired) ...[
                    const SizedBox(height: 12),
                    Center(
                      child: Text(
                        "Silakan buat booking baru",
                        style: TextStyle(color: context.c.danger),
                      ),
                    ),
                  ],
                  
                  // Payment Method Info
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.raised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.line),
                    ),
                    child: Column(
                      children: [
                        // Payment Method Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isVirtualAccount ? Colors.purple.shade50 : context.c.infoSoft,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isVirtualAccount ? Colors.purple.shade200 : context.c.info,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isVirtualAccount ? Icons.account_balance : Icons.qr_code_2,
                                size: 16,
                                color: isVirtualAccount ? Colors.purple.shade700 : context.c.info,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                displayPaymentMethod,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isVirtualAccount ? Colors.purple.shade700 : context.c.info,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Show VA Number or QR Code based on payment method
                        if (isVirtualAccount) ...[
                          Text(
                            "Nomor Virtual Account:",
                            style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: context.c.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: context.c.line),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  payment?['va_number'] ?? "8800 1234 5678 9012",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.5,
                                    color: context.c.ink,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                InkWell(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Nomor VA disalin!")),
                                    );
                                  },
                                  child: Icon(Icons.copy, size: 20, color: context.c.accent),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Transfer sesuai nominal ke nomor VA di atas",
                            style: TextStyle(fontSize: 11, color: context.c.inkSoft),
                            textAlign: TextAlign.center,
                          ),
                          // Tombol uji — hanya ada di build debug.
                          // Komentar lama menulis "remove in production"
                          // tapi tidak ada yang menegakkannya, jadi
                          // tombolnya ikut ke rilis.
                          if (kDebugMode) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _simulatePaymentSuccess,
                                icon: const Icon(Icons.bug_report,
                                    color: Colors.white, size: 18),
                                label: const Text(
                                  "TEST: Simulasi Pembayaran Berhasil",
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
                        ] else ...[
                          // QRIS
                          Text(
                            "Scan QR untuk bayar:",
                            style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                const Icon(Icons.qr_code_2, size: 120, color: Colors.black),
                                const SizedBox(height: 8),
                                Text(
                                  payment?['qr_string'] ?? "sporta-qr-payment",
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            "Scan dengan aplikasi e-wallet atau m-banking",
                            style: TextStyle(fontSize: 11, color: context.c.inkSoft),
                            textAlign: TextAlign.center,
                          ),
                          // Tombol uji — hanya ada di build debug.
                          // Komentar lama menulis "remove in production"
                          // tapi tidak ada yang menegakkannya, jadi
                          // tombolnya ikut ke rilis.
                          if (kDebugMode) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _simulatePaymentSuccess,
                                icon: const Icon(Icons.bug_report,
                                    color: Colors.white, size: 18),
                                label: const Text(
                                  "TEST: Simulasi Pembayaran Berhasil",
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
                      ],
                    ),
                  ),
                ],
              ),
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
                        builder: (context) => ETicketPage(booking: _currentBooking!),
                      ),
                      (route) => false,
                    );
                  },
                  icon: Icon(Icons.confirmation_number_outlined, color: context.c.onAccent, size: 20),
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
                        builder: (context) => const HomePageWithTab(initialIndex: 0),
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
                        builder: (context) => const HomePageWithTab(initialIndex: 0),
                      ),
                      (route) => false,
                    );
                  },
                  icon: Icon(Icons.add_circle_outline, color: context.c.onAccent, size: 20),
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
                        builder: (context) => const HomePageWithTab(initialIndex: 2),
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
                  onPressed: _isCheckingStatus ? null : () {
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
                    : const Icon(Icons.refresh, color: Colors.white, size: 20),
                  label: Text(
                    _isCheckingStatus ? "Mengecek..." : "Cek Status Pembayaran",
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
                        builder: (context) => const HomePageWithTab(initialIndex: 2),
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
                      builder: (context) => const HomePageWithTab(initialIndex: 0),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.c.inkSoft,
              fontSize: 14,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
                color: context.c.ink,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
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
            style: TextStyle(
              color: context.c.inkSoft,
              fontSize: 14,
            ),
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
