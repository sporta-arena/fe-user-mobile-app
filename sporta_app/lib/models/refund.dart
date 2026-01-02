import '../utils/timezone_utils.dart';
import 'booking.dart';

class Refund {
  final int id;
  final int bookingId;
  final int userId;
  final double amount;
  final double refundAmount;
  final int refundPercentage;
  final String reason;
  final String status; // pending, approved, rejected, processing, completed, failed
  final String? adminNotes;
  final String? xenditRefundId;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Booking? booking;

  Refund({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.refundAmount,
    required this.refundPercentage,
    required this.reason,
    required this.status,
    this.adminNotes,
    this.xenditRefundId,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    this.booking,
  });

  factory Refund.fromJson(Map<String, dynamic> json) {
    return Refund(
      id: json['id'],
      bookingId: json['booking_id'],
      userId: json['user_id'],
      amount: double.parse(json['amount'].toString()),
      refundAmount: double.parse(json['refund_amount'].toString()),
      refundPercentage: json['refund_percentage'] ?? 100,
      reason: json['reason'] ?? '',
      status: json['status'],
      adminNotes: json['admin_notes'],
      xenditRefundId: json['xendit_refund_id'],
      processedAt: json['processed_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['processed_at'])
          : null,
      createdAt: TimezoneUtils.parseUtcToLocal(json['created_at']),
      updatedAt: TimezoneUtils.parseUtcToLocal(json['updated_at']),
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Persetujuan';
      case 'approved':
        return 'Disetujui';
      case 'rejected':
        return 'Ditolak';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }

  String get formattedRefundAmount {
    return 'Rp ${_formatNumber(refundAmount.toInt())}';
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

/// Refund policy calculation
class RefundPolicy {
  final int percentage;
  final String description;
  final bool canRefund;

  RefundPolicy({
    required this.percentage,
    required this.description,
    required this.canRefund,
  });

  /// Calculate refund policy based on booking date/time
  /// Refund only allowed if more than 3 days (H-3) before booking
  static RefundPolicy calculate(DateTime bookingDateTime) {
    final now = DateTime.now();
    final diff = bookingDateTime.difference(now);

    // Booking sudah berlalu
    if (diff.isNegative) {
      return RefundPolicy(
        percentage: 0,
        description: 'Booking sudah berlalu, tidak dapat di-refund',
        canRefund: false,
      );
    }

    // Lebih dari 3 hari sebelum jadwal (H-3) - bisa refund 100%
    if (diff.inDays >= 3) {
      return RefundPolicy(
        percentage: 100,
        description: 'Refund 100% (pembatalan > 3 hari sebelum jadwal)',
        canRefund: true,
      );
    }

    // Kurang dari 3 hari - tidak bisa refund
    return RefundPolicy(
      percentage: 0,
      description: 'Tidak dapat refund (sudah memasuki H-3 sebelum jadwal)',
      canRefund: false,
    );
  }

  /// Get remaining days until refund deadline
  static int getDaysUntilDeadline(DateTime bookingDateTime) {
    final now = DateTime.now();
    final deadline = bookingDateTime.subtract(const Duration(days: 3));
    final diff = deadline.difference(now);
    return diff.inDays;
  }
}
