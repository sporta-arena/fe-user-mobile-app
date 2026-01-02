import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/refund.dart';
import 'auth_service.dart';

class RefundResult {
  final bool success;
  final String? message;
  final Refund? refund;
  final List<Refund>? refunds;
  final RefundPolicy? policy;
  final Map<String, dynamic>? policyData;

  RefundResult({
    required this.success,
    this.message,
    this.refund,
    this.refunds,
    this.policy,
    this.policyData,
  });
}

class RefundService {
  /// Get refund policy for a booking
  static Future<RefundResult> getRefundPolicy(int bookingId) async {
    if (AuthService.token == null) {
      return RefundResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.refundPolicyUrl(bookingId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return RefundResult(
          success: true,
          policyData: data,
        );
      } else {
        return RefundResult(
          success: false,
          message: data['message'] ?? 'Gagal mendapatkan kebijakan refund',
        );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Request a refund for a booking
  static Future<RefundResult> requestRefund({
    required int bookingId,
    required String reason,
  }) async {
    if (AuthService.token == null) {
      return RefundResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.requestRefundUrl(bookingId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
        body: jsonEncode({
          'reason': reason,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return RefundResult(
          success: true,
          message: data['message'] ?? 'Permintaan refund berhasil diajukan',
          refund: data['refund'] != null ? Refund.fromJson(data['refund']) : null,
        );
      } else {
        return RefundResult(
          success: false,
          message: data['message'] ?? 'Gagal mengajukan refund',
        );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get my refund requests
  static Future<RefundResult> getMyRefunds() async {
    if (AuthService.token == null) {
      return RefundResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.refundsUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final refunds = (data['data'] as List? ?? [])
            .map((r) => Refund.fromJson(r))
            .toList();

        return RefundResult(
          success: true,
          refunds: refunds,
        );
      } else {
        return RefundResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat data refund',
        );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get refund detail
  static Future<RefundResult> getRefundDetail(int refundId) async {
    if (AuthService.token == null) {
      return RefundResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.refundDetailUrl(refundId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return RefundResult(
          success: true,
          refund: Refund.fromJson(data['refund']),
        );
      } else {
        return RefundResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat detail refund',
        );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Cancel refund request (if still pending)
  static Future<RefundResult> cancelRefundRequest(int refundId) async {
    if (AuthService.token == null) {
      return RefundResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.delete(
        Uri.parse(ApiConfig.refundDetailUrl(refundId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return RefundResult(
          success: true,
          message: data['message'] ?? 'Permintaan refund dibatalkan',
        );
      } else {
        return RefundResult(
          success: false,
          message: data['message'] ?? 'Gagal membatalkan permintaan refund',
        );
      }
    } catch (e) {
      return RefundResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }
}
