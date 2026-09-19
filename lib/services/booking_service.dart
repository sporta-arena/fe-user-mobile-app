import 'dart:convert';
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

  /// Apakah simulasi benar-benar dijalankan lewat API Xendit.
  ///
  /// Backend mencoba `/qr_codes/{id}/payments/simulate` dulu supaya webhook
  /// aslinya ikut terpicu. Kalau itu tidak bisa, ia menandai lunas langsung
  /// di basis data dan mengaku lewat `simulated_by_gateway: false` berikut
  /// alasannya. App dulu membuang dua nilai itu, jadi tombol ujinya selalu
  /// terlihat berhasil dan tidak ada cara membedakan "gateway benar-benar
  /// dipakai" dari "dilewati".
  final bool? simulatedByGateway;

  /// Alasan gateway dilewati, dari `fallback_reason`.
  final String? alasanGatewayDilewati;

  BookingResult({
    required this.success,
    this.message,
    this.booking,
    this.bookings,
    this.payment,
    this.pagination,
    this.errors,
    this.simulatedByGateway,
    this.alasanGatewayDilewati,
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
    String? promoCode,
  }) async {
    if (AuthService.token == null) {
      return BookingResult(
        success: false,
        message: 'Silakan login terlebih dahulu',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.bookingsUrl),
            headers: ApiConfig.authHeaders(AuthService.token!),
            body: jsonEncode({
              'field_id': fieldId,
              'booking_date': bookingDate,
              'start_time': startTime,
              'duration_hours': durationHours,
              'notes': notes,
              // API memakai kode huruf kecil ('qris', 'va_bca', ...) dan
              // memvalidasinya persis. App menyimpan id metode dengan huruf
              // besar untuk tampilan, jadi harus diturunkan di sini.
              // Sebelumnya setiap pemesanan dari app ditolak 422
              // "Selected payment method is not supported."
              'payment_method': (paymentMethod ?? 'qris').toLowerCase(),
              // Diperiksa ulang server DI DALAM transaksi pemesanan, bukan
              // dipercaya dari hasil /promos/cek sebelumnya: kuota bisa
              // habis di sela antara keduanya.
              if (promoCode != null && promoCode.isNotEmpty)
                'promo_code': promoCode,
            }),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // API returns 'data' not 'booking'
        final bookingData = data['data'] ?? data['booking'];
        return BookingResult(
          success: true,
          message: data['message'],
          booking: Booking.fromJson(bookingData),
          payment: data['payment'],
        );
      } else {
        return BookingResult(
          success: false,
          message: data['message'],
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map(
                    (key, value) => MapEntry(key, List<String>.from(value)),
                  ),
                )
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
  ///
  /// [perPage] dibutuhkan halaman Profil, yang harus menjumlahkan
  /// SELURUH booking, bukan satu halaman saja.
  static Future<BookingResult> getMyBookings({
    int page = 1,
    int? perPage,
  }) async {
    if (AuthService.token == null) {
      return BookingResult(
        success: false,
        message: 'Silakan login terlebih dahulu',
      );
    }

    try {
      final uri = Uri.parse(ApiConfig.bookingsUrl).replace(
        queryParameters: {
          'page': page.toString(),
          if (perPage != null) 'per_page': perPage.toString(),
        },
      );

      final response = await http
          .get(uri, headers: ApiConfig.authHeaders(AuthService.token!))
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookings = (data['data'] as List)
            .map((b) => Booking.fromJson(b))
            .toList();

        return BookingResult(
          success: true,
          bookings: bookings,
          pagination: {
            'current_page':
                data['meta']?['current_page'] ?? data['current_page'],
            'last_page': data['meta']?['last_page'] ?? data['last_page'],
            'total': data['meta']?['total'] ?? data['total'],
          },
        );
      } else {
        return BookingResult(success: false, message: data['message']);
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
      return BookingResult(
        success: false,
        message: 'Silakan login terlebih dahulu',
      );
    }

    try {
      final response = await http
          .get(
            Uri.parse(ApiConfig.bookingDetailUrl(id)),
            headers: ApiConfig.authHeaders(AuthService.token!),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // API returns 'data' not 'booking'
        final bookingData = data['data'] ?? data['booking'];
        return BookingResult(
          success: true,
          booking: Booking.fromJson(bookingData),
        );
      } else {
        return BookingResult(success: false, message: data['message']);
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
      return BookingResult(
        success: false,
        message: 'Silakan login terlebih dahulu',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.cancelBookingUrl(id)),
            headers: ApiConfig.authHeaders(AuthService.token!),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // API returns 'data' not 'booking'
        final bookingData = data['data'] ?? data['booking'];
        return BookingResult(
          success: true,
          message: data['message'],
          booking: Booking.fromJson(bookingData),
        );
      } else {
        return BookingResult(success: false, message: data['message']);
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
      return BookingResult(
        success: false,
        message: 'Silakan login terlebih dahulu',
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse(ApiConfig.simulatePaymentUrl(bookingId)),
            headers: ApiConfig.authHeaders(AuthService.token!),
          )
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // API returns 'data' not 'booking'
        final bookingData = data['data'] ?? data['booking'];
        return BookingResult(
          success: true,
          message: data['message'],
          booking: Booking.fromJson(bookingData),
          simulatedByGateway: data['simulated_by_gateway'] == true,
          alasanGatewayDilewati: data['fallback_reason'] as String?,
        );
      } else {
        return BookingResult(success: false, message: data['message']);
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
      return BookingResult(
        success: false,
        message: 'Silakan login terlebih dahulu',
      );
    }

    try {
      final uri = Uri.parse(
        ApiConfig.partnerBookingsUrl,
      ).replace(queryParameters: {'page': page.toString()});

      final response = await http
          .get(uri, headers: ApiConfig.authHeaders(AuthService.token!))
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookings = (data['data'] as List)
            .map((b) => Booking.fromJson(b))
            .toList();

        return BookingResult(
          success: true,
          bookings: bookings,
          pagination: {
            'current_page':
                data['meta']?['current_page'] ?? data['current_page'],
            'last_page': data['meta']?['last_page'] ?? data['last_page'],
            'total': data['meta']?['total'] ?? data['total'],
          },
        );
      } else {
        return BookingResult(success: false, message: data['message']);
      }
    } catch (e) {
      return BookingResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get venue schedule for a specific date
  static Future<Map<String, dynamic>> getVenueSchedule(
    int venueId,
    String date,
  ) async {
    if (AuthService.token == null) {
      return {'success': false, 'message': 'Silakan login terlebih dahulu'};
    }

    try {
      final uri = Uri.parse(
        ApiConfig.venueScheduleUrl(venueId),
      ).replace(queryParameters: {'date': date});

      final response = await http
          .get(uri, headers: ApiConfig.authHeaders(AuthService.token!))
          .timeout(const Duration(seconds: 20));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'venue': data['venue'],
          'date': data['date'],
          'schedule': data['schedule'],
        };
      } else {
        return {'success': false, 'message': data['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Gagal terhubung ke server: $e'};
    }
  }

}
