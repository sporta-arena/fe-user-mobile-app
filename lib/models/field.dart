import 'venue.dart';

class Field {
  final int id;
  final int venueId;
  final String name;
  final String type; // futsal, badminton, basketball, volleyball, tennis, mini_soccer, padel
  final String? description;
  final double pricePerHour;
  final String status; // active, maintenance, inactive
  final DateTime createdAt;
  final DateTime updatedAt;
  final Venue? venue;

  Field({
    required this.id,
    required this.venueId,
    required this.name,
    required this.type,
    this.description,
    required this.pricePerHour,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.venue,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    return Field(
      id: json['id'],
      venueId: json['venue_id'],
      name: json['name'],
      type: json['type'],
      description: json['description'],
      pricePerHour: double.parse(json['price_per_hour'].toString()),
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      venue: json['venue'] != null ? Venue.fromJson(json['venue']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'venue_id': venueId,
    'name': name,
    'type': type,
    'description': description,
    'price_per_hour': pricePerHour,
    'status': status,
  };

  bool get isActive => status == 'active';
  bool get isMaintenance => status == 'maintenance';
  bool get isInactive => status == 'inactive';

  String get formattedPrice => 'Rp ${_formatNumber(pricePerHour.toInt())}/jam';

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  String get typeLabel {
    switch (type) {
      case 'futsal':
        return 'Futsal';
      case 'badminton':
        return 'Badminton';
      case 'basketball':
        return 'Basketball';
      case 'volleyball':
        return 'Volleyball';
      case 'tennis':
        return 'Tennis';
      case 'mini_soccer':
        return 'Mini Soccer';
      case 'padel':
        return 'Padel';
      default:
        return type;
    }
  }
}

class TimeSlot {
  final String startTime;
  final String endTime;
  final bool available;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.available,
  });

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    return TimeSlot(
      startTime: json['start_time'],
      endTime: json['end_time'],
      available: json['available'],
    );
  }
}
