import 'dart:async';
import 'package:flutter/material.dart';
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

class _TransactionsPageState extends State<TransactionsPage> with SingleTickerProviderStateMixin {
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
          _errorMessage = result.message ?? 'Gagal memuat data transaksi';
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
            return bookingDate.isAfter(todayDate) || bookingDate.isAtSameMomentAs(todayDate);
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
          if (b.status == 'completed' || b.status == 'cancelled' || b.status == 'expired') {
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

  int _getTabCount(String filterStatus) {
    return _getFilteredBookings(filterStatus).length;
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is not logged in
    if (AuthService.token == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            "Transaksi",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
          ),
          backgroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                "Silakan login untuk melihat transaksi",
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
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
                  backgroundColor: const Color(0xFF0047FF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Transaksi',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF0047FF),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFF0047FF),
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Mendatang'),
            Tab(text: 'Menunggu'),
            Tab(text: 'Riwayat'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0047FF)),
                  SizedBox(height: 16),
                  Text('Memuat data transaksi...'),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.grey[600]),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0047FF),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: Colors.white),
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
          emptyMessage = 'Belum ada riwayat transaksi';
          emptyIcon = Icons.history;
          break;
        default:
          emptyMessage = 'Belum ada transaksi';
          emptyIcon = Icons.receipt_long_outlined;
      }

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            if (status == 'upcoming') ...[
              const SizedBox(height: 8),
              Text(
                'Yuk booking lapangan favoritmu!',
                style: TextStyle(color: Colors.grey[400], fontSize: 13),
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
        return _BookingCard(
          booking: bookings[index],
          onRefresh: _loadBookings,
        );
      },
    );
  }
}

