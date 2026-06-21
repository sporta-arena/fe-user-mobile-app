import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/review.dart';
import 'auth_service.dart';

class ReviewResult {
  final bool success;
  final String? message;
  final Review? review;
  final List<Review>? reviews;
  final CanReviewResult? canReviewResult;
  final Map<String, dynamic>? pagination;
  final Map<String, List<String>>? errors;

  ReviewResult({
    required this.success,
    this.message,
    this.review,
    this.reviews,
    this.canReviewResult,
    this.pagination,
    this.errors,
  });
}

class ReviewService {
  /// Get venue reviews (public)
  static Future<ReviewResult> getVenueReviews(int venueId, {int page = 1}) async {
    try {
      final uri = Uri.parse(ApiConfig.venueReviewsUrl(venueId))
          .replace(queryParameters: {'page': page.toString()});

      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final reviewsData = data['data'] ?? data['reviews'] ?? [];
        final reviews = (reviewsData as List)
            .map((r) => Review.fromJson(r))
            .toList();

        return ReviewResult(
          success: true,
          reviews: reviews,
          pagination: {
            'current_page': data['meta']?['current_page'] ?? data['current_page'] ?? 1,
            'last_page': data['meta']?['last_page'] ?? data['last_page'] ?? 1,
            'total': data['meta']?['total'] ?? data['total'] ?? 0,
          },
        );
      } else {
        return ReviewResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat review',
        );
      }
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Create a review for a booking
  static Future<ReviewResult> createReview({
    required int bookingId,
    required int rating,
    String? comment,
  }) async {
    if (AuthService.token == null) {
      return ReviewResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.reviewsUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
        body: jsonEncode({
          'booking_id': bookingId,
          'rating': rating,
          'comment': comment,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final reviewData = data['data'] ?? data['review'];
        return ReviewResult(
          success: true,
          message: data['message'] ?? 'Review berhasil ditambahkan',
          review: reviewData != null ? Review.fromJson(reviewData) : null,
        );
      } else {
        return ReviewResult(
          success: false,
          message: data['message'] ?? 'Gagal menambahkan review',
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map((key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get my reviews
  static Future<ReviewResult> getMyReviews({int page = 1}) async {
    if (AuthService.token == null) {
      return ReviewResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final uri = Uri.parse(ApiConfig.myReviewsUrl)
          .replace(queryParameters: {'page': page.toString()});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final reviewsData = data['data'] ?? data['reviews'] ?? [];
        final reviews = (reviewsData as List)
            .map((r) => Review.fromJson(r))
            .toList();

        return ReviewResult(
          success: true,
          reviews: reviews,
          pagination: {
            'current_page': data['meta']?['current_page'] ?? data['current_page'] ?? 1,
            'last_page': data['meta']?['last_page'] ?? data['last_page'] ?? 1,
            'total': data['meta']?['total'] ?? data['total'] ?? 0,
          },
        );
      } else {
        return ReviewResult(
          success: false,
          message: data['message'] ?? 'Gagal memuat review',
        );
      }
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Check if user can review a booking
  static Future<ReviewResult> canReviewBooking(int bookingId) async {
    if (AuthService.token == null) {
      return ReviewResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.canReviewBookingUrl(bookingId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ReviewResult(
          success: true,
          canReviewResult: CanReviewResult.fromJson(data),
        );
      } else {
        return ReviewResult(
          success: false,
          message: data['message'] ?? 'Gagal memeriksa status review',
        );
      }
    } catch (e) {
      return ReviewResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }
}
