import 'user.dart';
import '../utils/waktu_wib.dart';
import '../config/api_config.dart';
import 'field.dart';
import '../utils/timezone_utils.dart';

/// Satu foto di galeri venue.
///
/// Server mengirimnya lewat `gallery_images`: foto sampul diikuti foto
/// tiap lapangan, sudah diurutkan dan dibatasi jumlahnya di sana.
class FotoVenue {
  final String url;
  final String keterangan;

  const FotoVenue({required this.url, required this.keterangan});

  /// Keterangan yang layak ditunjukkan ke pemesan.
  ///
  /// `Cover` itu label internal server untuk foto sampul — buat
  /// pemesan artinya tidak ada, dan nama venuenya sudah tertulis besar
  /// di atas foto itu juga. Yang bernilai cuma nama lapangan: di venue
  /// berisi empat lapangan, itu satu-satunya cara tahu foto mana milik
  /// lapangan mana.
  String get keteranganTampil => keterangan == 'Cover' ? '' : keterangan;
}

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

  /// Harga per jam termurah dan termahal di antara lapangan yang aktif.
  ///
  /// Dihitung server lewat withMin/withMax dan sudah ikut di SETIAP
  /// respons daftar venue sejak lama — yang kurang pembacanya, sama
  /// seperti `galeri` di atas. Akibatnya peta cuma bisa menancapkan
  /// jarum tanpa harga, dan layar kategori sampai menembak satu
  /// permintaan HTTP per venue hanya untuk mendapat angka yang
  /// sebenarnya sudah ada di tangan.
  ///
  /// Null kalau venuenya belum punya lapangan aktif sama sekali.
  /// Venue ini punya flash sale berjalan (hari ini sampai H+2).
  ///
  /// Dihitung server di kueri daftar, bukan per kartu: menghitungnya di
  /// klien berarti satu permintaan tambahan per venue, dan daftar venue
  /// adalah layar paling ramai di aplikasi.
  final bool adaFlashSale;

  final double? hargaMin;
  final double? hargaMaks;

  /// Jarak dari titik yang dikirim saat meminta daftar, dalam km.
  ///
  /// Hanya terisi kalau permintaannya menyertakan lat & lng; kalau
  /// tidak, server tidak menghitungnya sama sekali.
  final double? jarakKm;

  /// Isi `gallery_images` dari server.
  ///
  /// Dulu layar detail cuma memakai `coverImageUrl`, dengan catatan di
  /// kodenya bahwa foto lain "menyusul dari API". Padahal API-nya sudah
  /// mengirimkannya sejak lama; yang kurang pembacanya. Akibatnya venue
  /// dengan lima lapangan berfoto tetap tampil satu gambar.
  final List<FotoVenue> galeri;

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
    this.adaFlashSale = false,
    this.hargaMin,
    this.hargaMaks,
    this.jarakKm,
    this.galeri = const [],
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
      adaFlashSale: json['has_flash_sale'] == true,
      hargaMin: json['min_price'] != null
          ? double.tryParse(json['min_price'].toString())
          : null,
      hargaMaks: json['max_price'] != null
          ? double.tryParse(json['max_price'].toString())
          : null,
      jarakKm: json['distance_km'] != null
          ? double.tryParse(json['distance_km'].toString())
          : null,
      galeri: _bacaGaleri(json),
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

  /// Membaca `gallery_images`, dengan sampul sebagai cadangan.
  ///
  /// Baris tanpa url dilewati: satu slide kosong di tengah galeri lebih
  /// membingungkan daripada galeri yang lebih pendek.
  static List<FotoVenue> _bacaGaleri(Map<String, dynamic> json) {
    final mentah = json['gallery_images'];

    if (mentah is List) {
      final hasil = <FotoVenue>[];
      for (final baris in mentah) {
        if (baris is! Map) continue;
        final url = ApiConfig.perbaikiUrlMedia(baris['url']?.toString());
        if (url == null || url.isEmpty) continue;
        hasil.add(
          FotoVenue(url: url, keterangan: baris['caption']?.toString() ?? ''),
        );
      }
      return hasil;
    }

    final sampul = ApiConfig.perbaikiUrlMedia(json['cover_image_url']);
    if (sampul != null && sampul.isNotEmpty) {
      return [FotoVenue(url: sampul, keterangan: '')];
    }

    return const [];
  }
}
