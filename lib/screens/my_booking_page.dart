import 'package:flutter/material.dart';
import '../utils/waktu_wib.dart';
import '../theme/app_tokens.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'venue_detail_page.dart';
import 'login_page.dart';
import 'home_page.dart';
import 'chat/chat_page.dart';
import 'e_ticket_page.dart';

class MyBookingPage extends StatefulWidget {
  final bool showBackButton;

  const MyBookingPage({super.key, this.showBackButton = false});

  @override
  State<MyBookingPage> createState() => _MyBookingPageState();
}

class _MyBookingPageState extends State<MyBookingPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // API data
  List<Booking> _allBookings = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    if (AuthService.token == null) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Silakan login terlebih dahulu';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await BookingService.getMyBookings();

      if (mounted) {
        if (result.success && result.bookings != null) {
          setState(() {
            _allBookings = result.bookings!;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result.message ?? 'Gagal memuat data booking';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Terjadi kesalahan: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is not logged in
    if (AuthService.token == null) {
      return Scaffold(
        backgroundColor: context.c.surface,
        appBar: AppBar(
          title: Text(
            "Pesanan Saya",
            style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold)
          ),
          backgroundColor: context.c.surface,
          systemOverlayStyle: gayaOverlay(context),
          elevation: 0,
          leading: widget.showBackButton ? IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
          ) : null,
          automaticallyImplyLeading: widget.showBackButton,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: context.c.inkSoft),
              const SizedBox(height: 16),
              Text(
                "Silakan login untuk melihat pesanan",
                style: TextStyle(color: context.c.inkSoft, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.accent,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(color: context.c.onAccent, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.c.surface,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 140,
              floating: false,
              pinned: true,
              backgroundColor: context.c.surface,
              systemOverlayStyle: gayaOverlay(context),
              leading: widget.showBackButton ? IconButton(
                icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  }
                },
              ) : null,
              automaticallyImplyLeading: widget.showBackButton,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    color: context.c.surface,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Pesanan Saya",
                            style: TextStyle(
                              color: context.c.ink,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${_allBookings.length} total pesanan",
                            style: TextStyle(
                              color: context.c.inkSoft,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(50),
                child: Container(
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: context.c.accent,
                    unselectedLabelColor: context.c.inkSoft,
                    indicatorColor: context.c.accent,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    tabs: const [
                      Tab(text: "Menunggu"),
                      Tab(text: "Aktif"),
                      Tab(text: "Riwayat"),
                    ],
                  ),
                ),
              ),
            ),
          ];
        },
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.c.accent),
                  SizedBox(height: 16),
                  Text('Memuat data booking...', style: TextStyle(color: context.c.inkSoft)),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: context.c.inkSoft),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: context.c.inkSoft),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.c.accent,
                        ),
                        child: Text(
                          'Coba Lagi',
                          style: TextStyle(color: context.c.onAccent, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  color: context.c.accent,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingList("pending"),
                      _buildBookingList("active"),
                      _buildBookingList("history"),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildBookingList(String filterStatus) {
    List<Booking> filteredData;

    if (filterStatus == "pending") {
      // Menunggu = pending (belum bayar)
      filteredData = _allBookings.where((item) =>
        item.status == 'pending'
      ).toList();
    } else if (filterStatus == "active") {
      // Aktif = confirmed (sudah bayar, belum selesai)
      filteredData = _allBookings.where((item) =>
        item.status == 'confirmed'
      ).toList();
    } else {
      // History = completed, cancelled, expired
      filteredData = _allBookings.where((item) =>
        item.status == 'completed' ||
        item.status == 'cancelled' ||
        item.status == 'expired'
      ).toList();
    }

    if (filteredData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 80, color: context.c.inkSoft),
            const SizedBox(height: 16),
            Text(
              "Belum ada booking di sini",
              style: TextStyle(color: context.c.inkSoft)
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: filteredData.length,
      separatorBuilder: (context, index) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Divider(color: context.c.line, thickness: 1),
      ),
      itemBuilder: (context, index) {
        return BookingCard(
          booking: filteredData[index],
          onRefresh: _loadBookings,
        );
      },
    );
  }
}

