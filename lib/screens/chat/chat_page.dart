import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/booking.dart';
import '../../services/realtime_chat.dart';
import 'alasan_laporan.dart';
import 'chat_models.dart';
import 'chat_service.dart';
import '../../utils/sisipan_bawah.dart';

// Chat untuk user menghubungi partner venue
// Entry point: halaman e-ticket setelah booking confirmed

class ChatPage extends StatefulWidget {
  final Booking booking;

  const ChatPage({super.key, required this.booking});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Message> _messages = [];
  PartnerContact? _partnerContact;
  bool _isLoading = true;
  bool _isSending = false;

  /// Apakah percakapan ini masih boleh ditulis, menurut server.
  ///
  /// null berarti belum diketahui (masih memuat). Sengaja TIDAK dihitung
  /// dari `booking.status` di sini: chat_history_page dulu melakukan itu
  /// dengan `status == 'confirmed'` saja, sehingga pemesan yang sedang
  /// main (checked_in) ikut terkunci. Tiga pemanggil lain malah tidak
  /// mengisi apa-apa, jadi kolom ketik tetap terbuka di booking yang
  /// sudah selesai dan penolakannya baru muncul setelah tombol kirim
  /// ditekan. Satu-satunya sumber sekarang penanda `can_send` dari server.
  bool? _bolehKirim;

