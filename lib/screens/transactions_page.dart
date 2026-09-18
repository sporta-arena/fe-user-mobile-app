import 'dart:async';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../utils/waktu_wib.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_tokens.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'login_page.dart';
import 'venue_detail_page.dart';
import 'e_ticket_page.dart';
import 'chat/chat_page.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
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
      if (mounted && result.success && result.bookings != null) {
        setState(() {
          _allBookings = result.bookings!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = result.message ?? 'Gagal memuat pesanan';
          _isLoading = false;
        });
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

  List<Booking> _getFilteredBookings(String filterStatus) {
    switch (filterStatus) {
      case 'upcoming':
        // Mendatang = confirmed atau checked_in bookings yang belum selesai
        return _allBookings.where((b) {
          if (b.status != 'confirmed' && b.status != 'checked_in') return false;
          try {
            final bookingDate = DateTime.parse(b.bookingDate.split('T')[0]);
            final today = DateTime.now();
            final todayDate = DateTime(today.year, today.month, today.day);
            return bookingDate.isAfter(todayDate) ||
                bookingDate.isAtSameMomentAs(todayDate);
          } catch (e) {
            return true;
          }
        }).toList();
      case 'pending':
        // Menunggu = pending payment
        return _allBookings.where((b) => b.status == 'pending').toList();
      case 'history':
        // Riwayat = completed + cancelled + expired + confirmed/checked_in yang sudah lewat
        return _allBookings.where((b) {
          if (b.status == 'completed' ||
              b.status == 'cancelled' ||
              b.status == 'expired') {
            return true;
          }
          if (b.status == 'confirmed' || b.status == 'checked_in') {
            try {
              final bookingDate = DateTime.parse(b.bookingDate.split('T')[0]);
              final today = DateTime.now();
              final todayDate = DateTime(today.year, today.month, today.day);
              return bookingDate.isBefore(todayDate);
            } catch (e) {
              return false;
            }
          }
          return false;
        }).toList();
      default:
        return _allBookings;
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
            "Pesanan",
            style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
          ),
          backgroundColor: context.c.surface,
          elevation: 0,
          systemOverlayStyle: gayaOverlay(context),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: context.c.inkSoft),
              const SizedBox(height: 16),
              Text(
                "Masuk dulu untuk melihat pesanan",
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: Text(
                  "Login",
                  style: TextStyle(
                    color: context.c.onAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        elevation: 0,
        systemOverlayStyle: gayaOverlay(context),
        title: Text(
          'Pesanan',
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: context.c.accent,
          unselectedLabelColor: context.c.inkSoft,
          indicatorColor: context.c.accent,
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'Mendatang'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: context.c.accent),
                  SizedBox(height: 16),
                  Text(
                    'Memuat pesanan...',
                    style: TextStyle(color: context.c.inkSoft),
                  ),
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
                      style: TextStyle(color: context.c.onAccent),
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList('upcoming'),
                _buildTransactionList('pending'),
                _buildTransactionList('history'),
              ],
            ),
    );
  }

  Widget _buildTransactionList(String status) {
    final bookings = _getFilteredBookings(status);

    if (bookings.isEmpty) {
      String emptyMessage;
      IconData emptyIcon;

      switch (status) {
        case 'upcoming':
          emptyMessage = 'Tidak ada booking mendatang';
          emptyIcon = Icons.event_available;
          break;
        case 'pending':
          emptyMessage = 'Tidak ada pembayaran pending';
          emptyIcon = Icons.hourglass_empty;
          break;
        case 'history':
          emptyMessage = 'Belum ada riwayat main';
          emptyIcon = Icons.history;
          break;
        default:
          emptyMessage = 'Belum ada pesanan';
          emptyIcon = Icons.receipt_long_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: context.c.inkSoft),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: context.c.inkSoft, fontSize: 16),
            ),
            if (status == 'upcoming') ...[
              const SizedBox(height: 8),
              Text(
                'Yuk booking lapangan favoritmu!',
                style: TextStyle(color: context.c.inkSoft, fontSize: 13),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        return _BookingCard(booking: bookings[index], onRefresh: _loadBookings);
      },
    );
  }
}