// =========================================================
// 1. WIDGET KARTU BOOKING (DESAIN BARU + INTEGRASI API)
// =========================================================
class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const BookingCard({super.key, required this.booking, required this.onRefresh});

  // --- LOGIC NAVIGASI ---
  void _goToPaymentDirect(BuildContext context) {
    Map<String, dynamic> paymentData = _getPaymentData();
    paymentData["selectedMethod"] = "QRIS (Gopay/OVO/Dana)";
    paymentData["adminFee"] = 700;
    paymentData["totalWithFee"] = booking.totalPrice.toInt() + 700;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentWaitingPage(
          booking: booking,
          bookingData: paymentData,
        ),
      ),
    );
  }

  void _goToPaymentSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: PaymentSelectorSheet(totalPrice: booking.totalPrice.toInt()),
      ),
    ).then((result) {
      if (result != null) {
        Map<String, dynamic> paymentData = _getPaymentData();
        paymentData["selectedMethod"] = result['method'];
        paymentData["adminFee"] = result['fee'];
        paymentData["totalWithFee"] = result['total'];

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentWaitingPage(
              booking: booking,
              bookingData: paymentData,
            ),
          ),
        );
      }
    });
  }

  Map<String, dynamic> _getPaymentData() {
    return {
      "id": booking.bookingCode,
      "venueId": booking.field?.venueId,
      "venue": booking.field?.venue?.name ?? "Unknown Venue",
      "field": booking.field?.name ?? "Unknown Field",
      "date": _formatDate(booking.bookingDate),
      "time": booking.formattedTime,
      "price": booking.totalPrice.toInt(),
      "countdown": _getCountdown(),
    };
  }

  String _formatDate(String dateStr) {
    try {
      // Remove time portion if exists (e.g., "2025-12-31T00:00:00" -> "2025-12-31")
      String cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      // Fallback: just return date part without time
      return dateStr.split('T')[0];
    }
  }

  /// Jam dari API adalah UTC; ditampilkan sebagai WIB, sama seperti
  /// fe-web. Nilai mentahnya tetap dipakai kalau dikirim balik ke API.
  String _formatTimeRange(String startTime, String endTime) =>
      WaktuWib.rentang(startTime, endTime);

  String _getCountdown() {
    if (booking.expiresAt != null) {
      final remaining = booking.expiresAt!.difference(DateTime.now());
      if (remaining.isNegative) return "00:00:00";
      final hours = remaining.inHours.toString().padLeft(2, '0');
      final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
      final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
      return "$hours:$minutes:$seconds";
    }
    return "00:15:00";
  }

  void _goToTicket(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ETicketPage(booking: booking),
      ),
    );
  }

  void _rebook(BuildContext context) {
    final venueId = booking.field?.venueId;
    if (venueId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VenueDetailPage(
            venueId: venueId,
            venueName: booking.field?.venue?.name,
          ),
        ),
      );
    }
  }

  void _showRatingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        venueName: booking.field?.venue?.name ?? "Venue",
        bookingId: booking.id,
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final result = await BookingService.cancelBooking(booking.id);
    if (context.mounted) {
      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text("Pesanan berhasil dibatalkan"),
              ],
            ),
            backgroundColor: context.c.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        onRefresh();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal membatalkan pesanan'),
            backgroundColor: context.c.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String status = booking.status;
    Color themeColor;
    String statusText;
    String mainBtnText;
    Color btnColor;
    IconData statusIcon;
    VoidCallback? onMainAction;
    bool showSecondaryBtn = false;

    // --- CONFIG UI BERDASARKAN STATUS ---
    switch (status) {
      case 'pending':
        themeColor = context.c.warn;
        statusText = "Menunggu Pembayaran";
        mainBtnText = "BAYAR SEKARANG";
        btnColor = context.c.accent;
        statusIcon = Icons.timer_outlined;
        onMainAction = () => _goToPaymentDirect(context);
        showSecondaryBtn = true;
        break;
      case 'confirmed':
        themeColor = context.c.accent;
        statusText = "Booking Confirmed";
        mainBtnText = "LIHAT E-TICKET";
        btnColor = context.c.accent;
        statusIcon = Icons.verified;
        onMainAction = () => _goToTicket(context);
        break;
      case 'cancelled':
        themeColor = context.c.danger;
        statusText = "Dibatalkan";
        mainBtnText = "BOOKING LAGI";
        btnColor = context.c.accent;
        statusIcon = Icons.cancel_outlined;
        onMainAction = () => _rebook(context);
        break;
      case 'completed':
        themeColor = context.c.ok;
        statusText = "Selesai";
        mainBtnText = "BERI RATING";
        btnColor = context.c.accent;
        statusIcon = Icons.thumb_up_alt_outlined;
        onMainAction = () => _showRatingDialog(context);
        break;
      case 'expired':
        themeColor = context.c.inkSoft;
        statusText = "Kadaluarsa";
        mainBtnText = "BOOKING LAGI";
        btnColor = context.c.accent;
        statusIcon = Icons.timer_off_outlined;
        onMainAction = () => _rebook(context);
        break;
      default:
        themeColor = context.c.inkSoft;
        statusText = "Unknown";
        mainBtnText = "DETAIL";
        btnColor = context.c.accent;
        statusIcon = Icons.help_outline;
        onMainAction = () {};
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4)
          )
        ],
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, size: 18, color: themeColor),
                    const SizedBox(width: 8),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: themeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13
                      )
                    ),
                  ],
                ),
                if (status == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: context.c.surface,
                      borderRadius: BorderRadius.circular(10)
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.av_timer, size: 14, color: context.c.danger),
                        const SizedBox(width: 4),
                        Text(
                          _getCountdown(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: context.c.danger
                          )
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // BODY
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: context.c.surface,
                    borderRadius: BorderRadius.circular(16)
                  ),
                  child: Icon(Icons.sports_soccer, color: context.c.inkSoft),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.field?.venue?.name ?? "Unknown Venue",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: context.c.ink
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.field?.name ?? "Unknown Field",
                        style: TextStyle(color: context.c.inkSoft, fontSize: 13)
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: context.c.inkSoft),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(booking.bookingDate),
                                style: TextStyle(
                                  color: context.c.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500
                                )
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 12, color: context.c.inkSoft),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeRange(booking.startTime, booking.endTime),
                                style: TextStyle(
                                  color: context.c.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500
                                )
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: context.c.line, thickness: 1),

          // FOOTER
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Total Harga",
                          style: TextStyle(fontSize: 11, color: context.c.inkSoft)
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.formattedTotalPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: context.c.ink
                          )
                        ),
                      ],
                    ),
                    if (status == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.c.info.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: context.c.info.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, size: 14, color: context.c.info),
                            SizedBox(width: 4),
                            Text(
                              "QRIS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.c.info
                              )
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (showSecondaryBtn) ...[
                      Expanded(
                        flex: 1,
                        child: OutlinedButton(
                          onPressed: () => _goToPaymentSelector(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.c.ink,
                            side: BorderSide(color: context.c.line),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            "Ganti",
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.c.ink)
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: onMainAction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: btnColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999)
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                        ),
                        child: Text(
                          mainBtnText,
                          style: TextStyle(
                            color: context.c.onAccent,
                            fontWeight: FontWeight.w700
                          )
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 2. PAYMENT SELECTOR SHEET (MENU PILIH METODE BAYAR)
// =========================================================
class PaymentSelectorSheet extends StatelessWidget {
  final int totalPrice;

  const PaymentSelectorSheet({super.key, required this.totalPrice});

  @override
  Widget build(BuildContext context) {
    String formatCurrency(int amount) {
      return "Rp ${amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.'
      )}";
    }

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Sheet
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.c.line,
              borderRadius: BorderRadius.circular(10)
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Pilih Pembayaran",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.c.ink)
            ),
          ),
          Divider(height: 1, color: context.c.line),

          // Ringkasan Tagihan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: context.c.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total Tagihan", style: TextStyle(color: context.c.inkSoft)),
                Text(
                  formatCurrency(totalPrice),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: context.c.ink
                  )
                ),
              ],
            ),
          ),

          // List Metode
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSectionTitle(context, "Rekomendasi"),
                _buildPaymentOption(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: "QRIS (Gopay/OVO/Dana)",
                  fee: 700,
                  color: context.c.info,
                  isRecommended: true
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(context, "Virtual Account"),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: "BCA Virtual Account",
                  fee: 2500,
                  color: Colors.purple
                ),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: "Mandiri Virtual Account",
                  fee: 2500,
                  color: context.c.info!
                ),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: "BRI Virtual Account",
                  fee: 2500,
                  color: context.c.warn
                ),
                const SizedBox(height: 20),
                _buildSectionTitle(context, "Gerai Retail"),
                _buildPaymentOption(
                  context,
                  icon: Icons.storefront,
                  title: "Alfamart / Indomaret",
                  fee: 5000,
                  color: context.c.danger
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: context.c.inkSoft
        )
      ),
    );
  }

  Widget _buildPaymentOption(BuildContext context, {
    required IconData icon,
    required String title,
    required int fee,
    required Color color,
    bool isRecommended = false
  }) {
    int finalPrice = totalPrice + fee;

    String formatCurrency(int amount) => "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";

    return InkWell(
      onTap: () {
        Navigator.pop(context, {
          "method": title,
          "fee": fee,
          "total": finalPrice
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.c.raised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? context.c.accent : context.c.line
          ),
          boxShadow: [
            if(isRecommended)
              BoxShadow(
                color: context.c.accent.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4)
              )
          ]
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: context.c.ink
                          ),
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      if(isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: context.c.accent,
                            borderRadius: BorderRadius.circular(4)
                          ),
                          child: Text(
                            "PROMO",
                            style: TextStyle(
                              fontSize: 8,
                              color: context.c.onAccent,
                              fontWeight: FontWeight.bold
                            )
                          ),
                        )
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fee == 0 ? "Bebas Biaya Admin" : "Biaya Admin: ${formatCurrency(fee)}",
                    style: TextStyle(
                      fontSize: 12,
                      color: fee == 0 ? context.c.ok : context.c.inkSoft
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: context.c.inkSoft),
          ],
        ),
      ),
    );
  }
}

