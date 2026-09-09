import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../constants/colors.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';
import '../models/booking.dart';
import 'chat/chat_page.dart';
import 'login_page.dart';

class ChatHistoryPage extends StatefulWidget {
  const ChatHistoryPage({super.key});

  @override
  State<ChatHistoryPage> createState() => _ChatHistoryPageState();
}

class _ChatHistoryPageState extends State<ChatHistoryPage> {
  List<Booking> _bookingsWithChat = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBookingsWithChat();
  }

  Future<void> _loadBookingsWithChat() async {
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
          // Filter bookings that had chat (confirmed or completed bookings)
          final bookingsWithChat = result.bookings!.where((b) =>
            b.status == 'confirmed' || b.status == 'completed'
          ).toList();

          setState(() {
            _bookingsWithChat = bookingsWithChat;
            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage = result.message ?? 'Gagal memuat data';
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

  String _formatDate(String dateStr) {
    try {
      String cleanDate = dateStr.split('T')[0];
      final date = DateTime.parse(cleanDate);
      return DateFormat('dd MMM yyyy', 'id').format(date);
    } catch (e) {
      return dateStr.split('T')[0];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if user is not logged in
    if (AuthService.token == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          systemOverlayStyle: gayaOverlay(context),
          title: const Text(
            "Riwayat Pesan",
            style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)
          ),
          backgroundColor: AppColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.login, size: 80, color: AppColors.onDarkMuted),
              const SizedBox(height: 16),
              const Text(
                "Silakan login untuk melihat riwayat pesan",
                style: TextStyle(color: AppColors.onDarkMuted, fontSize: 16),
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
                  backgroundColor: AppColors.brandYellow,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                child: const Text(
                  "Login",
                  style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: const Text(
          "Riwayat Pesan",
          style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.bold)
        ),
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandYellow),
            )
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 60, color: AppColors.onDarkMuted),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppColors.onDarkMuted),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBookingsWithChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandYellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text(
                          'Coba Lagi',
                          style: TextStyle(color: AppColors.ink, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                )
              : _bookingsWithChat.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_bubble_outline, size: 80, color: AppColors.onDarkMuted),
                          const SizedBox(height: 16),
                          const Text(
                            "Belum ada riwayat pesan",
                            style: TextStyle(
                              color: AppColors.onDarkMuted,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Riwayat chat akan muncul setelah\nbooking selesai",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.onDarkMuted, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookingsWithChat,
                      color: AppColors.brandYellow,
                      backgroundColor: AppColors.surface,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bookingsWithChat.length,
                        itemBuilder: (context, index) {
                          return _buildChatItem(_bookingsWithChat[index]);
                        },
                      ),
                    ),
    );
  }

  Widget _buildChatItem(Booking booking) {
    final bool isActive = booking.status == 'confirmed';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              booking: booking,
              isReadOnly: !isActive,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            // Venue Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? AppColors.brandYellow : AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.sports_soccer,
                  color: isActive ? AppColors.ink : AppColors.onDarkMuted, size: 28),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          booking.field?.venue?.name ?? "Venue",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.onDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Aktif",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "Selesai",
                            style: TextStyle(
                              color: AppColors.onDarkMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    booking.field?.name ?? "Field",
                    style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.onDarkMuted),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(booking.bookingDate),
                        style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time_outlined, size: 12, color: AppColors.onDarkMuted),
                      const SizedBox(width: 4),
                      Text(
                        booking.formattedTime,
                        style: const TextStyle(color: AppColors.onDarkMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            const Icon(Icons.chevron_right, color: AppColors.onDarkMuted),
          ],
        ),
      ),
    );
  }
}
