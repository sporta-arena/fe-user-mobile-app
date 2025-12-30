import 'field.dart';
import 'user.dart';

class Booking {
  final int id;
  final String bookingCode;
  final int userId;
  final int fieldId;
  final String bookingDate;
  final String startTime;
  final String endTime;
  final int durationHours;
  final double pricePerHour;
  final double totalPrice;
  final String status; // pending, confirmed, completed, cancelled, expired
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Field? field;
  final User? user;
  final Payment? payment;

  Booking({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.fieldId,
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.pricePerHour,
    required this.totalPrice,
    required this.status,
    this.expiresAt,
    this.paidAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.field,
    this.user,
    this.payment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      bookingCode: json['booking_code'],
      userId: json['user_id'],
      fieldId: json['field_id'],
      bookingDate: json['booking_date'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      durationHours: json['duration_hours'],
      pricePerHour: double.parse(json['price_per_hour'].toString()),
      totalPrice: double.parse(json['total_price'].toString()),
      status: json['status'],
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      field: json['field'] != null ? Field.fromJson(json['field']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  bool get canCancel => isPending || isConfirmed;

  String get formattedTotalPrice => 'Rp ${_formatNumber(totalPrice.toInt())}';

  String get formattedTime => '${_formatTimeString(startTime)} - ${_formatTimeString(endTime)}';

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String _formatTimeString(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'confirmed':
        return 'Terkonfirmasi';
      case 'completed':
        return 'Selesai';
      case 'cancelled':
        return 'Dibatalkan';
      case 'expired':
        return 'Kadaluarsa';
      default:
        return status;
    }
  }
}

class Payment {
  final int id;
  final String? xenditId;
  final String externalId;
  final double amount;
  final String status; // pending, paid, expired, failed
  final String paymentMethod;
  final String? qrString;
  final DateTime? paidAt;
  final DateTime? expiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Payment({
    required this.id,
    this.xenditId,
    required this.externalId,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.qrString,
    this.paidAt,
    this.expiresAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      xenditId: json['xendit_id'],
      externalId: json['external_id'],
      amount: double.parse(json['amount'].toString()),
      status: json['status'],
      paymentMethod: json['payment_method'] ?? 'qris',
      qrString: json['qr_string'],
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at']) : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';
}