// Booking Card with enhanced features for upcoming bookings
class _BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const _BookingCard({required this.booking, required this.onRefresh});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  Timer? _countdownTimer;
  String _countdownText = "";

  Booking get booking => widget.booking;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    // Only start timer for upcoming confirmed bookings
    if (_isUpcoming) {
      _countdownTimer = Timer.periodic(const Duration(minutes: 1), (_) {
        if (mounted) _updateCountdown();
      });
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  bool get _isUpcoming {
    return (booking.status == 'confirmed' || booking.status == 'checked_in');
  }

  void _updateCountdown() {
    if (!_isUpcoming) return;

    try {
      final bookingDate = DateTime.parse(booking.bookingDate.split('T')[0]);
      final timeParts = booking.startTime.split(':');
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );

      final now = DateTime.now();
      final diff = bookingDateTime.difference(now);

      if (diff.isNegative) {
        setState(() => _countdownText = "Sedang berlangsung");
      } else if (diff.inDays > 0) {
        setState(() => _countdownText = "Mulai dalam ${diff.inDays} hari");
      } else if (diff.inHours > 0) {
        final hours = diff.inHours;
        final minutes = diff.inMinutes % 60;
        setState(() => _countdownText = "Mulai dalam ${hours}j ${minutes}m");
      } else if (diff.inMinutes > 0) {
        setState(() => _countdownText = "Mulai dalam ${diff.inMinutes} menit");
      } else {
        setState(() => _countdownText = "Sebentar lagi");
      }
    } catch (e) {
      setState(() => _countdownText = "");
    }
  }

  Future<void> _openMaps() async {
    final venue = booking.field?.venue;
    if (venue == null) return;

    Uri uri;
    if (venue.latitude != null && venue.longitude != null) {
      // Use coordinates if available
      uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=${venue.latitude},${venue.longitude}',
      );
    } else {
      // Fallback to address search
      final encodedAddress = Uri.encodeComponent(
        '${venue.name}, ${venue.address}, ${venue.city}',
      );
      uri = Uri.parse(
        'https://www.google.com/maps/search/?api=1&query=$encodedAddress',
      );
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ChatPage(booking: booking)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = booking.status;
    Color themeColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'pending':
        themeColor = context.c.warn;
        statusText = "Menunggu Pembayaran";
        statusIcon = Icons.timer_outlined;
        break;
      case 'confirmed':
        themeColor = context.c.accent;
        statusText = "Terkonfirmasi";
        statusIcon = Icons.verified;
        break;
      case 'checked_in':
        themeColor = context.c.accent;
        statusText = "Sedang Bermain";
        statusIcon = Icons.sports;
        break;
      case 'cancelled':
        themeColor = context.c.danger;
        statusText = "Dibatalkan";
        statusIcon = Icons.cancel_outlined;
        break;
      case 'completed':
        themeColor = context.c.ok;
        statusText = "Selesai";
        statusIcon = Icons.check_circle_outline;
        break;
      case 'expired':
        themeColor = Colors.grey;
        statusText = "Kadaluarsa";
        statusIcon = Icons.timer_off_outlined;
        break;
      default:
        themeColor = Colors.grey;
        statusText = status;
        statusIcon = Icons.help_outline;
    }

    final venueAddress = booking.field?.venue?.address;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(statusIcon, size: 16, color: themeColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: themeColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Countdown for upcoming bookings
                if (_isUpcoming && _countdownText.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: context.c.warn),
                        const SizedBox(width: 4),
                        Text(
                          _countdownText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: context.c.warn,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.field?.venue?.name ?? "Unknown Venue",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.field?.name ?? "-",
                  style: TextStyle(color: context.c.inkSoft, fontSize: 14),
                ),
                // Venue Address for upcoming bookings
                if (_isUpcoming &&
                    venueAddress != null &&
                    venueAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: context.c.inkSoft,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venueAddress,
                          style: TextStyle(
                            color: context.c.inkSoft,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: context.c.inkSoft,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(booking.bookingDate),
                      style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: context.c.inkSoft),
                    const SizedBox(width: 6),
                    Text(
                      booking.formattedTime,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  booking.formattedTotalPrice,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: context.c.accent,
                  ),
                ),
                const SizedBox(height: 12),
                // Quick action buttons for upcoming bookings
                if (_isUpcoming) ...[
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openMaps,
                          icon: const Icon(Icons.directions, size: 18),
                          label: const Text("Navigasi"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.c.accent,
                            side: BorderSide(color: context.c.accent),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(Icons.chat_outlined, size: 18),
                          label: const Text("Chat"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: context.c.ok,
                            side: BorderSide(color: context.c.ok),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
                _buildActionButton(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    switch (booking.status) {
      case 'pending':
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _goToPayment(context),
                icon: const Icon(Icons.payment, color: Colors.white, size: 18),
                label: const Text(
                  "BAYAR SEKARANG",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.ok,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(context),
                icon: Icon(Icons.close, color: context.c.danger, size: 18),
                label: Text(
                  "Batalkan",
                  style: TextStyle(color: context.c.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: context.c.danger),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      case 'confirmed':
      case 'checked_in':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ETicketPage(booking: booking),
                ),
              );
            },
            icon: Icon(
              Icons.confirmation_number,
              color: context.c.onAccent,
              size: 18,
            ),
            label: Text(
              "LIHAT E-TICKET",
              style: TextStyle(
                color: context.c.onAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.c.accent,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _rebook(context),
            icon: Icon(Icons.replay, size: 18, color: context.c.accent),
            label: Text(
              "BOOKING LAGI",
              style: TextStyle(color: context.c.accent),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: context.c.accent,
              side: BorderSide(color: context.c.accent),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        );
    }
  }

  String _formatDate(String dateStr) {
    try {
      String cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  void _goToPayment(BuildContext context) {
    String paymentMethod = booking.payment?.paymentMethod ?? "QRIS";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionPaymentWaitingPage(
          booking: booking,
          bookingData: {
            "id": booking.bookingCode,
            "venue": booking.field?.venue?.name ?? "Unknown",
            "field": booking.field?.name ?? "Unknown",
            "date": _formatDate(booking.bookingDate),
            "time": booking.formattedTime,
            "price": booking.totalPrice.toInt(),
            "selectedMethod": _getPaymentMethodDisplay(paymentMethod),
            "paymentMethod": paymentMethod,
            "totalWithFee":
                booking.payment?.amount.toInt() ?? booking.totalPrice.toInt(),
            "qrString": booking.payment?.qrString,
          },
          onPaymentComplete: widget.onRefresh,
        ),
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

  Future<void> _cancelBooking(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Batalkan Pesanan?",
          style: TextStyle(color: context.c.ink),
        ),
        content: Text(
          "Apakah Anda yakin ingin membatalkan pesanan ini?",
          style: TextStyle(color: context.c.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Tidak", style: TextStyle(color: context.c.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.c.danger),
            child: const Text(
              "Ya, Batalkan",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final result = await BookingService.cancelBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? "Pesanan dibatalkan"
                  : (result.message ?? "Gagal membatalkan"),
            ),
            backgroundColor: result.success ? context.c.ok : context.c.danger,
          ),
        );
        if (result.success) widget.onRefresh();
      }
    }
  }
}

// =========================================================
// TRANSACTION BOOKING CARD
// =========================================================
class TransactionBookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const TransactionBookingCard({
    super.key,
    required this.booking,
    required this.onRefresh,
  });

  @override
  State<TransactionBookingCard> createState() => _TransactionBookingCardState();
}

class _TransactionBookingCardState extends State<TransactionBookingCard> {
  late Timer? _timer;
  String _countdown = "00:00:00";

  Booking get booking => widget.booking;
  VoidCallback get onRefresh => widget.onRefresh;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    if (booking.status == 'pending' && booking.expiresAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateCountdown();
      });
    } else {
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    if (!mounted) return;

    if (booking.expiresAt != null) {
      final remaining = booking.expiresAt!.difference(DateTime.now());
      if (remaining.isNegative) {
        if (mounted) setState(() => _countdown = "00:00:00");
        _timer?.cancel();
        // Auto refresh when expired
        if (mounted) onRefresh();
      } else {
        final hours = remaining.inHours.toString().padLeft(2, '0');
        final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
        final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
        if (mounted) setState(() => _countdown = "$hours:$minutes:$seconds");
      }
    } else {
      // 10 menit, bukan 15: config/payment.php menahan slot 10 menit
      // untuk semua metode. Angka cadangan ini cuma terpakai kalau
      // expires_at tidak ikut terkirim, dan kalau salah ia menjanjikan
      // waktu yang tidak ada.
      if (mounted) setState(() => _countdown = "00:10:00");
    }
  }

  void _goToPaymentDirect(BuildContext context) {
    Map<String, dynamic> paymentData = _getPaymentData();

    // Use actual payment method from booking
    String paymentMethod = booking.payment?.paymentMethod ?? "QRIS";
    String displayMethod = _getPaymentMethodDisplay(paymentMethod);

    paymentData["selectedMethod"] = displayMethod;
    paymentData["paymentMethod"] = paymentMethod;
    paymentData["adminFee"] = 0; // Already included in total
    paymentData["totalWithFee"] =
        booking.payment?.amount.toInt() ?? booking.totalPrice.toInt();
    paymentData["qrString"] = booking.payment?.qrString;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionPaymentWaitingPage(
          booking: booking,
          bookingData: paymentData,
          onPaymentComplete: onRefresh,
        ),
      ),
    );
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
      "countdown": _countdown,
    };
  }

  String _formatDate(String dateStr) {
    try {
      String cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  /// Jam dari API adalah UTC; ditampilkan sebagai WIB, sama seperti
  /// fe-web. Nilai mentahnya tetap dipakai kalau dikirim balik ke API.
  String _formatTimeRange(String startTime, String endTime) =>
      WaktuWib.rentang(startTime, endTime);

  void _goToTicket(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ETicketPage(booking: booking)),
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

  Future<void> _cancelBooking(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.c.raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          "Batalkan Pesanan?",
          style: TextStyle(color: context.c.ink),
        ),
        content: Text(
          "Apakah Anda yakin ingin membatalkan pesanan ini?",
          style: TextStyle(color: context.c.inkSoft),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Tidak", style: TextStyle(color: context.c.inkSoft)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.c.danger),
            child: const Text(
              "Ya, Batalkan",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    String status = booking.status;
    Color themeColor;
    String statusText;
    String mainBtnText;
    Color btnColor = context.c.accent;
    IconData statusIcon;
    VoidCallback? onMainAction;
    bool showCancelBtn = false;

    switch (status) {
      case 'pending':
        themeColor = context.c.warn;
        statusText = "Menunggu Pembayaran";
        mainBtnText = "BAYAR SEKARANG";
        statusIcon = Icons.timer_outlined;
        onMainAction = () => _goToPaymentDirect(context);
        showCancelBtn = true;
        break;
      case 'confirmed':
        themeColor = context.c.accent;
        statusText = "Terkonfirmasi";
        mainBtnText = "LIHAT E-TICKET";
        statusIcon = Icons.verified;
        onMainAction = () => _goToTicket(context);
        break;
      case 'checked_in':
        themeColor = context.c.accent;
        statusText = "Sedang Bermain";
        mainBtnText = "LIHAT E-TICKET";
        statusIcon = Icons.sports;
        onMainAction = () => _goToTicket(context);
        break;
      case 'cancelled':
        themeColor = context.c.danger;
        statusText = "Dibatalkan";
        mainBtnText = "BOOKING LAGI";
        statusIcon = Icons.cancel_outlined;
        onMainAction = () => _rebook(context);
        break;
      case 'completed':
        themeColor = context.c.ok;
        statusText = "Selesai";
        mainBtnText = "BOOKING LAGI";
        statusIcon = Icons.check_circle_outline;
        onMainAction = () => _rebook(context);
        break;
      case 'expired':
        themeColor = Colors.grey;
        statusText = "Kadaluarsa";
        mainBtnText = "BOOKING LAGI";
        statusIcon = Icons.timer_off_outlined;
        onMainAction = () => _rebook(context);
        break;
      default:
        themeColor = Colors.grey;
        statusText = "Unknown";
        mainBtnText = "DETAIL";
        statusIcon = Icons.help_outline;
        onMainAction = () {};
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: context.c.raised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.c.line),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
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
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (status == 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: context.c.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.av_timer, size: 14, color: context.c.danger),
                        const SizedBox(width: 4),
                        Text(
                          _countdown,
                          style: TextStyle(
                            fontSize: 12,
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
                    borderRadius: BorderRadius.circular(16),
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
                          color: context.c.ink,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.field?.name ?? "Unknown Field",
                        style: TextStyle(
                          color: context.c.inkSoft,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 12,
                                color: context.c.inkSoft,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(booking.bookingDate),
                                style: TextStyle(
                                  color: context.c.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 12,
                                color: context.c.inkSoft,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeRange(
                                  booking.startTime,
                                  booking.endTime,
                                ),
                                style: TextStyle(
                                  color: context.c.inkSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
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
                          style: TextStyle(
                            fontSize: 11,
                            color: context.c.inkSoft,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.formattedTotalPrice,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: context.c.ink,
                          ),
                        ),
                      ],
                    ),
                    if (status == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.c.infoSoft,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: context.c.info.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.qr_code,
                              size: 14,
                              color: context.c.info,
                            ),
                            SizedBox(width: 4),
                            Text(
                              "QRIS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: context.c.info,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Main action button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: onMainAction,
                    icon: Icon(
                      status == 'pending'
                          ? Icons.payment
                          : status == 'confirmed' || status == 'checked_in'
                          ? Icons.confirmation_number
                          : Icons.replay,
                      color: status == 'pending'
                          ? Colors.white
                          : context.c.onAccent,
                      size: 20,
                    ),
                    label: Text(
                      mainBtnText,
                      style: TextStyle(
                        color: status == 'pending'
                            ? Colors.white
                            : context.c.onAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'pending'
                          ? context.c.ok
                          : btnColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                if (showCancelBtn) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelBooking(context),
                      icon: Icon(
                        Icons.close,
                        color: context.c.danger,
                        size: 20,
                      ),
                      label: Text(
                        "Batalkan Pesanan",
                        style: TextStyle(
                          color: context.c.danger,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: context.c.danger),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// =========================================================
// PAYMENT WAITING PAGE FOR TRANSACTIONS
// =========================================================
class TransactionPaymentWaitingPage extends StatefulWidget {
  final Booking booking;
  final Map<String, dynamic> bookingData;
  final VoidCallback onPaymentComplete;

  const TransactionPaymentWaitingPage({
    super.key,
    required this.booking,
    required this.bookingData,
    required this.onPaymentComplete,
  });

  @override
  State<TransactionPaymentWaitingPage> createState() =>
      _TransactionPaymentWaitingPageState();
}

class _TransactionPaymentWaitingPageState
    extends State<TransactionPaymentWaitingPage> {
  bool _isProcessing = false;

  /// Sisa waktu pembayaran, dihitung sendiri di halaman ini.
  ///
  /// Sebelumnya angka ini diambil dari `bookingData['countdown']`, yaitu
  /// string yang disalin sekali saat halaman dibuka lalu tidak pernah
  /// berubah. Kalau kunci itu kosong, yang tampil adalah "00:15:00" yang
  /// ditulis langsung di kode. Akibatnya pemesanan yang SUDAH lewat pun
  /// terlihat masih punya sisa 15 menit, dan angkanya diam di tempat.
  Timer? _pewaktu;
  String _sisaWaktu = '';
  bool _sudahLewat = false;

  @override
  void initState() {
    super.initState();
    _hitungSisaWaktu();
    // Satu detik sekali, dan hanya selama masih ada yang dihitung.
    _pewaktu = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _hitungSisaWaktu(),
    );
  }

  @override
  void dispose() {
    _pewaktu?.cancel();
    super.dispose();
  }

  void _hitungSisaWaktu() {
    if (!mounted) return;

    final batas = widget.booking.expiresAt;
    if (batas == null) {
      // Tanpa batas waktu dari server, tidak ada yang bisa dihitung.
      // Menampilkan angka apa pun di sini berarti mengarang.
      _pewaktu?.cancel();
      setState(() {
        _sisaWaktu = '';
        _sudahLewat = false;
      });
      return;
    }

    final sisa = batas.difference(DateTime.now());
    if (sisa.isNegative) {
      _pewaktu?.cancel();
      setState(() {
        _sisaWaktu = '00:00:00';
        _sudahLewat = true;
      });
      return;
    }

    String duaDigit(int n) => n.toString().padLeft(2, '0');
    setState(() {
      _sisaWaktu =
          '${duaDigit(sisa.inHours)}:'
          '${duaDigit(sisa.inMinutes % 60)}:'
          '${duaDigit(sisa.inSeconds % 60)}';
      _sudahLewat = false;
    });
  }

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
        widget.onPaymentComplete();
        Navigator.pop(context);
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
        widget.onPaymentComplete();
        Navigator.pop(context);
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
    String paymentMethod = (widget.bookingData['paymentMethod'] ?? "QRIS")
        .toString()
        .toUpperCase();
    bool isQRIS = paymentMethod == "QRIS";

    // Use actual booking data
    // Komponen biaya diambil dari server, bukan disusun ulang di sini.
    // `subtotal` dari server sudah bersih dari biaya platform dan biaya
    // admin, jadi ia yang mewakili harga lapangannya.
    final int biayaPlatform = widget.booking.platformFee.toInt();
    final int biayaAdmin = widget.booking.paymentFee.toInt();
    final int hargaLapangan = widget.booking.subtotal > 0
        ? widget.booking.subtotal.toInt()
        : (widget.booking.totalPrice.toInt() - biayaPlatform - biayaAdmin);
    final int total =
        widget.booking.payment?.amount.toInt() ??
        widget.booking.totalPrice.toInt();

    String formatCurrency(int amount) =>
        "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";

    String? qrString = widget.booking.payment?.qrString;
    // Nomor VA yang sebenarnya, dari server. Sebelum ini halaman ini
    // memakai qrString sebagai nomor VA, dan kalau kosong (dan untuk VA
    // memang selalu kosong) ia jatuh ke "8800 1234 5678 9012" yang
    // ditulis langsung di kode. Nomor itu karangan; pelanggan yang
    // mentransfer ke sana kehilangan uangnya dan pemesanannya tetap
    // tidak terbayar.
    final String? nomorVa = widget.booking.payment?.virtualAccountNo;

    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        title: Text(
          "Selesaikan Pembayaran",
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold),
        ),
        backgroundColor: context.c.surface,
        elevation: 0,
        systemOverlayStyle: gayaOverlay(context),
        iconTheme: IconThemeData(color: context.c.ink),
      ),
      body: SafeArea(
        // Bilah navigasi menumpuk di atas isi layar sejak
        // targetSdk 35. top:false karena AppBar sudah
        // menyisihkan bagian atasnya sendiri.
        top: false,
        child: _isProcessing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: context.c.accent),
                    SizedBox(height: 16),
                    Text(
                      'Memproses...',
                      style: TextStyle(color: context.c.inkSoft),
                    ),
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
                        color: context.c.raised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: context.c.warn.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: context.c.warn.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.timer_outlined,
                              color: context.c.warn,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _sudahLewat
                                      ? 'Batas waktu pembayaran terlampaui'
                                      : (_sisaWaktu.isEmpty
                                            ? 'Menunggu pembayaran'
                                            : 'Selesaikan pembayaran dalam'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.c.inkSoft,
                                  ),
                                ),
                                if (_sisaWaktu.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _sisaWaktu,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: _sudahLewat
                                          ? context.c.inkSoft
                                          : context.c.danger,
                                    ),
                                  ),
                                ],
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
                          Row(
                            children: [
                              Icon(
                                Icons.receipt_long,
                                color: context.c.inkSoft,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Detail Booking",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.c.ink,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20, color: context.c.line),
                          _buildDetailRow(
                            "Kode Booking",
                            widget.booking.bookingCode,
                          ),
                          _buildDetailRow(
                            "Venue",
                            widget.booking.field?.venue?.name ?? "-",
                          ),
                          _buildDetailRow(
                            "Lapangan",
                            widget.booking.field?.name ?? "-",
                          ),
                          _buildDetailRow(
                            "Tanggal",
                            widget.bookingData['date'] ?? "-",
                          ),
                          _buildDetailRow(
                            "Waktu",
                            widget.booking.formattedTime,
                          ),
                          _buildDetailRow(
                            "Durasi",
                            "${widget.booking.durationHours} jam",
                          ),
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
                          Row(
                            children: [
                              Icon(
                                Icons.payment,
                                color: context.c.inkSoft,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Metode Pembayaran",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.c.ink,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20, color: context.c.line),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.c.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isQRIS
                                      ? Icons.qr_code_scanner
                                      : Icons.account_balance,
                                  color: context.c.accent,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    method,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: context.c.ink,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Payment Display - QRIS or VA
                          if (isQRIS) ...[
                            // QRIS - Show QR Code
                            Center(
                              child: Container(
                                width: 200,
                                height: 200,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.qr_code_2,
                                      size: 120,
                                      color: Colors.grey[800],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "SCAN ME",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: context.c.onAccent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (qrString != null) ...[
                              const SizedBox(height: 12),
                              Center(
                                child: Text(
                                  "Kode: $qrString",
                                  style: TextStyle(
                                    color: context.c.inkSoft,
                                    fontSize: 11,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                "Scan dengan aplikasi e-wallet atau m-banking",
                                style: TextStyle(
                                  color: context.c.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ] else ...[
                            // Virtual Account - Show VA Number
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: context.c.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: context.c.line),
                              ),
                              // stretch, bukan center: tanpa ini Column
                              // mengikuti lebar anak terlebar, dan nomor VA
                              // 16 digit lebih lebar dari kartunya. Akibatnya
                              // label dan tombol tampak rata tengah terhadap
                              // NOMOR yang meluber, bukan terhadap kartu, jadi
                              // semuanya terlihat bergeser ke kiri.
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "Nomor Virtual Account",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: context.c.inkSoft,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  // Nomor terpanjang yang kita temui 17 digit
                                  // (BNC). Dikecilkan kalau tidak muat, bukan
                                  // dipotong: satu digit hilang berarti uang
                                  // pelanggan nyasar.
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      nomorVa ?? 'Belum tersedia',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: nomorVa == null ? 15 : 24,
                                        fontWeight: FontWeight.bold,
                                        // Jarak antarhuruf dikurangi supaya
                                        // nomornya muat utuh tanpa mengecil
                                        // berlebihan, tapi tetap terbaca
                                        // per digit saat disalin manual.
                                        letterSpacing: nomorVa == null ? 0 : 1,
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                        color: nomorVa == null
                                            ? context.c.danger
                                            : context.c.ink,
                                      ),
                                    ),
                                  ),
                                  if (nomorVa == null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Hubungi tim Sportago sebelum mentransfer. '
                                      'Jangan menebak nomor rekening.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: context.c.inkSoft,
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  // Center supaya tombol tidak ikut melebar
                                  // penuh oleh crossAxisAlignment.stretch di
                                  // atas, tapi tetap rata tengah terhadap kartu.
                                  Center(
                                    child: OutlinedButton.icon(
                                      // Tombol ini SEBELUMNYA tidak menyalin
                                      // apa pun. Ia hanya memunculkan pesan
                                      // "Nomor VA berhasil disalin!", lalu
                                      // pelanggan menempel di m-banking dan
                                      // mendapat isi papan klip sebelumnya.
                                      // Pesan yang mengaku berhasil padahal
                                      // tidak terjadi apa-apa lebih berbahaya
                                      // daripada tombol yang diam saja.
                                      onPressed: nomorVa == null
                                          ? null
                                          : () {
                                              Clipboard.setData(
                                                ClipboardData(text: nomorVa),
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: const Text(
                                                    'Nomor VA disalin',
                                                  ),
                                                  backgroundColor: context.c.ok,
                                                  duration: const Duration(
                                                    seconds: 2,
                                                  ),
                                                ),
                                              );
                                            },
                                      icon: const Icon(Icons.copy, size: 16),
                                      label: const Text("Salin"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: context.c.accent,
                                        side: BorderSide(
                                          color: context.c.accent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Center(
                              child: Text(
                                "Transfer sesuai nominal ke nomor VA di atas",
                                style: TextStyle(
                                  color: context.c.inkSoft,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],

                          // Pintasan pengembang: menandai pemesanan lunas
                          // tanpa uang berpindah. Backend menolaknya di
                          // produksi (403), jadi di tangan pelanggan tombol
                          // ini tidak melakukan apa-apa; ia cuma tombol mati
                          // berwarna ungu bertuliskan "TEST" di layar tempat
                          // orang menyerahkan uang.
                          //
                          // Komentar lamanya berbunyi "Remove in production"
                          // tapi tidak pernah ada yang menghapusnya, dan tanpa
                          // pagar kDebugMode ia ikut ke setiap build rilis.
                          if (kDebugMode) ...[
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _simulatePayment,
                                icon: const Icon(
                                  Icons.bug_report,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                label: const Text(
                                  "TEST: Simulasi Pembayaran Berhasil",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                          Row(
                            children: [
                              Icon(
                                Icons.receipt,
                                color: context.c.inkSoft,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Rincian Pembayaran",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: context.c.ink,
                                ),
                              ),
                            ],
                          ),
                          Divider(height: 20, color: context.c.line),
                          // Baris lama: harga per jam, durasi, lalu
                          // "Subtotal" yang isinya justru TOTAL. Pelanggan
                          // membaca Rp 200.000 lalu Rp 221.000 dengan
                          // selisih Rp 21.000 yang tidak pernah dijelaskan.
                          // Biaya platform dan biaya admin memang tidak
                          // pernah ditampilkan, padahal keduanya yang
                          // membentuk selisih itu.
                          _buildPriceRow(
                            "Harga lapangan (${widget.booking.durationHours} jam)",
                            formatCurrency(hargaLapangan),
                          ),
                          _buildPriceRow(
                            "Biaya platform",
                            formatCurrency(biayaPlatform),
                          ),
                          _buildPriceRow(
                            "Biaya admin",
                            formatCurrency(biayaAdmin),
                          ),
                          Divider(height: 20, color: context.c.line),
                          _buildPriceRow(
                            "Total Bayar",
                            formatCurrency(total),
                            isBold: true,
                            isBlue: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action Buttons
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _simulatePayment,
                        icon: Icon(
                          Icons.check_circle_outline,
                          color: context.c.onAccent,
                        ),
                        label: Text(
                          "CEK STATUS PEMBAYARAN",
                          style: TextStyle(
                            color: context.c.onAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.c.accent,
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
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _cancelBooking,
                        icon: Icon(Icons.close, color: context.c.danger),
                        label: Text(
                          "BATALKAN PESANAN",
                          style: TextStyle(
                            color: context.c.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: context.c.danger),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
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
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 13,
              color: context.c.ink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
    String label,
    String value, {
    bool isBold = false,
    bool isBlue = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: context.c.inkSoft, fontSize: 13).copyWith(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 13,
              color: isBlue ? context.c.accent : context.c.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Nama metode pembayaran yang layak dibaca pelanggan.
///
/// Dulu daftarnya cuma lima dan sisanya jatuh ke `return method`,
/// sementara pemanggilnya menempelkan " Virtual Account" di belakang.
/// Hasilnya kode mentah muncul di layar: "va_bca Virtual Account".
/// Sejak gateway pindah ke Duitku ada sepuluh bank Virtual Account,
/// jadi hampir semuanya kena.
///
/// Nama bank ditulis di sini, bukan disusun dari potongan kode, supaya
/// "Bank Neo Commerce" tidak berubah jadi "Bnc".
String _getPaymentMethodDisplay(String method) {
  const nama = {
    'qris': 'QRIS',
    'ovo': 'OVO',
    'dana': 'DANA',
    'gopay': 'GoPay',
    'shopeepay': 'ShopeePay',
    'linkaja': 'LinkAja',
    'va_bca': 'BCA Virtual Account',
    'va_bni': 'BNI Virtual Account',
    'va_bri': 'BRI Virtual Account',
    'va_mandiri': 'Mandiri Virtual Account',
    'va_permata': 'Permata Virtual Account',
    'va_cimb': 'CIMB Niaga Virtual Account',
    'va_bsi': 'BSI Virtual Account',
    'va_bnc': 'Bank Neo Commerce Virtual Account',
    'va_maybank': 'Maybank Virtual Account',
    'va_artha_graha': 'Bank Artha Graha Virtual Account',
    'va_sampoerna': 'Bank Sahabat Sampoerna Virtual Account',
    'card': 'Kartu Kredit / Debit',
  };

  final kunci = method.toLowerCase();
  if (nama.containsKey(kunci)) return nama[kunci]!;

  // Sebagian layar lama mengirim nama bank saja ("BCA"), bukan kode.
  if (nama.containsKey('va_$kunci')) return nama['va_$kunci']!;

  // Kode yang belum dikenal ditampilkan apa adanya, tanpa ditempeli
  // kata "Virtual Account" yang belum tentu benar.
  return method;
}
