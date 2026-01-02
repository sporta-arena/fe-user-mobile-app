import 'package:flutter/foundation.dart';

class FavoriteVenue {
  final String id;
  final String name;
  final String address;
  final double rating;
  final int pricePerHour;
  final String category;

  FavoriteVenue({
    required this.id,
    required this.name,
    required this.address,
    required this.rating,
    required this.pricePerHour,
    required this.category,
  });
}

class FavoriteService extends ChangeNotifier {
  static final FavoriteService _instance = FavoriteService._internal();
  factory FavoriteService() => _instance;
  FavoriteService._internal();

  final List<FavoriteVenue> _favorites = [];

  List<FavoriteVenue> get favorites => List.unmodifiable(_favorites);

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
  }

  void addFavorite(FavoriteVenue venue) {
    if (!isFavorite(venue.id)) {
      _favorites.add(venue);
      notifyListeners();
    }
  }

  void removeFavorite(String venueId) {
    _favorites.removeWhere((venue) => venue.id == venueId);
    notifyListeners();
  }
}
