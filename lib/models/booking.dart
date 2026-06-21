import 'field.dart';
import 'user.dart';
import '../utils/timezone_utils.dart';

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
      id: json['id'] ?? 0,
      bookingCode: json['booking_code'] ?? '',
      userId: json['user_id'] ?? json['user']?['id'] ?? 0,
      fieldId: json['field_id'] ?? json['field']?['id'] ?? 0,
      bookingDate: json['booking_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      durationHours: json['duration_hours'] ?? 1,
      pricePerHour: json['price_per_hour'] != null
          ? double.parse(json['price_per_hour'].toString())
          : 0,
      totalPrice: json['total_price'] != null
          ? double.parse(json['total_price'].toString())
          : 0,
      status: json['status'] ?? 'pending',
      // Parse UTC datetime from server
      expiresAt: json['expires_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['expires_at'])
          : null,
      paidAt: json['paid_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['paid_at'])
          : null,
      notes: json['notes'],
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : DateTime.now(),
      field: json['field'] != null ? Field.fromJson(json['field']) : null,
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isExpired => status == 'expired';

  bool get canCancel => isPending || isConfirmed;
  bool get isActive => isConfirmed || isCheckedIn; // User can play

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
      case 'checked_in':
        return 'Sedang Bermain';
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
      id: json['id'] ?? 0,
      xenditId: json['xendit_id'],
      externalId: json['external_id'] ?? '',
      amount: json['amount'] != null ? double.parse(json['amount'].toString()) : 0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['payment_method'] ?? 'qris',
      qrString: json['qr_string'],
      // Parse UTC datetime from server
      paidAt: json['paid_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['paid_at'])
          : null,
      expiresAt: json['expires_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['expires_at'])
          : null,
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : DateTime.now(),
    );
  }

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isExpired => status == 'expired';
}
