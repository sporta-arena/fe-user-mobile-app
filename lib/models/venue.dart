import 'user.dart';
import '../utils/waktu_wib.dart';
import '../config/api_config.dart';
import 'field.dart';
import '../utils/timezone_utils.dart';

class Venue {
  final int id;
  final int partnerId;
  final String name;
  final String? phone;
  final String address;
  final String city;
  final String? description;
  final List<String> facilities;
  final String openHour;
  final String closeHour;
  final double? latitude;
  final double? longitude;
  final String? coverImage;
  final String? coverImageUrl;
  final String status; // pending, active, suspended
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? partner;
  final List<Field>? fields;
  final double? averageRating;
  final int? reviewCount;

  Venue({
    required this.id,
    required this.partnerId,
    required this.name,
    this.phone,
    required this.address,
    required this.city,
    this.description,
    this.facilities = const [],
    required this.openHour,
    required this.closeHour,
    this.latitude,
    this.longitude,
    this.coverImage,
    this.coverImageUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.partner,
    this.fields,
    this.averageRating,
    this.reviewCount,
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'] ?? 0,
      partnerId: json['partner_id'] ?? json['partner']?['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'],
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      description: json['description'],
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : [],
      openHour: json['open_hour'] ?? '08:00',
      closeHour: json['close_hour'] ?? '22:00',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      coverImage: json['cover_image'],
      coverImageUrl: ApiConfig.perbaikiUrlMedia(json['cover_image_url']),
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : DateTime.now(),
      partner: json['partner'] != null ? User.fromJson(json['partner']) : null,
      fields: json['fields'] != null
          ? (json['fields'] as List).map((f) => Field.fromJson(f)).toList()
          : null,
      averageRating: json['average_rating'] != null
          ? double.tryParse(json['average_rating'].toString())
          : null,
      reviewCount: json['review_count'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'partner_id': partnerId,
    'name': name,
    'phone': phone,
    'address': address,
    'city': city,
    'description': description,
    'facilities': facilities,
    'open_hour': openHour,
    'close_hour': closeHour,
    'latitude': latitude,
    'longitude': longitude,
    'status': status,
  };

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isSuspended => status == 'suspended';

  /// Jam operasional dari API adalah UTC; ditampilkan sebagai WIB,
  /// sama seperti fe-web.
  String get formattedOpenHours => WaktuWib.rentang(openHour, closeHour);


  String get facilitiesText => facilities.join(', ');
}