  // Pesan baru datang lewat WebSocket, bukan dari polling: layar ini
  // tidak pernah menanyakan ulang ke server selama terbuka.
  RealtimeChat? _realtime;
  bool _terhubung = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    // Percakapan yang terkunci tetap mendengarkan: riwayatnya boleh
    // dibaca, dan lawan bicara bisa saja masih menutup percakapan dari
    // sisinya. Yang dikunci cuma kolom ketiknya.
    _realtime = RealtimeChat.dengarkan(
      widget.booking.id,
      onPesan: _terimaPesan,
      onStatus: (tersambung) {
        if (mounted) setState(() => _terhubung = tersambung);
      },
    );
  }

  @override
  void dispose() {
    _realtime?.tutup();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Pesan dorongan dari server.
  ///
  /// Disaring berdasarkan id: server sudah tidak menyiarkan balik pesan
  /// kita sendiri (lewat X-Socket-ID), tapi setelah sambungan putus dan
  /// tersambung lagi socket_id-nya berubah, jadi penyaring ini tetap
  /// diperlukan supaya tidak ada pesan kembar.
  void _terimaPesan(Map<String, dynamic> data) {
    if (!mounted) return;

    final pesan = Message.fromJson(data);
    if (_messages.any((m) => m.id == pesan.id)) return;

    setState(() => _messages.add(pesan));
    _scrollToBottom();
    ChatService.markAsRead(widget.booking.id);
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final isi = await ChatService.getMessages(widget.booking.id);
    final partner = await ChatService.getPartnerContact(widget.booking.id);

    setState(() {
      _messages = isi.pesan;
      _bolehKirim = isi.bolehKirim;
      _partnerContact = partner;
      _isLoading = false;
    });
    _scrollToBottom();
    ChatService.markAsRead(widget.booking.id);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _messageController.clear();

    final message = await ChatService.sendMessage(
      widget.booking.id,
      content,
      socketId: _realtime?.socketId,
    );

    if (message != null) {
      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal mengirim pesan')));
      }
    }
  }

  Future<void> _callPartner() async {
    if (_partnerContact?.phone != null) {
      final uri = Uri.parse('tel:${_partnerContact!.phone}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  /// Melaporkan percakapan ini.
  ///
  /// Ditaruh sebagai tombol tetap di app bar, bukan disembunyikan di
  /// menu tiga titik: kebijakan Google menuntut jalur pelaporan yang
  /// mudah ditemukan, dan orang yang sedang dilecehkan tidak sedang
  /// dalam keadaan mau menjelajahi menu.
  ///
  /// Sengaja tidak ada tombol "blokir". Chat di Sportago selalu terikat
  /// pada satu pemesanan antara pemesan dan pengelola lapangannya;
  /// memblokir lawan bicara berarti memutus koordinasi pemesanan yang
  /// sedang berjalan, dan tidak ada pesan dari orang asing yang perlu
  /// dicegah. Yang dibutuhkan di sini pelaporan, bukan pemblokiran.
  void _laporkan() {
    AlasanLaporan? terpilih;
    final catatan = TextEditingController();
    bool sedangKirim = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.raised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, aturSheet) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: sheetContext.sisipanBawah + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporkan percakapan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: context.c.ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Tim kami meninjau laporan ini beserta isi percakapannya.',
                style: TextStyle(fontSize: 13, color: context.c.inkSoft),
              ),
              const SizedBox(height: 16),
              ...AlasanLaporan.semua.map(
                (a) => RadioListTile<AlasanLaporan>(
                  value: a,
                  groupValue: terpilih,
                  onChanged: sedangKirim
                      ? null
                      : (v) => aturSheet(() => terpilih = v),
                  title: Text(
                    a.label,
                    style: TextStyle(fontSize: 14, color: context.c.ink),
                  ),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: context.c.accent,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: catatan,
                enabled: !sedangKirim,
                maxLines: 3,
                maxLength: 1000,
                style: TextStyle(color: context.c.ink),
                decoration: InputDecoration(
                  hintText: 'Ceritakan singkat (opsional)',
                  hintStyle: TextStyle(color: context.c.inkDim),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (terpilih == null || sedangKirim)
                      ? null
                      : () async {
                          aturSheet(() => sedangKirim = true);
                          final hasil = await ChatService.laporkan(
                            widget.booking.id,
                            alasan: terpilih!.kode,
                            catatan: catatan.text,
                          );
                          if (!sheetContext.mounted) return;
                          Navigator.pop(sheetContext);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(hasil.pesan),
                              backgroundColor: hasil.berhasil
                                  ? context.c.ok
                                  : context.c.danger,
                            ),
                          );
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.c.danger,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: sedangKirim
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Kirim Laporan',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

  void _showPartnerInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.c.raised,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + context.sisipanBawah),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: context.c.accent.withValues(alpha: 0.15),
              child: Text(
                _partnerContact?.name.isNotEmpty == true
                    ? _partnerContact!.name[0].toUpperCase()
                    : 'P',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: context.c.accent,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _partnerContact?.name ?? 'Partner',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: context.c.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _partnerContact?.venueName ?? '',
              style: TextStyle(fontSize: 14, color: context.c.inkSoft),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on, size: 14, color: context.c.inkSoft),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _partnerContact?.address ?? '',
                    style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _callPartner,
                icon: Icon(Icons.phone, color: context.c.accent),
                label: Text(
                  'Telepon',
                  style: TextStyle(color: context.c.accent),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: context.c.accent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.c.surface,
      appBar: AppBar(
        backgroundColor: context.c.surface,
        elevation: 0,
        systemOverlayStyle: gayaOverlay(context),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.c.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _showPartnerInfo,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: context.c.accent.withValues(alpha: 0.15),
                child: Text(
                  _partnerContact?.name.isNotEmpty == true
                      ? _partnerContact!.name[0].toUpperCase()
                      : 'P',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: context.c.accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _partnerContact?.name ?? 'Partner',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.c.ink,
                      ),
                    ),
                    // Baris kedua biasanya nama venue. Kalau sambungan
                    // realtime sedang putus, tempat yang sama dipakai
                    // memberi tahu bahwa pesan baru mungkin tertunda,
                    // lebih jujur daripada diam-diam berhenti menerima.
                    Text(
                      (_realtime != null && !_terhubung)
                          ? 'Menyambungkan\u2026'
                          : (widget.booking.field?.venue?.name ?? ''),
                      style: TextStyle(
                        fontSize: 12,
                        color: (_realtime != null && !_terhubung)
                            ? context.c.warn
                            : context.c.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.phone, color: context.c.ink),
            onPressed: _callPartner,
          ),
          IconButton(
            icon: Icon(Icons.flag_outlined, color: context.c.ink),
            tooltip: 'Laporkan percakapan',
            onPressed: _laporkan,
          ),
          IconButton(
            icon: Icon(Icons.more_vert, color: context.c.ink),
            onPressed: _showPartnerInfo,
          ),
        ],
      ),
      body: SafeArea(
        // Bilah navigasi menumpuk di atas isi layar sejak
        // targetSdk 35. top:false karena AppBar sudah
        // menyisihkan bagian atasnya sendiri.
        top: false,
        child: Column(
          children: [
            // Booking info banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: context.c.raised,
              child: Row(
                children: [
                  Icon(
                    Icons.confirmation_number,
                    size: 16,
                    color: context.c.accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Booking: ${widget.booking.bookingCode}',
                    style: TextStyle(
                      fontSize: 13,
                      color: context.c.accent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.booking.formattedTime,
                    style: TextStyle(fontSize: 12, color: context.c.inkSoft),
                  ),
                ],
              ),
            ),
            // Messages list
            Expanded(
              child: _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: context.c.accent),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[index];
                        final isUser = message.senderType == 'user';
                        final showDate =
                            index == 0 ||
                            !_isSameDay(
                              _messages[index - 1].timestamp,
                              message.timestamp,
                            );

                        return Column(
                          children: [
                            if (showDate)
                              _buildDateSeparator(message.timestamp),
                            _buildMessageBubble(message, isUser),
                          ],
                        );
                      },
                    ),
            ),
            // Message input or read-only banner
            if (_bolehKirim == false)
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: context.c.raised,
                  border: Border(top: BorderSide(color: context.c.line)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 16,
                      color: context.c.inkSoft,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "Pemesanan sudah selesai, chat ditutup",
                      style: TextStyle(color: context.c.inkSoft, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(context).padding.bottom + 12,
                ),
                decoration: BoxDecoration(
                  color: context.c.surface,
                  border: Border(top: BorderSide(color: context.c.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.c.raised,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: context.c.line),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: context.c.ink),
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            hintStyle: TextStyle(color: context.c.inkSoft),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          maxLines: null,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: context.c.accent,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: context.c.onAccent,
                                ),
                              )
                            : Icon(Icons.send, color: context.c.onAccent),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    String dateText;

    if (_isSameDay(date, now)) {
      dateText = 'Hari ini';
    } else if (_isSameDay(date, now.subtract(const Duration(days: 1)))) {
      dateText = 'Kemarin';
    } else {
      dateText = DateFormat('dd MMMM yyyy', 'id').format(date);
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.c.line)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: TextStyle(fontSize: 12, color: context.c.inkSoft),
            ),
          ),
          Expanded(child: Divider(color: context.c.line)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isUser ? 60 : 0,
          right: isUser ? 0 : 60,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? context.c.accent : context.c.raised,
          border: isUser ? null : Border.all(color: context.c.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                color: isUser ? context.c.onAccent : context.c.ink,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isUser
                        ? context.c.onAccent.withValues(alpha: 0.6)
                        : context.c.inkSoft,
                  ),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.status == MessageStatus.read
                        ? Icons.done_all
                        : message.status == MessageStatus.delivered
                        ? Icons.done_all
                        : Icons.done,
                    size: 14,
                    color: message.status == MessageStatus.read
                        ? context.c.onAccent
                        : context.c.onAccent.withValues(alpha: 0.6),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
