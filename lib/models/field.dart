import 'venue.dart';
import '../utils/timezone_utils.dart';

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
      id: json['id'] ?? 0,
      venueId: json['venue_id'] ?? json['venue']?['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      description: json['description'],
      pricePerHour: json['price_per_hour'] != null
          ? double.parse(json['price_per_hour'].toString())
          : 0,
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? TimezoneUtils.parseUtcToLocal(json['updated_at'])
          : DateTime.now(),
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

  /// Harga yang berlaku untuk slot ini — sudah termasuk potongan flash
  /// sale kalau ada. Ini juga harga yang akan ditagih; server memakai
  /// resolusi harga yang sama saat booking dibuat, jadi angka di layar
  /// dan angka di tagihan tidak bisa berbeda.
  final double pricePerHour;

  /// Harga sebelum diskon, untuk dicoret. Sama dengan [pricePerHour]
  /// kalau slot ini bukan flash sale.
  final double originalPricePerHour;

  final bool isFlashSale;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.available,
    this.pricePerHour = 0,
    this.originalPricePerHour = 0,
    this.isFlashSale = false,
  });

  /// Besar potongan dalam persen, dibulatkan. Nol kalau bukan flash sale
  /// atau harga pembandingnya tidak masuk akal.
  int get diskonPersen {
    if (!isFlashSale) return 0;
    if (originalPricePerHour <= 0) return 0;
    if (pricePerHour >= originalPricePerHour) return 0;

    return (((originalPricePerHour - pricePerHour) / originalPricePerHour) *
            100)
        .round();
  }

  factory TimeSlot.fromJson(Map<String, dynamic> json) {
    double angka(String k) => (json[k] as num?)?.toDouble() ?? 0;

    return TimeSlot(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      available: json['available'] ?? false,
      pricePerHour: angka('price_per_hour'),
      originalPricePerHour: angka('original_price_per_hour'),
      isFlashSale: json['is_flash_sale'] == true,
    );
  }
}
