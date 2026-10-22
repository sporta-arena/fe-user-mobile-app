import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_tokens.dart';
import '../widgets/sportago_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/booking.dart';
import '../services/auth_service.dart';
import 'home_page.dart';
import 'chat/chat_page.dart';

class ETicketPage extends StatefulWidget {
  final Booking booking;

  const ETicketPage({super.key, required this.booking});

  @override
  State<ETicketPage> createState() => _ETicketPageState();
}

class _ETicketPageState extends State<ETicketPage> {
  final GlobalKey _ticketKey = GlobalKey();

  /// Titik asal lembar bagikan iOS. Tanpa titik asal yang ada di layar,
  /// iOS menolak lembar bagikan dan unduhan tiket selalu gagal.
  final GlobalKey _tombolUnduhKey = GlobalKey();
  String _userName = "";
  String _userPhone = "";
  bool _isDownloading = false;

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
    return widget.booking.status == 'confirmed' ||
        widget.booking.status == 'checked_in';
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
      RenderRepaintBoundary boundary =
          _ticketKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      // Capture as image
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);

      // Convert to bytes
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final fileName =
          'tiket_${widget.booking.bookingCode}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(bytes);

      // Share the file
      if (mounted) {
        final kotak =
            _tombolUnduhKey.currentContext?.findRenderObject() as RenderBox?;
        await Share.shareXFiles(
          [XFile(file.path, mimeType: 'image/png')],
          sharePositionOrigin: kotak == null
              ? null
              : kotak.localToGlobal(Offset.zero) & kotak.size,
          text:
              'E-Tiket Sportago\n${widget.booking.field?.venue?.name ?? "Venue"}\n${widget.booking.bookingCode}',
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
    final c = context.c;

    // Tiket duduk di atas bidang hijau pekat, sama dengan pembuka dan
    // kepala halaman. Kotak QR selalu putih murni (juga di mode gelap)
    // supaya pemindai di pintu venue tetap membacanya.
    return Scaffold(
      backgroundColor: SportagoColors.pekat,
      appBar: AppBar(
        backgroundColor: SportagoColors.pekat,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => const HomePageWithTab(initialIndex: 1),
              ),
              (route) => false,
            );
          },
        ),
        title: const Text("E-Tiket"),
        centerTitle: false,
        actions: [
          if (_isChatEnabled)
            TombolIkonPekat(
              ikon: Icons.chat_bubble_outline_rounded,
              tooltip: 'Chat venue',
              onTap: _openChat,
            ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    // Ticket Card - wrapped in RepaintBoundary for screenshot
                    RepaintBoundary(
                      key: _ticketKey,
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: c.raised,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Column(
                          children: [
                            // Top Section - Venue Name & QR Code
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                20,
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    widget.booking.field?.venue?.name ??
                                        "Venue",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.4,
                                      color: c.ink,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.booking.field?.name ?? "-",
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      color: c.inkSoft,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 20),

                                  // Real QR Code
                                  Container(
                                    width: 212,
                                    height: 212,
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: SportagoColors.pure,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: c.line),
                                    ),
                                    child: QrImageView(
                                      data: widget.booking.bookingCode,
                                      version: QrVersions.auto,
                                      size: 184,
                                      backgroundColor: SportagoColors.pure,
                                      errorCorrectionLevel:
                                          QrErrorCorrectLevel.M,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    widget.booking.bookingCode,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: c.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Tunjukkan QR ini di meja venue',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: c.inkDim,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Sobekan tiket: lekuk kiri-kanan berwarna latar
                            // pekat, garis putus di tengah.
                            Row(
                              children: [
                                Container(
                                  width: 14,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: SportagoColors.pekat,
                                    borderRadius: BorderRadius.only(
                                      topRight: Radius.circular(14),
                                      bottomRight: Radius.circular(14),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: LayoutBuilder(
                                    builder: (context, box) {
                                      final n = (box.maxWidth / 10).floor();
                                      return Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: List.generate(
                                          n,
                                          (_) => Container(
                                            width: 5,
                                            height: 1.5,
                                            color: c.lineStrong,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                Container(
                                  width: 14,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: SportagoColors.pekat,
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
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                20,
                                24,
                                24,
                              ),
                              child: Column(
                                children: [
                                  _buildInfoRow(
                                    "Tanggal",
                                    _formatDate(widget.booking.bookingDate),
                                    "Waktu",
                                    widget.booking.formattedTime,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    "Nama",
                                    _userName.isNotEmpty ? _userName : "-",
                                    "No. Telepon",
                                    _userPhone,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    "Lapangan",
                                    widget.booking.field?.name ?? "-",
                                    "Durasi",
                                    "${widget.booking.durationHours} Jam",
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInfoRow(
                                    "Status",
                                    widget.booking.status == 'checked_in'
                                        ? 'Sudah check-in'
                                        : 'Terkonfirmasi',
                                    "Total",
                                    _formatCurrency(
                                      widget.booking.totalPrice.toInt(),
                                    ),
                                    valueColor: c.accent,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    if (_isChatEnabled) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openChat,
                          icon: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            size: 18,
                          ),
                          label: const Text("Chat Venue"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: SportagoColors.pure,
                            side: BorderSide(
                              color: SportagoColors.pure.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    _catatanPekat(
                      ikon: Icons.schedule_rounded,
                      judul: 'Harap datang 10 menit sebelum jadwal',
                    ),

                    // Keterangan pembatalan.
                    //
                    // Dulu di sini ada tier "100% jika >24 jam, 50% jika
                    // 12-24 jam" yang dihitung sendiri oleh app, lalu
                    // diganti kebijakan yang dibaca dari server. Keduanya
                    // sudah tidak berlaku: kebijakannya sekarang tidak ada
                    // pengembalian dana sama sekali, jadi tidak ada yang
                    // perlu ditanyakan ke server dan tidak ada angka yang
                    // bisa berubah di belakang layar.
                    if (widget.booking.status == 'confirmed') ...[
                      const SizedBox(height: 10),
                      _catatanPekat(
                        ikon: Icons.receipt_long_outlined,
                        judul: 'Pembatalan',
                        pesan:
                            'Pemesanan yang sudah dibayar tidak dapat '
                            'dibatalkan, dan pembayarannya tidak '
                            'dikembalikan.',
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: _tombolUnduhKey,
                  onPressed: _isDownloading ? null : _downloadTicket,
                  icon: _isDownloading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SportagoColors.pekat,
                          ),
                        )
                      : const Icon(Icons.download_rounded),
                  label: Text(
                    _isDownloading ? "Menyimpan..." : "Download Ticket",
                  ),
                  // Di atas bidang pekat tombol utama memakai volt, sama
                  // dengan tombol di pembuka; tombol pekat akan tenggelam.
                  style: FilledButton.styleFrom(
                    backgroundColor: SportagoColors.volt,
                    foregroundColor: SportagoColors.pekat,
                    disabledBackgroundColor: SportagoColors.volt.withValues(
                      alpha: 0.7,
                    ),
                    disabledForegroundColor: SportagoColors.pekat,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Catatan kecil di atas bidang pekat, di bawah tiket.
  Widget _catatanPekat({
    required IconData ikon,
    required String judul,
    String? pesan,
  }) {
    final media = context.c.onMedia;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: SportagoColors.pekatNaik,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(ikon, color: SportagoColors.volt, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  judul,
                  style: GoogleFonts.plusJakartaSans(
                    color: media.ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (pesan != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    pesan,
                    style: GoogleFonts.plusJakartaSans(
                      color: media.inkSoft,
                      fontSize: 12,
                      height: 1.4,
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

  Widget _buildInfoRow(
    String leftLabel,
    String leftValue,
    String rightLabel,
    String rightValue, {
    Color? valueColor,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                leftLabel,
                style: TextStyle(color: context.c.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                leftValue,
                style: TextStyle(
                  color: valueColor ?? context.c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                rightLabel,
                style: TextStyle(color: context.c.inkSoft, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                rightValue,
                style: TextStyle(
                  color: valueColor ?? context.c.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final parts = date.split('-');
      final months = [
        '',
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Ags',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return "${parts[2]} ${months[int.parse(parts[1])]} ${parts[0]}";
    } catch (e) {
      return date;
    }
  }

  String _formatCurrency(int amount) {
    return "Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}";
  }
}