// =========================================================
// 3. PAYMENT WAITING PAGE (INSTRUKSI BAYAR)
// =========================================================
class PaymentWaitingPage extends StatefulWidget {
  final Booking booking;
  final Map<String, dynamic> bookingData;

  const PaymentWaitingPage({
    super.key,
    required this.booking,
    required this.bookingData,
  });

  @override
  State<PaymentWaitingPage> createState() => _PaymentWaitingPageState();
}

class _PaymentWaitingPageState extends State<PaymentWaitingPage> {
  bool _isProcessing = false;

  Future<void> _simulatePayment() async {
    setState(() => _isProcessing = true);

    final result = await BookingService.simulatePayment(widget.booking.id);

    if (mounted) {
      setState(() => _isProcessing = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text("Pembayaran berhasil!"),
              ],
            ),
            backgroundColor: context.c.ok,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Navigate back to HomePage with Transaksi tab selected
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePageWithTab(initialIndex: 2),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal memproses pembayaran'),
            backgroundColor: context.c.danger,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking() async {
    setState(() => _isProcessing = true);

    final result = await BookingService.cancelBooking(widget.booking.id);

    if (mounted) {
      setState(() => _isProcessing = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text("Pesanan berhasil dibatalkan"),
              ],
            ),
            backgroundColor: context.c.danger,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Navigate back to HomePage with Transaksi tab selected
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const HomePageWithTab(initialIndex: 2),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal membatalkan pesanan'),
            backgroundColor: context.c.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String method = widget.bookingData['selectedMethod'] ?? "Metode Pembayaran";
    int subtotal = widget.bookingData['price'] ?? 0;
    int adminFee = widget.bookingData['adminFee'] ?? 0;
    int total = widget.bookingData['totalWithFee'] ?? subtotal;

    String formatCurrency(int amount) => "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";

    // Get QR string from payment if available
    String? qrString = widget.booking.payment?.qrString;
    String paymentCode = qrString ?? "8800 1234 5678 9012";

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        title: Text(
          "Selesaikan Pembayaran",
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.c.surface,
        systemOverlayStyle: gayaOverlay(context),
        elevation: 0,
        iconTheme: IconThemeData(color: context.c.ink),
      ),
      body: _isProcessing
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.c.accent),
                  SizedBox(height: 16),
                  Text('Memproses...', style: TextStyle(color: context.c.inkSoft)),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countdown Timer Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.warn.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.warn.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.c.warn.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.timer_outlined, color: context.c.warn, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Selesaikan pembayaran dalam",
                                style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.bookingData['countdown'] ?? "00:15:00",
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: context.c.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Detail Booking Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.raised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Detail Booking",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.c.ink),
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow("Kode Booking", widget.booking.bookingCode),
                        _buildDetailRow("Venue", widget.bookingData['venue'] ?? "-"),
                        _buildDetailRow("Lapangan", widget.bookingData['field'] ?? "-"),
                        _buildDetailRow("Tanggal", widget.bookingData['date'] ?? "-"),
                        _buildDetailRow("Waktu", widget.bookingData['time'] ?? "-"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metode Pembayaran Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.raised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Metode Pembayaran",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.c.ink),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.c.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                method.contains("QRIS") ? Icons.qr_code_scanner : Icons.account_balance,
                                color: context.c.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                method,
                                style: TextStyle(fontWeight: FontWeight.w600, color: context.c.ink),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.c.surface,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Text(
                                method.contains("QRIS") ? "Scan QR Code" : "Nomor Virtual Account",
                                style: TextStyle(fontSize: 11, color: context.c.inkSoft),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    paymentCode,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                      color: context.c.ink,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("Nomor disalin!")),
                                      );
                                    },
                                    child: Icon(Icons.copy, size: 18, color: context.c.accent),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rincian Pembayaran Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.c.raised,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.c.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Rincian Pembayaran",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.c.ink),
                        ),
                        const SizedBox(height: 12),
                        _buildPriceRow("Subtotal", formatCurrency(subtotal)),
                        const SizedBox(height: 8),
                        _buildPriceRow("Biaya Admin", formatCurrency(adminFee)),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(height: 1, color: context.c.line),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Total Pembayaran",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.c.ink),
                            ),
                            Text(
                              formatCurrency(total),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: context.c.ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Button Konfirmasi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _simulatePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.c.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        "Saya Sudah Bayar",
                        style: TextStyle(
                          color: context.c.onAccent,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
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
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: context.c.danger.withValues(alpha: 0.15),
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
                                    "Batalkan Pesanan?",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: context.c.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Apakah kamu yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dibatalkan.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.c.inkSoft,
                                      fontSize: 14,
                                      height: 1.4,
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
                                            "Kembali",
                                            style: TextStyle(
                                              color: context.c.ink,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            _cancelBooking();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: context.c.danger,
                                            padding: const EdgeInsets.symmetric(vertical: 14),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                          ),
                                          child: const Text(
                                            "Ya, Batalkan",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
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
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.c.line),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        "Batalkan Pesanan",
                        style: TextStyle(
                          color: context.c.danger,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: context.c.inkSoft, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: context.c.ink),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: context.c.inkSoft, fontSize: 13)),
        Text(value, style: TextStyle(fontSize: 13, color: context.c.ink)),
      ],
    );
  }
}

