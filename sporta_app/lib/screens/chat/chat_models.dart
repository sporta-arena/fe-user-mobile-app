import '../../utils/timezone_utils.dart';

enum MessageType { text, image, file }

enum MessageStatus { sending, sent, delivered, read }

class Message {
  final String id;
  final String bookingId;
  final String senderId;
  final String senderName;
  final String senderType; // 'partner' or 'user'
  final String content;
  final DateTime timestamp;
  final MessageType type;
  final MessageStatus status;

  Message({
    required this.id,
    required this.bookingId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.timestamp,
    this.type = MessageType.text,
    this.status = MessageStatus.sent,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      bookingId: json['booking_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      senderName: json['sender_name'] ?? '',
      senderType: json['sender_type'] ?? 'user',
      content: json['content'] ?? '',
      // Parse UTC timestamp from server and convert to local
      timestamp: json['timestamp'] != null
          ? TimezoneUtils.parseUtcToLocal(json['timestamp'])
          : DateTime.now(),
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.text,
      ),
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_type': senderType,
      'content': content,
      // Convert to UTC when sending to server
      'timestamp': TimezoneUtils.formatToUtcString(timestamp),
      'type': type.name,
      'status': status.name,
    };
  }
}

class PartnerContact {
  final String id;
  final String name;
  final String phone;
  final String? imageUrl;
  final String venueName;
  final String address;

  PartnerContact({
    required this.id,
    required this.name,
    required this.phone,
    this.imageUrl,
    required this.venueName,
    required this.address,
  });

  factory PartnerContact.fromJson(Map<String, dynamic> json) {
    return PartnerContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['image_url'],
      venueName: json['venue_name'] ?? '',
      address: json['address'] ?? '',
    );
  }
}
