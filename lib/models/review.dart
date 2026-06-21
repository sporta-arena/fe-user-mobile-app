import 'user.dart';
import 'booking.dart';
import 'venue.dart';
import '../utils/timezone_utils.dart';

class Review {
  final int id;
  final int bookingId;
  final int userId;
  final int venueId;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime? repliedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? user;
  final Booking? booking;
  final Venue? venue;

  Review({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.venueId,
    required this.rating,
    this.comment,
    this.reply,
    this.repliedAt,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.booking,
    this.venue,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] ?? 0,
      bookingId: json['booking_id'] ?? json['booking']?['id'] ?? 0,
      userId: json['user_id'] ?? json['user']?['id'] ?? 0,
      venueId: json['venue_id'] ?? json['venue']?['id'] ?? 0,
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      reply: json['reply'],
      repliedAt: json['replied_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['replied_at'])
          : null,
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : DateTime.now(),
      user: json['user'] != null ? User.fromJson(json['user']) : null,
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
      venue: json['venue'] != null ? Venue.fromJson(json['venue']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_id': bookingId,
    'user_id': userId,
    'venue_id': venueId,
    'rating': rating,
    'comment': comment,
  };

  bool get hasReply => reply != null && reply!.isNotEmpty;

  String get ratingText {
    if (rating >= 5) return 'Sangat Baik';
    if (rating >= 4) return 'Baik';
    if (rating >= 3) return 'Cukup';
    if (rating >= 2) return 'Kurang';
    return 'Sangat Kurang';
  }
}

class CanReviewResult {
  final bool canReview;
  final String? reason;
  final Booking? booking;

  CanReviewResult({
    required this.canReview,
    this.reason,
    this.booking,
  });

  factory CanReviewResult.fromJson(Map<String, dynamic> json) {
    return CanReviewResult(
      canReview: json['can_review'] ?? false,
      reason: json['reason'],
      booking: json['booking'] != null ? Booking.fromJson(json['booking']) : null,
    );
  }
}
