import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/withdrawal.dart';
import 'auth_service.dart';

class WithdrawalResult {
  final bool success;
  final String? message;
  final Withdrawal? withdrawal;
  final List<Withdrawal>? withdrawals;
  final WithdrawalBalance? balance;
  final List<Bank>? banks;
  final List<EligibleBooking>? eligibleBookings;
  final Map<String, dynamic>? pagination;
  final Map<String, List<String>>? errors;

  WithdrawalResult({
    required this.success,
    this.message,
    this.withdrawal,
    this.withdrawals,
    this.balance,
    this.banks,
    this.eligibleBookings,
    this.pagination,
    this.errors,
  });
}

class WithdrawalService {
  /// Get withdrawal balance
  static Future<WithdrawalResult> getBalance() async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.withdrawalBalanceUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final balanceData = data['data'] ?? data;
        return WithdrawalResult(
          success: true,
          balance: WithdrawalBalance.fromJson(balanceData),
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat saldo',
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get eligible bookings for withdrawal
  static Future<WithdrawalResult> getEligibleBookings() async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.withdrawalEligibleBookingsUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookingsData = data['data'] ?? data['bookings'] ?? [];
        final eligibleBookings = (bookingsData as List)
            .map((b) => EligibleBooking.fromJson(b))
            .toList();

        return WithdrawalResult(
          success: true,
          eligibleBookings: eligibleBookings,
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat booking yang eligible',
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get supported banks
  static Future<WithdrawalResult> getBanks() async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.withdrawalBanksUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final banksData = data['data'] ?? data['banks'] ?? [];
        final banks = (banksData as List)
            .map((b) => Bank.fromJson(b))
            .toList();

        return WithdrawalResult(
          success: true,
          banks: banks,
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat daftar bank',
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Create withdrawal request
  static Future<WithdrawalResult> createWithdrawal({
    required List<int> bookingIds,
    required String bankCode,
    required String accountNumber,
    required String accountName,
  }) async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.withdrawalsUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
        body: jsonEncode({
          'booking_ids': bookingIds,
          'bank_code': bankCode,
          'account_number': accountNumber,
          'account_name': accountName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final withdrawalData = data['data'] ?? data['withdrawal'];
        return WithdrawalResult(
          success: true,
          message: data['message'] ?? 'Permintaan penarikan berhasil dibuat',
          withdrawal: withdrawalData != null ? Withdrawal.fromJson(withdrawalData) : null,
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal membuat permintaan penarikan',
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map((key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get my withdrawals
  static Future<WithdrawalResult> getWithdrawals({int page = 1}) async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final uri = Uri.parse(ApiConfig.withdrawalsUrl)
          .replace(queryParameters: {'page': page.toString()});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final withdrawalsData = data['data'] ?? [];
        final withdrawals = (withdrawalsData as List)
            .map((w) => Withdrawal.fromJson(w))
            .toList();

        return WithdrawalResult(
          success: true,
          withdrawals: withdrawals,
          pagination: {
            'current_page': data['meta']?['current_page'] ?? data['current_page'] ?? 1,
            'last_page': data['meta']?['last_page'] ?? data['last_page'] ?? 1,
            'total': data['meta']?['total'] ?? data['total'] ?? 0,
          },
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat daftar penarikan',
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get withdrawal detail
  static Future<WithdrawalResult> getWithdrawalDetail(int id) async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.withdrawalDetailUrl(id)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final withdrawalData = data['data'] ?? data['withdrawal'];
        return WithdrawalResult(
          success: true,
          withdrawal: Withdrawal.fromJson(withdrawalData),
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat detail penarikan',
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Simulate process (development only)
  static Future<WithdrawalResult> simulateProcess(int id) async {
    if (AuthService.token == null) {
      return WithdrawalResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.withdrawalSimulateProcessUrl(id)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final withdrawalData = data['data'] ?? data['withdrawal'];
        return WithdrawalResult(
          success: true,
          message: data['message'] ?? 'Simulasi berhasil',
          withdrawal: withdrawalData != null ? Withdrawal.fromJson(withdrawalData) : null,
        );
      } else {
        return WithdrawalResult(
          success: false,
          message: data['message'] ?? 'Gagal melakukan simulasi',
        );
      }
    } catch (e) {
      return WithdrawalResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }
}