// =========================================================
// 4. HALAMAN E-TICKET (REDESIGN)
// =========================================================
class TicketDetailPage extends StatelessWidget {
  final Booking booking;

  const TicketDetailPage({super.key, required this.booking});

  String _formatDate(String dateStr) {
    try {
      String cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return DateFormat('EEEE, dd MMMM yyyy', 'id').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  String _formatShortDate(String dateStr) {
    try {
      String cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  void _shareTicket() {
    final String shareText = '''
🎫 E-Ticket Sportago

📍 ${booking.field?.venue?.name ?? "Venue"}
⚽ ${booking.field?.name ?? "Field"}
📅 ${_formatDate(booking.bookingDate)}
⏰ ${booking.formattedTime}

🔑 Kode Booking: ${booking.bookingCode}

Tunjukkan e-ticket ini saat datang ke venue.
''';

    Share.share(shareText, subject: 'E-Ticket Sportago - ${booking.field?.venue?.name}');
  }

  bool get _isChatEnabled {
    return booking.status == 'confirmed';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.c.raised,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.c.line),
                      ),
                      child: Icon(Icons.arrow_back_ios_new, color: context.c.ink, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "E-Ticket",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.c.ink,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _shareTicket,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: context.c.raised,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: context.c.line),
                      ),
                      child: Icon(Icons.share, color: context.c.ink, size: 20),
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: context.c.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Ticket Card
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.c.raised,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.c.line),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            // Top Section - Venue Info
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Status Badge
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: context.c.ok.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(color: context.c.ok.withValues(alpha: 0.4)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, size: 16, color: context.c.ok),
                                        const SizedBox(width: 6),
                                        Text(
                                          "Booking Confirmed",
                                          style: TextStyle(
                                            color: context.c.ok,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Venue Logo/Icon
                                  Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: context.c.accent,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: context.c.accent.withValues(alpha: 0.3),
                                          blurRadius: 15,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Icon(Icons.sports_soccer, color: context.c.onAccent, size: 40),
                                  ),
                                  const SizedBox(height: 16),

                                  // Venue Name
                                  Text(
                                    booking.field?.venue?.name ?? "Venue",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                      color: context.c.ink,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    booking.field?.name ?? "Field",
                                    style: TextStyle(
                                      color: context.c.inkSoft,
                                      fontSize: 15,
                                    ),
                                  ),
                                  if (booking.field?.venue?.address != null) ...[
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_on_outlined, size: 14, color: context.c.inkSoft),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            booking.field?.venue?.address ?? "-",
                                            style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            // Dotted Divider with Circles
                            Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      return Row(
                                        children: List.generate(
                                          (constraints.maxWidth / 8).floor(),
                                          (index) => Container(
                                            width: 4,
                                            height: 2,
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            decoration: BoxDecoration(
                                              color: context.c.line,
                                              borderRadius: BorderRadius.circular(1),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Positioned(
                                  left: -15,
                                  top: -14,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: context.c.surface,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: -15,
                                  top: -14,
                                  child: Container(
                                    width: 30,
                                    height: 30,
                                    decoration: BoxDecoration(
                                      color: context.c.surface,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Section - Date, Time, QR
                            Container(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Date and Time Row
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildInfoCard(
                                          context,
                                          icon: Icons.calendar_today_rounded,
                                          label: "TANGGAL",
                                          value: _formatShortDate(booking.bookingDate),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _buildInfoCard(
                                          context,
                                          icon: Icons.access_time_rounded,
                                          label: "WAKTU",
                                          value: booking.formattedTime,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Duration Card
                                  _buildInfoCard(
                                    context,
                                    icon: Icons.timer_outlined,
                                    label: "DURASI",
                                    value: "${booking.durationHours} Jam",
                                    fullWidth: true,
                                  ),
                                  const SizedBox(height: 24),

                                  // QR Code
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.grey.shade200, width: 2),
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 180,
                                          height: 180,
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: const Icon(
                                            Icons.qr_code_2_rounded,
                                            size: 150,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                          decoration: BoxDecoration(
                                            color: context.c.onAccent.withValues(alpha: 0.06),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Column(
                                            children: [
                                              Text(
                                                "KODE BOOKING",
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600],
                                                  fontWeight: FontWeight.w500,
                                                  letterSpacing: 1,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                booking.bookingCode,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 24,
                                                  letterSpacing: 3,
                                                  color: context.c.onAccent,
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
                      const SizedBox(height: 16),

                      // Info Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.c.warn.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.c.warn.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: context.c.warn.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.info_outline_rounded, color: context.c.warn, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Tunjukkan QR code atau kode booking ke petugas saat datang ke venue",
                                style: TextStyle(
                                  color: context.c.warn,
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Action Buttons
                      if (_isChatEnabled)
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatPage(booking: booking),
                                ),
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
                                Icon(Icons.chat_bubble_outline_rounded, color: context.c.onAccent, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "Chat dengan Partner",
                                  style: TextStyle(
                                    color: context.c.onAccent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (_isChatEnabled) const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: _shareTicket,
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.c.line, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.share_outlined, color: context.c.ink, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Bagikan",
                                      style: TextStyle(
                                        color: context.c.ink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SizedBox(
                              height: 54,
                              child: OutlinedButton(
                                onPressed: () {
                                  // Navigate to venue detail
                                  final venueId = booking.field?.venueId;
                                  if (venueId != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => VenueDetailPage(venueId: venueId),
                                      ),
                                    );
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: context.c.line, width: 1.5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.location_on_outlined, color: context.c.ink, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      "Lihat Venue",
                                      style: TextStyle(
                                        color: context.c.ink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    bool fullWidth = false,
  }) {
    return Container(
      width: fullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.c.line),
      ),
      child: Row(
        mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: context.c.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: context.c.accent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.c.inkSoft,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
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
        ],
      ),
    );
  }
}

class RatingDialog extends StatefulWidget {
  final String venueName;
  final int bookingId;

  const RatingDialog({super.key, required this.venueName, required this.bookingId});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _selectedStars = 0;
  final TextEditingController _reviewController = TextEditingController();

  String _getRatingLabel() {
    switch (_selectedStars) {
      case 1: return "Sangat Buruk";
      case 2: return "Buruk";
      case 3: return "Cukup";
      case 4: return "Bagus";
      case 5: return "Sangat Bagus";
      default: return "Ketuk untuk memberi rating";
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.c.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.rate_review_rounded,
                color: context.c.accent,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              "Beri Penilaian",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: context.c.ink,
              ),
            ),
            const SizedBox(height: 8),

            Text(
              "Bagaimana pengalaman main di ${widget.venueName}?",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.c.inkSoft,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: context.c.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      bool isSelected = index < _selectedStars;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedStars = index + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: isSelected ? context.c.accent : context.c.inkSoft,
                            size: 36,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getRatingLabel(),
                    style: TextStyle(
                      color: _selectedStars > 0 ? context.c.accent : context.c.inkSoft,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _reviewController,
              style: TextStyle(color: context.c.ink),
              decoration: InputDecoration(
                hintText: "Tulis ulasan (opsional)...",
                hintStyle: TextStyle(color: context.c.inkSoft, fontSize: 14),
                filled: true,
                fillColor: context.c.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.line),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.line),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.c.accent, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              maxLines: 3,
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
                      "Nanti Saja",
                      style: TextStyle(
                        color: context.c.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedStars > 0 ? () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 20),
                              SizedBox(width: 12),
                              Text("Terima kasih atas penilaiannya!"),
                            ],
                          ),
                          backgroundColor: context.c.accent,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.c.accent,
                      disabledBackgroundColor: context.c.line,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      "Kirim",
                      style: TextStyle(
                        color: context.c.onAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