// Booking Card with enhanced features for upcoming bookings
class _BookingCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onRefresh;

  const _BookingCard({
    required this.booking,
    required this.onRefresh,
  });

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
      uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${venue.latitude},${venue.longitude}');
    } else {
      // Fallback to address search
      final encodedAddress = Uri.encodeComponent('${venue.name}, ${venue.address}, ${venue.city}');
      uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$encodedAddress');
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
        themeColor = Colors.orange;
        statusText = "Menunggu Pembayaran";
        statusIcon = Icons.timer_outlined;
        break;
      case 'confirmed':
        themeColor = const Color(0xFF0047FF);
        statusText = "Terkonfirmasi";
        statusIcon = Icons.verified;
        break;
      case 'checked_in':
        themeColor = Colors.teal;
        statusText = "Sedang Bermain";
        statusIcon = Icons.sports;
        break;
      case 'cancelled':
        themeColor = Colors.red;
        statusText = "Dibatalkan";
        statusIcon = Icons.cancel_outlined;
        break;
      case 'completed':
        themeColor = Colors.green;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule, size: 12, color: Colors.orange.shade700),
                        const SizedBox(width: 4),
                        Text(
                          _countdownText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  booking.field?.name ?? "-",
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                ),
                // Venue Address for upcoming bookings
                if (_isUpcoming && venueAddress != null && venueAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          venueAddress,
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey[500]),
                    const SizedBox(width: 6),
                    Text(
                      _formatDate(booking.bookingDate),
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.access_time, size: 14, color: Colors.grey[500]),
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0047FF),
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
                            foregroundColor: const Color(0xFF0047FF),
                            side: const BorderSide(color: Color(0xFF0047FF)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            foregroundColor: Colors.green,
                            side: const BorderSide(color: Colors.green),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                label: const Text("BAYAR SEKARANG", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _cancelBooking(context),
                icon: Icon(Icons.close, color: Colors.red.shade400, size: 18),
                label: Text("Batalkan", style: TextStyle(color: Colors.red.shade400)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.red.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                MaterialPageRoute(builder: (context) => ETicketPage(booking: booking)),
              );
            },
            icon: const Icon(Icons.confirmation_number, color: Colors.white, size: 18),
            label: const Text("LIHAT E-TICKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0047FF),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _rebook(context),
            icon: const Icon(Icons.replay, size: 18),
            label: const Text("BOOKING LAGI"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            "selectedMethod": paymentMethod == "QRIS" ? "QRIS (Gopay/OVO/Dana)" : "$paymentMethod Virtual Account",
            "paymentMethod": paymentMethod,
            "totalWithFee": booking.payment?.amount.toInt() ?? booking.totalPrice.toInt(),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Batalkan Pesanan?"),
        content: const Text("Apakah Anda yakin ingin membatalkan pesanan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Tidak"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final result = await BookingService.cancelBooking(booking.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.success ? "Pesanan dibatalkan" : (result.message ?? "Gagal membatalkan")),
            backgroundColor: result.success ? Colors.green : Colors.red,
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
      if (mounted) setState(() => _countdown = "00:15:00");
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
    paymentData["totalWithFee"] = booking.payment?.amount.toInt() ?? booking.totalPrice.toInt();
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

  String _getPaymentMethodDisplay(String method) {
    switch (method.toUpperCase()) {
      case 'QRIS':
        return "QRIS (Gopay/OVO/Dana)";
      case 'BCA':
        return "BCA Virtual Account";
      case 'MANDIRI':
        return "Mandiri Virtual Account";
      case 'BRI':
        return "BRI Virtual Account";
      case 'BNI':
        return "BNI Virtual Account";
      default:
        return method;
    }
  }

  void _goToPaymentSelector(BuildContext context) {
    final navigator = Navigator.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.85,
        child: TransactionPaymentSelectorSheet(totalPrice: booking.totalPrice.toInt()),
      ),
    ).then((result) {
      if (result != null) {
        Map<String, dynamic> paymentData = _getPaymentData();
        paymentData["selectedMethod"] = result['method'];
        paymentData["adminFee"] = result['fee'];
        paymentData["totalWithFee"] = result['total'];

        navigator.push(
          MaterialPageRoute(
            builder: (context) => TransactionPaymentWaitingPage(
              booking: booking,
              bookingData: paymentData,
              onPaymentComplete: onRefresh,
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

  String _formatTimeRange(String startTime, String endTime) {
    String formatTime(String time) {
      if (time.length >= 5) {
        return time.substring(0, 5);
      }
      return time;
    }
    return "${formatTime(startTime)} - ${formatTime(endTime)}";
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

  Future<void> _cancelBooking(BuildContext context) async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Batalkan Pesanan?"),
        content: const Text("Apakah Anda yakin ingin membatalkan pesanan ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Tidak"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Ya, Batalkan", style: TextStyle(color: Colors.white)),
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
              backgroundColor: Colors.red.shade400,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          onRefresh();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message ?? 'Gagal membatalkan pesanan'),
              backgroundColor: Colors.red,
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
    Color btnColor = const Color(0xFF0047FF);
    IconData statusIcon;
    VoidCallback? onMainAction;
    bool showSecondaryBtn = false;
    bool showCancelBtn = false;

    switch (status) {
      case 'pending':
        themeColor = Colors.orange;
        statusText = "Menunggu Pembayaran";
        mainBtnText = "BAYAR SEKARANG";
        statusIcon = Icons.timer_outlined;
        onMainAction = () => _goToPaymentDirect(context);
        showSecondaryBtn = true;
        showCancelBtn = true;
        break;
      case 'confirmed':
        themeColor = const Color(0xFF0047FF);
        statusText = "Terkonfirmasi";
        mainBtnText = "LIHAT E-TICKET";
        statusIcon = Icons.verified;
        onMainAction = () => _goToTicket(context);
        break;
      case 'checked_in':
        themeColor = Colors.teal;
        statusText = "Sedang Bermain";
        mainBtnText = "LIHAT E-TICKET";
        statusIcon = Icons.sports;
        onMainAction = () => _goToTicket(context);
        break;
      case 'cancelled':
        themeColor = Colors.red;
        statusText = "Dibatalkan";
        mainBtnText = "BOOKING LAGI";
        statusIcon = Icons.cancel_outlined;
        onMainAction = () => _rebook(context);
        break;
      case 'completed':
        themeColor = Colors.green;
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.av_timer, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          _countdown,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
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
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(Icons.sports_soccer, color: Colors.grey[400]),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.field?.venue?.name ?? "Unknown Venue",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        booking.field?.name ?? "Unknown Field",
                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today_outlined, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(booking.bookingDate),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 12, color: Colors.grey[500]),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeRange(booking.startTime, booking.endTime),
                                style: TextStyle(
                                  color: Colors.grey[600],
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

          Divider(height: 1, color: Colors.grey.shade100, thickness: 1),

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
                        const Text(
                          "Total Harga",
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          booking.formattedTotalPrice,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    if (status == 'pending')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F7FA),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code, size: 14, color: Colors.cyan),
                            SizedBox(width: 4),
                            Text(
                              "QRIS",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.cyan,
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
                      status == 'pending' ? Icons.payment :
                      status == 'confirmed' || status == 'checked_in' ? Icons.confirmation_number :
                      Icons.replay,
                      color: Colors.white,
                      size: 20,
                    ),
                    label: Text(
                      mainBtnText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: status == 'pending' ? Colors.green : btnColor,
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
                      icon: Icon(Icons.close, color: Colors.red.shade400, size: 20),
                      label: Text(
                        "Batalkan Pesanan",
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
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
// PAYMENT SELECTOR SHEET FOR TRANSACTIONS
// =========================================================
class TransactionPaymentSelectorSheet extends StatelessWidget {
  final int totalPrice;

  const TransactionPaymentSelectorSheet({super.key, required this.totalPrice});

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
      decoration: const BoxDecoration(
        color: Colors.white,
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
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              "Pilih Pembayaran",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 24),

          // Ringkasan Tagihan
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: const Color(0xFFF8F9FA),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Total Tagihan", style: TextStyle(color: Colors.grey)),
                Text(
                  formatCurrency(totalPrice),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // List Metode
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              children: [
                _buildSectionTitle("Rekomendasi"),
                _buildPaymentOption(
                  context,
                  icon: Icons.qr_code_scanner,
                  title: "QRIS (Gopay/OVO/Dana)",
                  fee: 700,
                  color: Colors.blue,
                  isRecommended: true,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Virtual Account"),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: "BCA Virtual Account",
                  fee: 2500,
                  color: Colors.purple,
                ),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: "Mandiri Virtual Account",
                  fee: 2500,
                  color: Colors.blue[900]!,
                ),
                _buildPaymentOption(
                  context,
                  icon: Icons.account_balance,
                  title: "BRI Virtual Account",
                  fee: 2500,
                  color: Colors.orange,
                ),
                const SizedBox(height: 20),
                _buildSectionTitle("Gerai Retail"),
                _buildPaymentOption(
                  context,
                  icon: Icons.storefront,
                  title: "Alfamart / Indomaret",
                  fee: 5000,
                  color: Colors.red,
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPaymentOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required int fee,
    required Color color,
    bool isRecommended = false,
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
          "total": finalPrice,
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isRecommended ? const Color(0xFF0047FF) : Colors.grey.shade200,
          ),
          boxShadow: [
            if (isRecommended)
              BoxShadow(
                color: const Color(0xFF0047FF).withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0047FF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            "PROMO",
                            style: TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
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
                      color: fee == 0 ? Colors.green : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
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
  State<TransactionPaymentWaitingPage> createState() => _TransactionPaymentWaitingPageState();
}

class _TransactionPaymentWaitingPageState extends State<TransactionPaymentWaitingPage> {
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
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        widget.onPaymentComplete();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal memproses pembayaran'),
            backgroundColor: Colors.red,
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
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        widget.onPaymentComplete();
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Gagal membatalkan pesanan'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String method = widget.bookingData['selectedMethod'] ?? "Metode Pembayaran";
    String paymentMethod = (widget.bookingData['paymentMethod'] ?? "QRIS").toString().toUpperCase();
    bool isQRIS = paymentMethod == "QRIS";

    // Use actual booking data
    int subtotal = widget.booking.totalPrice.toInt();
    int total = widget.booking.payment?.amount.toInt() ?? subtotal;

    String formatCurrency(int amount) => "Rp ${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.'
    )}";

    String? qrString = widget.booking.payment?.qrString;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Selesaikan Pembayaran",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0047FF)),
                  SizedBox(height: 16),
                  Text('Memproses...'),
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
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.timer_outlined, color: Colors.orange, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Selesaikan pembayaran dalam",
                                style: TextStyle(fontSize: 12, color: Colors.black54),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.bookingData['countdown'] ?? "00:15:00",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt_long, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Detail Booking",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildDetailRow("Kode Booking", widget.booking.bookingCode),
                        _buildDetailRow("Venue", widget.booking.field?.venue?.name ?? "-"),
                        _buildDetailRow("Lapangan", widget.booking.field?.name ?? "-"),
                        _buildDetailRow("Tanggal", widget.bookingData['date'] ?? "-"),
                        _buildDetailRow("Waktu", widget.booking.formattedTime),
                        _buildDetailRow("Durasi", "${widget.booking.durationHours} jam"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Metode Pembayaran Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payment, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Metode Pembayaran",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0047FF).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isQRIS ? Icons.qr_code_scanner : Icons.account_balance,
                                color: const Color(0xFF0047FF),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  method,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
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
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 120, color: Colors.grey[800]),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "SCAN ME",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0047FF),
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
                                style: TextStyle(color: Colors.grey[600], fontSize: 11),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "Scan dengan aplikasi e-wallet atau m-banking",
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ),
                        ] else ...[
                          // Virtual Account - Show VA Number
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Nomor Virtual Account",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  qrString ?? "8800 1234 5678 9012",
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text("Nomor VA berhasil disalin!"),
                                        backgroundColor: Color(0xFF0047FF),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.copy, size: 16),
                                  label: const Text("Salin"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF0047FF),
                                    side: const BorderSide(color: Color(0xFF0047FF)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: Text(
                              "Transfer sesuai nominal ke nomor VA di atas",
                              style: TextStyle(color: Colors.grey[500], fontSize: 12),
                            ),
                          ),
                        ],

                        // TEST BUTTON - Remove in production
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _simulatePayment,
                            icon: const Icon(Icons.bug_report, color: Colors.white, size: 18),
                            label: const Text(
                              "TEST: Simulasi Pembayaran Berhasil",
                              style: TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.receipt, color: Colors.grey[600], size: 18),
                            const SizedBox(width: 8),
                            const Text(
                              "Rincian Pembayaran",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _buildPriceRow("Harga Lapangan", formatCurrency(widget.booking.pricePerHour.toInt())),
                        _buildPriceRow("Durasi", "${widget.booking.durationHours} jam"),
                        _buildPriceRow("Subtotal", formatCurrency(subtotal)),
                        const Divider(height: 20),
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
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text(
                        "CEK STATUS PEMBAYARAN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0047FF),
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
                      icon: Icon(Icons.close, color: Colors.red.shade400),
                      label: Text(
                        "BATALKAN PESANAN",
                        style: TextStyle(
                          color: Colors.red.shade400,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade300),
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
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isBold = false, bool isBlue = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              fontSize: isBold ? 16 : 13,
              color: isBlue ? const Color(0xFF0047FF) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
