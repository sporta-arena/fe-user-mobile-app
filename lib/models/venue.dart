import 'user.dart';
import 'field.dart';

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
  });

  factory Venue.fromJson(Map<String, dynamic> json) {
    return Venue(
      id: json['id'],
      partnerId: json['partner_id'],
      name: json['name'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      description: json['description'],
      facilities: json['facilities'] != null
          ? List<String>.from(json['facilities'])
          : [],
      openHour: json['open_hour'],
      closeHour: json['close_hour'],
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
      coverImage: json['cover_image'],
      coverImageUrl: json['cover_image_url'],
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      partner: json['partner'] != null ? User.fromJson(json['partner']) : null,
      fields: json['fields'] != null
          ? (json['fields'] as List).map((f) => Field.fromJson(f)).toList()
          : null,
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

  String get formattedOpenHours => '${_formatTime(openHour)} - ${_formatTime(closeHour)}';

  String _formatTime(String time) {
    final parts = time.split(':');
    if (parts.length >= 2) {
      return '${parts[0]}:${parts[1]}';
    }
    return time;
  }

  String get facilitiesText => facilities.join(', ');
}
