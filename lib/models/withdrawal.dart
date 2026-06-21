import 'booking.dart';
import '../utils/timezone_utils.dart';

class Withdrawal {
  final int id;
  final int userId;
  final double amount;
  final String bankCode;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String status; // pending, processing, completed, failed, rejected
  final String? adminNotes;
  final String? xenditDisbursementId;
  final DateTime? processedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WithdrawalBooking>? bookings;

  Withdrawal({
    required this.id,
    required this.userId,
    required this.amount,
    required this.bankCode,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    required this.status,
    this.adminNotes,
    this.xenditDisbursementId,
    this.processedAt,
    required this.createdAt,
    required this.updatedAt,
    this.bookings,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : 0,
      bankCode: json['bank_code'] ?? '',
      bankName: json['bank_name'] ?? '',
      accountNumber: json['account_number'] ?? '',
      accountName: json['account_name'] ?? '',
      status: json['status'] ?? 'pending',
      adminNotes: json['admin_notes'],
      xenditDisbursementId: json['xendit_disbursement_id'],
      processedAt: json['processed_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['processed_at'])
          : null,
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : DateTime.now(),
      bookings: json['bookings'] != null
          ? (json['bookings'] as List)
              .map((b) => WithdrawalBooking.fromJson(b))
              .toList()
          : null,
    );
  }

  bool get isPending => status == 'pending';
  bool get isProcessing => status == 'processing';
  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isRejected => status == 'rejected';

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Menunggu Proses';
      case 'processing':
        return 'Sedang Diproses';
      case 'completed':
        return 'Selesai';
      case 'failed':
        return 'Gagal';
      case 'rejected':
        return 'Ditolak';
      default:
        return status;
    }
  }

  String get formattedAmount => 'Rp ${_formatNumber(amount.toInt())}';

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class WithdrawalBooking {
  final int id;
  final int bookingId;
  final int withdrawalId;
  final double amount;
  final Booking? booking;

  WithdrawalBooking({
    required this.id,
    required this.bookingId,
    required this.withdrawalId,
    required this.amount,
    this.booking,
  });

  factory WithdrawalBooking.fromJson(Map<String, dynamic> json) {
    return WithdrawalBooking(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? 0,
      withdrawalId: json['withdrawal_id'] ?? 0,
      amount: json['amount'] != null
          ? double.parse(json['amount'].toString())
          : 0,
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
    );
  }
}

class WithdrawalBalance {
  final double availableBalance;
  final double pendingBalance;
  final double totalWithdrawn;
  final int eligibleBookingsCount;

  WithdrawalBalance({
    required this.availableBalance,
    required this.pendingBalance,
    required this.totalWithdrawn,
    required this.eligibleBookingsCount,
  });

  factory WithdrawalBalance.fromJson(Map<String, dynamic> json) {
    return WithdrawalBalance(
      availableBalance: json['available_balance'] != null
          ? double.parse(json['available_balance'].toString())
          : 0,
      pendingBalance: json['pending_balance'] != null
          ? double.parse(json['pending_balance'].toString())
          : 0,
      totalWithdrawn: json['total_withdrawn'] != null
          ? double.parse(json['total_withdrawn'].toString())
          : 0,
      eligibleBookingsCount: json['eligible_bookings_count'] ?? 0,
    );
  }

  String get formattedAvailableBalance => 'Rp ${_formatNumber(availableBalance.toInt())}';
  String get formattedPendingBalance => 'Rp ${_formatNumber(pendingBalance.toInt())}';
  String get formattedTotalWithdrawn => 'Rp ${_formatNumber(totalWithdrawn.toInt())}';

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

class Bank {
  final String code;
  final String name;

  Bank({
    required this.code,
    required this.name,
  });

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['code'] ?? '',
      name: json['name'] ?? '',
    );
  }
}

class EligibleBooking {
  final int bookingId;
  final String bookingCode;
  final double refundableAmount;
  final String venueName;
  final String fieldName;
  final String bookingDate;
  final Booking? booking;

  EligibleBooking({
    required this.bookingId,
    required this.bookingCode,
    required this.refundableAmount,
    required this.venueName,
    required this.fieldName,
    required this.bookingDate,
    this.booking,
  });

  factory EligibleBooking.fromJson(Map<String, dynamic> json) {
    return EligibleBooking(
      bookingId: json['booking_id'] ?? json['id'] ?? 0,
      bookingCode: json['booking_code'] ?? '',
      refundableAmount: json['refundable_amount'] != null
          ? double.parse(json['refundable_amount'].toString())
          : 0,
      venueName: json['venue_name'] ?? json['venue']?['name'] ?? '',
      fieldName: json['field_name'] ?? json['field']?['name'] ?? '',
      bookingDate: json['booking_date'] ?? '',
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
    );
  }

  String get formattedRefundableAmount => 'Rp ${_formatNumber(refundableAmount.toInt())}';

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
