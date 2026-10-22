import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import '../widgets/sportago_ui.dart';
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
          final bookingsWithChat = result.bookings!
              .where((b) => b.status == 'confirmed' || b.status == 'completed')
              .toList();

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

  // Bilah aplikasi ikut tema: hijau pekat dengan judul putih.
  PreferredSizeWidget _bilah() => AppBar(
    title: const Text("Riwayat Pesan"),
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      onPressed: () => Navigator.pop(context),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Check if user is not logged in
    if (AuthService.token == null) {
      return Scaffold(
        appBar: _bilah(),
        body: Center(
          child: KeadaanKosong(
            ikon: Icons.login_rounded,
            judul: "Masuk dulu, ya",
            pesan: "Silakan login untuk melihat riwayat pesan",
            aksi: "Login",
            onAksi: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
              );
            },
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _bilah(),
      body: SafeArea(
        // Bilah navigasi menumpuk di atas isi layar sejak
        // targetSdk 35. top:false karena AppBar sudah
        // menyisihkan bagian atasnya sendiri.
        top: false,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: context.c.accent))
            : _errorMessage != null
            ? Center(
                child: KeadaanKosong(
                  ikon: Icons.error_outline_rounded,
                  judul: "Riwayat belum termuat",
                  pesan: _errorMessage,
                  aksi: 'Coba Lagi',
                  onAksi: _loadBookingsWithChat,
                ),
              )
            : _bookingsWithChat.isEmpty
            ? const Center(
                child: KeadaanKosong(
                  ikon: Icons.chat_bubble_outline_rounded,
                  judul: "Belum ada riwayat pesan",
                  pesan: "Riwayat chat akan muncul setelah\nbooking selesai",
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
      ),
    );
  }

  Widget _buildChatItem(Booking booking) {
    // Penanda visual di daftar saja. Yang menentukan boleh-tidaknya
    // menulis adalah `can_send` dari server, bukan tebakan di sini:
    // baris ini dulu memakai `status == 'confirmed'` saja, sehingga
    // pemesan yang sedang main (checked_in) ikut terkunci.
    final bool isActive =
        booking.status == 'confirmed' || booking.status == 'checked_in';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Kartu(
        padding: const EdgeInsets.all(16),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatPage(booking: booking)),
          );
        },
        child: Row(
          children: [
            // Venue Icon: pekat ber-ikon volt selagi chat masih terbuka.
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isActive ? SportagoColors.pekat : context.c.sunken,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.sports_soccer_rounded,
                color: isActive ? SportagoColors.volt : context.c.inkDim,
                size: 26,
              ),
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
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: -0.2,
                            color: context.c.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      isActive
                          ? const ChipStatus("Aktif", nada: Nada.ok)
                          : const ChipStatus("Selesai"),
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
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 12,
                        color: context.c.inkDim,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(booking.bookingDate),
                        style: TextStyle(
                          color: context.c.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time_outlined,
                        size: 12,
                        color: context.c.inkDim,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        booking.formattedTime,
                        style: TextStyle(
                          color: context.c.inkSoft,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Arrow
            Icon(Icons.chevron_right_rounded, color: context.c.inkSoft),
          ],
        ),
      ),
    );
  }
}
