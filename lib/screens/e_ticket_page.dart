import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import '../services/refund_service.dart';
import 'home_page.dart';
import 'chat/chat_page.dart';

class ETicketPage extends StatefulWidget {
  final Booking booking;

  const ETicketPage({
    super.key,
    required this.booking,
  });

  @override
  State<ETicketPage> createState() => _ETicketPageState();
}

class _ETicketPageState extends State<ETicketPage> {
  final GlobalKey _ticketKey = GlobalKey();
  String _userName = "";
  String _userPhone = "";
  bool _isDownloading = false;

  /// Kebijakan refund yang berlaku, dibaca dari server saat layar dibuka.
  /// Null selama belum termuat — kotak keterangannya belum ditampilkan.
  KebijakanRefund? _kebijakanRefund;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _muatKebijakanRefund();
  }

  Future<void> _muatKebijakanRefund() async {
    final kebijakan = await RefundService.ambilKebijakan();
    if (mounted) setState(() => _kebijakanRefund = kebijakan);
  }

  Future<void> _loadUserData() async {
    var user = AuthService.currentUser;
    if (user == null) {
      final result = await AuthService.getUser();
      if (result.success && result.user != null) {
        user = result.user;
      }
    }
    if (user != null && mounted) {
      setState(() {
        _userName = user!.name;
        _userPhone = user.phone ?? "-";
      });
    }
  }

  bool get _isChatEnabled {
    return widget.booking.status == 'confirmed' || widget.booking.status == 'checked_in';
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(booking: widget.booking),
      ),
    );
  }


  Future<void> _downloadTicket() async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _ticketKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      // Capture as image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName = 'tiket_${widget.booking.bookingCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Share the file
      if (mounted) {
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'E-Tiket Sportago\n${widget.booking.field?.venue?.name ?? "Venue"}\n${widget.booking.bookingCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh tiket: $e'),
            backgroundColor: context.c.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        systemOverlayStyle: gayaOverlay(context),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.c.ink),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePageWithTab(initialIndex: 2),
              ),
              (route) => false,
            );
          },
        ),
        title: Text(
          "E-Tiket",
          style: TextStyle(
            color: context.c.ink,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: false,
        actions: [
          if (_isChatEnabled)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.c.ok.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chat_outlined, color: context.c.ok, size: 20),
              ),
              onPressed: _openChat,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Ticket Card - wrapped in RepaintBoundary for screenshot
                    RepaintBoundary(
                      key: _ticketKey,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.c.raised,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.c.line),
                        ),
                        child: Column(
                          children: [
                            // Top Section - Venue Name & QR Code
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  // Venue Name
                                  Text(
                                    widget.booking.field?.venue?.name ?? "Venue",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: context.c.ink,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),

                                  // Real QR Code
                                  Container(
                                    width: 180,
                                    height: 180,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: QrImageView(
                                      data: widget.booking.bookingCode,
                                      version: QrVersions.auto,
                                      size: 164,
                                      backgroundColor: Colors.white,
                                      errorCorrectionLevel: QrErrorCorrectLevel.M,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Simple Divider with Notches
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: context.c.surface,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: context.c.line,
                                  ),
                                ),
                                Container(
                                  width: 14,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: context.c.surface,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(14),
                                      bottomLeft: Radius.circular(14),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Bottom Section - Info Grid
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  _buildInfoRow("Nama", _userName.isNotEmpty ? _userName : "-", "No. Telepon", _userPhone),
                                  const SizedBox(height: 16),
                                  _buildInfoRow("Tanggal", _formatDate(widget.booking.bookingDate), "Waktu", widget.booking.formattedTime),
                                  const SizedBox(height: 16),
                                  _buildInfoRow("Lapangan", widget.booking.field?.name ?? "-", "Durasi", "${widget.booking.durationHours} Jam"),
                                  const SizedBox(height: 16),
                                  _buildInfoRow("Kode Booking", widget.booking.bookingCode, "Total", _formatCurrency(widget.booking.totalPrice.toInt()), valueColor: context.c.accent),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons Row
                    if (_isChatEnabled)
                      Row(
                        children: [
                          // Chat Button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _openChat,
                              icon: Icon(Icons.chat_outlined, color: context.c.ok, size: 18),
                              label: Text(
                                "Chat Venue",
                                style: TextStyle(color: context.c.ok, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: context.c.ok),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: context.c.raised,
                              ),
                            ),
                          ),
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Info Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: context.c.raised,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.c.line),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: context.c.inkSoft, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Harap datang 10 menit sebelum jadwal",
                              style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Keterangan refund.
                    //
                    // Dulu di sini ada tier "100% jika >24 jam, 50% jika
                    // 12-24 jam" yang dihitung sendiri oleh app, plus
                    // tombol Ajukan Refund. Keduanya tidak berdasar:
                    // backend menyatakan tidak ada jalur refund dari sisi
                    // pemesan (`customer_can_request: false`), dan rute
                    // yang dipanggil tombol itu memang tidak pernah ada.
                    //
                    // Sekarang yang ditampilkan adalah cara refund yang
                    // sebenarnya berlaku, dibaca dari server.
                    if (widget.booking.status == 'confirmed' &&
                        _kebijakanRefund != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: context.c.raised,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.c.line),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                color: context.c.inkSoft, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pembatalan & refund',
                                    style: TextStyle(
                                      color: context.c.ink,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _kebijakanRefund!.pesan,
                                    style: TextStyle(
                                      color: context.c.inkSoft,
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ElevatedButton.icon(
                onPressed: _isDownloading ? null : _downloadTicket,
                icon: _isDownloading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.c.onAccent,
                        ),
                      )
                    : Icon(Icons.download, color: context.c.onAccent),
                label: Text(
                  _isDownloading ? "Menyimpan..." : "Download Ticket",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.c.onAccent),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.c.accent,
                  foregroundColor: context.c.onAccent,
                  disabledBackgroundColor: context.c.accent.withValues(alpha: 0.7),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String leftLabel, String leftValue, String rightLabel, String rightValue, {Color? valueColor}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(leftLabel, style: TextStyle(color: context.c.inkSoft, fontSize: 12)),
              const SizedBox(height: 4),
              Text(leftValue, style: TextStyle(color: valueColor ?? context.c.ink, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel, style: TextStyle(color: context.c.inkSoft, fontSize: 12)),
              const SizedBox(height: 4),
              Text(rightValue, style: TextStyle(color: valueColor ?? context.c.ink, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.end),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
      return "${parts[2]} ${months[int.parse(parts[1])]} ${parts[0]}";
    } catch (e) {
      return date;
    }
  }

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }
}
