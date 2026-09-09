import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:intl/intl.dart';
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
        backgroundColor: context.c.surface,
        appBar: AppBar(
          systemOverlayStyle: gayaOverlay(context),
          title: Text(
            "Riwayat Pesan",
            style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold)
          ),
          backgroundColor: context.c.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.login, size: 80, color: context.c.inkSoft),
              const SizedBox(height: 16),
              Text(
                "Silakan login untuk melihat riwayat pesan",
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
      appBar: AppBar(
        systemOverlayStyle: gayaOverlay(context),
        title: Text(
          "Riwayat Pesan",
          style: TextStyle(color: context.c.ink, fontWeight: FontWeight.bold)
        ),
        backgroundColor: context.c.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.c.accent),
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
                        onPressed: _loadBookingsWithChat,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.c.accent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Text(
                          'Coba Lagi',
                          style: TextStyle(color: context.c.onAccent, fontWeight: FontWeight.w700),
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
                          Icon(Icons.chat_bubble_outline, size: 80, color: context.c.inkSoft),
                          const SizedBox(height: 16),
                          Text(
                            "Belum ada riwayat pesan",
                            style: TextStyle(
                              color: context.c.inkSoft,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Riwayat chat akan muncul setelah\nbooking selesai",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: context.c.inkSoft, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBookingsWithChat,
                      color: context.c.accent,
                      backgroundColor: context.c.raised,
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
          color: context.c.raised,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.c.line),
        ),
        child: Row(
          children: [
            // Venue Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive ? context.c.accent : context.c.line,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.sports_soccer,
                  color: isActive ? context.c.onAccent : context.c.inkSoft, size: 28),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: context.c.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.c.okSoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Aktif",
                            style: TextStyle(
                              color: context.c.ok,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: context.c.line,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            "Selesai",
                            style: TextStyle(
                              color: context.c.inkSoft,
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
                    style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_outlined, size: 12, color: context.c.inkSoft),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(booking.bookingDate),
                        style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.access_time_outlined, size: 12, color: context.c.inkSoft),
                      const SizedBox(width: 4),
                      Text(
                        booking.formattedTime,
                        style: TextStyle(color: context.c.inkSoft, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right, color: context.c.inkSoft),
          ],
        ),
      ),
    );
  }
}
