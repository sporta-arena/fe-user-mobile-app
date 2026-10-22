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
      onDibaca: _terimaTandaBaca,
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

  /// Mitra baru saja membaca pesan kita: semua pesan milik pemesan yang
  /// belum biru jadi biru, sama dengan yang ditandai server.
  void _terimaTandaBaca(Map<String, dynamic> data) {
    if (!mounted || data['sender_type'] != 'user') return;
    setState(() {
      _messages = [
        for (final m in _messages)
          m.senderType == 'user' && m.status != MessageStatus.read
              ? m.withStatus(MessageStatus.read)
              : m,
      ];
    });
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
                  fontWeight: FontWeight.w800,
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
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: sedangKirim
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: SportagoColors.pure,
                          ),
                        )
                      : const Text(
                          'Kirim Laporan',
                          style: TextStyle(
                            color: SportagoColors.pure,
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
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + context.sisipanBawah),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: SportagoColors.pekat,
              child: Text(
                _partnerContact?.name.isNotEmpty == true
                    ? _partnerContact!.name[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: SportagoColors.volt,
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
                    borderRadius: BorderRadius.circular(14),
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
    // Bilah aplikasi pekat dari tema, jadi teksnya memakai warna
    // "di atas media", bukan tinta halaman.
    final media = context.c.onMedia;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _showPartnerInfo,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: SportagoColors.pekatNaik,
                child: Text(
                  _partnerContact?.name.isNotEmpty == true
                      ? _partnerContact!.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: SportagoColors.volt,
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
                        fontWeight: FontWeight.w800,
                        color: media.ink,
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
                            ? media.warn
                            : media.inkSoft,
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
            icon: const Icon(Icons.phone_rounded),
            onPressed: _callPartner,
          ),
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Laporkan percakapan',
            onPressed: _laporkan,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded),
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
            // Pita kode booking menyambung dari bilah pekat di atasnya.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: SportagoColors.pekatNaik,
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_rounded,
                    size: 16,
                    color: SportagoColors.volt,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Booking: ${widget.booking.bookingCode}',
                    style: TextStyle(
                      fontSize: 13,
                      color: media.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.booking.formattedTime,
                    style: TextStyle(fontSize: 12, color: media.inkSoft),
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
                  color: context.c.sunken,
                  border: Border(top: BorderSide(color: context.c.lineStrong)),
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
                    Flexible(
                      child: Text(
                        "Pemesanan sudah selesai, chat ditutup",
                        style: TextStyle(
                          color: context.c.inkSoft,
                          fontSize: 13,
                        ),
                      ),
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
                  color: context.c.raised,
                  border: Border(top: BorderSide(color: context.c.line)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: context.c.sunken,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          style: TextStyle(color: context.c.ink),
                          decoration: InputDecoration(
                            hintText: 'Ketik pesan...',
                            hintStyle: TextStyle(color: context.c.inkSoft),
                            // Garis tema dimatikan: bidangnya sudah
                            // berbentuk pil dari wadah di luarnya.
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
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
                    // Tombol kirim pekat ber-ikon volt, seperti tombol
                    // utama di halaman lain.
                    Container(
                      decoration: const BoxDecoration(
                        color: SportagoColors.pekat,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isSending ? null : _sendMessage,
                        icon: _isSending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: SportagoColors.volt,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: SportagoColors.volt,
                              ),
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: context.c.raised,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: context.c.line),
              ),
              child: Text(
                dateText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.c.inkSoft,
                ),
              ),
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? SportagoColors.pekat : context.c.raised,
          border: isUser ? null : Border.all(color: context.c.line),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isUser ? 18 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message.content,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: isUser ? SportagoColors.pure : context.c.ink,
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
                        ? context.c.onMedia.inkSoft
                        : context.c.inkDim,
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
                    // Sudah dibaca: volt, supaya beda dari terkirim.
                    color: message.status == MessageStatus.read
                        ? SportagoColors.volt
                        : context.c.onMedia.inkSoft,
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
