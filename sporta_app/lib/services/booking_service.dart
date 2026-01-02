import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/booking.dart';
import 'auth_service.dart';

class BookingResult {
  final bool success;
  final String? message;
  final Booking? booking;
  final List<Booking>? bookings;
  final Map<String, dynamic>? payment;
  final Map<String, dynamic>? pagination;
  final Map<String, List<String>>? errors;

  BookingResult({
    required this.success,
    this.message,
    this.booking,
    this.bookings,
    this.payment,
    this.pagination,
    this.errors,
  });
}

class BookingService {
  /// Create a new booking
  static Future<BookingResult> createBooking({
    required int fieldId,
    required String bookingDate,
    required String startTime,
    required int durationHours,
    String? notes,
    String? paymentMethod,
  }) async {
    if (AuthService.token == null) {
      return BookingResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final requestBody = {
        'field_id': fieldId,
        'booking_date': bookingDate,
        'start_time': startTime,
        'duration_hours': durationHours,
        'notes': notes,
        'payment_method': paymentMethod ?? 'QRIS',
      };

      debugPrint('=== API REQUEST ===');
      debugPrint('URL: ${ApiConfig.bookingsUrl}');
      debugPrint('Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse(ApiConfig.bookingsUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
        body: jsonEncode(requestBody),
      );

      debugPrint('=== API RESPONSE ===');
      debugPrint('Status: ${response.statusCode}');
      debugPrint('Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return BookingResult(
          success: true,
          message: data['message'],
          booking: Booking.fromJson(data['booking']),
          payment: data['payment'],
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map((key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get my bookings
  static Future<BookingResult> getMyBookings({int page = 1}) async {
    if (AuthService.token == null) {
      return BookingResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final uri = Uri.parse(ApiConfig.bookingsUrl)
          .replace(queryParameters: {'page': page.toString()});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookings = (data['data'] as List)
            .map((b) => Booking.fromJson(b))
            .toList();

        return BookingResult(
          success: true,
          bookings: bookings,
          pagination: {
            'current_page': data['current_page'],
            'last_page': data['last_page'],
            'total': data['total'],
          },
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get booking detail
  static Future<BookingResult> getBookingDetail(int id) async {
    if (AuthService.token == null) {
      return BookingResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.bookingDetailUrl(id)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BookingResult(
          success: true,
          booking: Booking.fromJson(data['booking']),
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Cancel booking
  static Future<BookingResult> cancelBooking(int id) async {
    if (AuthService.token == null) {
      return BookingResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.cancelBookingUrl(id)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BookingResult(
          success: true,
          message: data['message'],
          booking: Booking.fromJson(data['booking']),
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Simulate payment (development only)
  static Future<BookingResult> simulatePayment(int bookingId) async {
    if (AuthService.token == null) {
      return BookingResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.simulatePaymentUrl(bookingId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return BookingResult(
          success: true,
          message: data['message'],
          booking: Booking.fromJson(data['booking']),
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  // ========== Partner Endpoints ==========

  /// Get partner bookings
  static Future<BookingResult> getPartnerBookings({int page = 1}) async {
    if (AuthService.token == null) {
      return BookingResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final uri = Uri.parse(ApiConfig.partnerBookingsUrl)
          .replace(queryParameters: {'page': page.toString()});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookings = (data['data'] as List)
            .map((b) => Booking.fromJson(b))
            .toList();

        return BookingResult(
          success: true,
          bookings: bookings,
          pagination: {
            'current_page': data['current_page'],
            'last_page': data['last_page'],
            'total': data['total'],
          },
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get venue schedule for a specific date
  static Future<Map<String, dynamic>> getVenueSchedule(int venueId, String date) async {
    if (AuthService.token == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      final uri = Uri.parse(ApiConfig.venueScheduleUrl(venueId))
          .replace(queryParameters: {'date': date});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'venue': data['venue'],
          'date': data['date'],
          'schedule': data['schedule'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung ke server: $e',
      };
    }
  }
}
