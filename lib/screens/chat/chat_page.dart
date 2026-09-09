import 'package:flutter/material.dart';
import '../../theme/app_tokens.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../constants/colors.dart';
import '../../models/booking.dart';
import 'chat_models.dart';
import 'chat_service.dart';

// Chat untuk user menghubungi partner venue
// Entry point: halaman e-ticket setelah booking confirmed

class ChatPage extends StatefulWidget {
  final Booking booking;
  final bool isReadOnly;

  const ChatPage({super.key, required this.booking, this.isReadOnly = false});

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

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final messages = await ChatService.getMessages(widget.booking.id);
    final partner = await ChatService.getPartnerContact(widget.booking.id);

    setState(() {
      _messages = messages;
      _partnerContact = partner;
      _isLoading = false;
    });
    _scrollToBottom();
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

    final message = await ChatService.sendMessage(widget.booking.id, content);

    if (message != null) {
      setState(() {
        _messages.add(message);
        _isSending = false;
      });
      _scrollToBottom();
    } else {
      setState(() => _isSending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal mengirim pesan')),
        );
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

  void _showPartnerInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.brandYellow.withValues(alpha: 0.15),
              child: Text(
                _partnerContact?.name.isNotEmpty == true
                    ? _partnerContact!.name[0].toUpperCase()
                    : 'P',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandYellow,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _partnerContact?.name ?? 'Partner',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.onDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _partnerContact?.venueName ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.onDarkMuted,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.location_on, size: 14, color: AppColors.onDarkMuted),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    _partnerContact?.address ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.onDarkMuted,
                    ),
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
                icon: const Icon(Icons.phone, color: AppColors.brandYellow),
                label: const Text('Telepon', style: TextStyle(color: AppColors.brandYellow)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: AppColors.brandYellow),
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        systemOverlayStyle: gayaOverlay(context),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.onDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: _showPartnerInfo,
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.brandYellow.withValues(alpha: 0.15),
                child: Text(
                  _partnerContact?.name.isNotEmpty == true
                      ? _partnerContact!.name[0].toUpperCase()
                      : 'P',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandYellow,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onDark,
                      ),
                    ),
                    Text(
                      widget.booking.field?.venue?.name ?? '',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.onDarkMuted,
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
            icon: const Icon(Icons.phone, color: AppColors.onDark),
            onPressed: _callPartner,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: AppColors.onDark),
            onPressed: _showPartnerInfo,
          ),
        ],
      ),
      body: Column(
        children: [
          // Booking info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.confirmation_number, size: 16, color: AppColors.brandYellow),
                const SizedBox(width: 8),
                Text(
                  'Booking: ${widget.booking.bookingCode}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.brandYellow,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.booking.formattedTime,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.onDarkMuted,
                  ),
                ),
              ],
            ),
          ),
          // Messages list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.brandYellow))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isUser = message.senderType == 'user';
                      final showDate = index == 0 ||
                          !_isSameDay(
                            _messages[index - 1].timestamp,
                            message.timestamp,
                          );

                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(message.timestamp),
                          _buildMessageBubble(message, isUser),
                        ],
                      );
                    },
                  ),
          ),
          // Message input or read-only banner
          if (widget.isReadOnly)
            Container(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).padding.bottom + 12,
              ),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 16, color: AppColors.onDarkMuted),
                  const SizedBox(width: 8),
                  const Text(
                    "Chat sudah ditutup karena booking selesai",
                    style: TextStyle(color: AppColors.onDarkMuted, fontSize: 13),
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
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: AppColors.onDark),
                      decoration: const InputDecoration(
                        hintText: 'Ketik pesan...',
                        hintStyle: TextStyle(color: AppColors.onDarkMuted),
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
                  decoration: const BoxDecoration(
                    color: AppColors.brandYellow,
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
                              color: AppColors.ink,
                            ),
                          )
                        : const Icon(Icons.send, color: AppColors.ink),
                  ),
                ),
              ],
            ),
          ),
        ],
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
          const Expanded(child: Divider(color: AppColors.surfaceBorder)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              dateText,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onDarkMuted,
              ),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.surfaceBorder)),
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
          color: isUser ? AppColors.brandYellow : AppColors.surface,
          border: isUser ? null : Border.all(color: AppColors.surfaceBorder),
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
                color: isUser ? AppColors.ink : AppColors.onDark,
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
                        ? AppColors.ink.withValues(alpha: 0.6)
                        : AppColors.onDarkMuted,
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
                        ? AppColors.ink
                        : AppColors.ink.withValues(alpha: 0.6),
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
