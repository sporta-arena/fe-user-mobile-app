import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteVenue {
  final String id;
  final String name;
  final String address;

  /// Rating rata-rata venue, atau null kalau belum pernah diulas.
  final double? rating;
  final int pricePerHour;
  final String category;
  final String? imageUrl;

  FavoriteVenue({
    required this.id,
    required this.name,
    required this.address,
    this.rating,
    required this.pricePerHour,
    required this.category,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'rating': rating,
        'pricePerHour': pricePerHour,
        'category': category,
        'imageUrl': imageUrl,
      };

  factory FavoriteVenue.fromJson(Map<String, dynamic> json) => FavoriteVenue(
        id: json['id']?.toString() ?? '',
        name: json['name'] ?? '',
        address: json['address'] ?? '',
        rating: (json['rating'] as num?)?.toDouble(),
        pricePerHour: (json['pricePerHour'] as num?)?.toInt() ?? 0,
        category: json['category'] ?? '',
        imageUrl: json['imageUrl'],
      );
}

/// Venue yang ditandai hati oleh pemakai.
///
/// Sebelumnya daftar ini cuma hidup di memori: tidak ada layar yang
/// membacanya, tidak ada yang menyimpannya, dan backend pun belum punya
/// endpoint favorit. Jadi ikon hatinya menyala sebentar lalu isinya
/// hilang begitu aplikasi ditutup, alias tombol mati.
///
/// Sekarang daftarnya disimpan di perangkat lewat SharedPreferences dan
/// dibaca oleh halaman Venue Favorit. Sengaja lokal, bukan per akun:
/// menyimpannya di server butuh endpoint yang belum ada, dan menunda
/// hatinya sampai endpoint itu jadi berarti membiarkan tombol mati.
class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  static const String _kunci = 'venue_favorit';

  final List<FavoriteVenue> _favorites = [];
  bool _sudahDimuat = false;

  List<FavoriteVenue> get favorites => List.unmodifiable(_favorites);
  bool get sudahDimuat => _sudahDimuat;

  /// Dipanggil sekali sebelum frame pertama, dari `main()`.
  Future<void> muat() async {
    if (_sudahDimuat) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final mentah = prefs.getStringList(_kunci) ?? const [];
      _favorites
        ..clear()
        ..addAll(mentah.map(
          (baris) => FavoriteVenue.fromJson(
            jsonDecode(baris) as Map<String, dynamic>,
          ),
        ));
    } catch (_) {
      // Data lama yang formatnya tidak terbaca tidak boleh menahan
      // aplikasi terbuka; daftarnya cukup dimulai kosong.
      _favorites.clear();
    }
    _sudahDimuat = true;
    notifyListeners();
  }

  Future<void> _simpan() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
        _kunci,
        _favorites.map((v) => jsonEncode(v.toJson())).toList(),
      );
    } catch (_) {
      // Penyimpanan gagal berarti favoritnya hilang di sesi berikutnya,
      // bukan alasan untuk menggagalkan ketukan yang sedang berjalan.
    }
  }

  bool isFavorite(String venueId) {
    return _favorites.any((venue) => venue.id == venueId);
  }

  void toggleFavorite(FavoriteVenue venue) {
    final index = _favorites.indexWhere((v) => v.id == venue.id);
    if (index >= 0) {
      _favorites.removeAt(index);
    } else {
      _favorites.add(venue);
    }
    notifyListeners();
    _simpan();
  }

  void addFavorite(FavoriteVenue venue) {
    if (!isFavorite(venue.id)) {
      _favorites.add(venue);
      notifyListeners();
      _simpan();
    }
  }

  void removeFavorite(String venueId) {
    _favorites.removeWhere((venue) => venue.id == venueId);
    notifyListeners();
    _simpan();
  }
}
