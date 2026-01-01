import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking.dart';
import '../models/refund.dart';
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
  bool _isRequestingRefund = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
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

  bool get _canRequestRefund {
    // Only confirmed bookings can request refund
    if (widget.booking.status != 'confirmed') return false;

    // Check if more than 12 hours before booking
    try {
      final bookingDate = DateTime.parse(widget.booking.bookingDate.split('T')[0]);
      final timeParts = widget.booking.startTime.split(':');
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final diff = bookingDateTime.difference(DateTime.now());
      // Can only refund if more than 12 hours before booking
      return diff.inHours >= 12;
    } catch (e) {
      return false;
    }
  }

  String get _refundTimeInfo {
    try {
      final bookingDate = DateTime.parse(widget.booking.bookingDate.split('T')[0]);
      final timeParts = widget.booking.startTime.split(':');
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      final diff = bookingDateTime.difference(DateTime.now());

      if (diff.isNegative) {
        return "";
      } else if (diff.inHours >= 24) {
        return "Refund 100% tersedia (${diff.inHours} jam sebelum jadwal)";
      } else if (diff.inHours >= 12) {
        return "Refund 50% tersedia (${diff.inHours} jam sebelum jadwal)";
      } else {
        return "Refund tidak tersedia (kurang dari 12 jam sebelum jadwal)";
      }
    } catch (e) {
      return "";
    }
  }

  RefundPolicy get _refundPolicy {
    try {
      final bookingDate = DateTime.parse(widget.booking.bookingDate.split('T')[0]);
      final timeParts = widget.booking.startTime.split(':');
      final bookingDateTime = DateTime(
        bookingDate.year,
        bookingDate.month,
        bookingDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      return RefundPolicy.calculate(bookingDateTime);
    } catch (e) {
      return RefundPolicy(percentage: 0, description: 'Tidak dapat menghitung kebijakan refund', canRefund: false);
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(booking: widget.booking),
      ),
    );
  }

  Future<void> _showRefundDialog() async {
    final policy = _refundPolicy;

    if (!policy.canRefund) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(policy.description),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final refundAmount = (widget.booking.totalPrice * policy.percentage / 100).toInt();
    final reasonController = TextEditingController();

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text(
                "Ajukan Refund",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              // Policy info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          "Kebijakan Refund",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      policy.description,
                      style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Amount info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Total Pembayaran", style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(_formatCurrency(widget.booking.totalPrice.toInt()),
                            style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text("Jumlah Refund (${policy.percentage}%)",
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        const SizedBox(height: 4),
                        Text(
                          _formatCurrency(refundAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF0047FF),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reason input
              const Text("Alasan Refund", style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "Jelaskan alasan pengajuan refund...",
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF0047FF)),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Note about admin approval
              Row(
                children: [
                  Icon(Icons.schedule, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Pengajuan refund memerlukan persetujuan admin (1-3 hari kerja)",
                      style: TextStyle(color: Colors.grey[500], fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Batal"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (reasonController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Silakan isi alasan refund"),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text(
                        "Ajukan Refund",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

    if (result == true && mounted) {
      await _submitRefundRequest(reasonController.text.trim());
    }
  }

  Future<void> _submitRefundRequest(String reason) async {
    setState(() => _isRequestingRefund = true);

    final result = await RefundService.requestRefund(
      bookingId: widget.booking.id,
      reason: reason,
    );

    if (mounted) {
      setState(() => _isRequestingRefund = false);

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(child: Text("Pengajuan refund berhasil! Menunggu persetujuan admin.")),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        // Navigate back to transactions
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePageWithTab(initialIndex: 2)),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? "Gagal mengajukan refund"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
          text: 'E-Tiket Sporta\n${widget.booking.field?.venue?.name ?? "Venue"}\n${widget.booking.bookingCode}',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh tiket: $e'),
            backgroundColor: Colors.red,
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
      backgroundColor: const Color(0xFFE8F0FE),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE8F0FE),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
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
        title: const Text(
          "E-Tiket",
          style: TextStyle(
            color: Colors.black87,
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
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_outlined, color: Colors.green, size: 20),
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
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
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
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
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
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0FE),
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Container(
                                    height: 1,
                                    color: Colors.grey.shade300,
                                  ),
                                ),
                                Container(
                                  width: 14,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F0FE),
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
                                  _buildInfoRow("Kode Booking", widget.booking.bookingCode, "Total", _formatCurrency(widget.booking.totalPrice.toInt()), valueColor: const Color(0xFF0047FF)),
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
                              icon: const Icon(Icons.chat_outlined, color: Colors.green, size: 18),
                              label: const Text(
                                "Chat Venue",
                                style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.green),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                          // Refund Button (only if can request refund)
                          if (_canRequestRefund) ...[
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isRequestingRefund ? null : _showRefundDialog,
                                icon: _isRequestingRefund
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red),
                                      )
                                    : Icon(Icons.money_off, color: Colors.red.shade400, size: 18),
                                label: Text(
                                  "Refund",
                                  style: TextStyle(color: Colors.red.shade400, fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(color: Colors.red.shade300),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                    const SizedBox(height: 12),

                    // Info Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.grey.shade600, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Harap datang 10 menit sebelum jadwal",
                              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Refund Info Box (show for confirmed bookings)
                    if (widget.booking.status == 'confirmed' && _refundTimeInfo.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _canRequestRefund ? Colors.green.shade50 : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _canRequestRefund ? Colors.green.shade200 : Colors.red.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _canRequestRefund ? Icons.check_circle_outline : Icons.cancel_outlined,
                                  color: _canRequestRefund ? Colors.green.shade700 : Colors.red.shade700,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _refundTimeInfo,
                                    style: TextStyle(
                                      color: _canRequestRefund ? Colors.green.shade800 : Colors.red.shade800,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Kebijakan: Refund 100% jika > 24 jam, 50% jika 12-24 jam, 0% jika < 12 jam sebelum jadwal",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 11,
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.download, color: Colors.white),
                label: Text(
                  _isDownloading ? "Menyimpan..." : "Download Ticket",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0047FF),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF0047FF).withValues(alpha: 0.7),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
              Text(leftLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Text(leftValue, style: TextStyle(color: valueColor ?? Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rightLabel, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
              const SizedBox(height: 4),
              Text(rightValue, style: TextStyle(color: valueColor ?? Colors.black87, fontSize: 14, fontWeight: FontWeight.w600), textAlign: TextAlign.end),
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
