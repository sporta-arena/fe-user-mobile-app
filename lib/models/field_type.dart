import 'package:flutter/material.dart';

class FieldType {
  final String value; // e.g., 'futsal', 'badminton'
  final String label; // e.g., 'Futsal', 'Badminton'
  final int venueCount;

  FieldType({required this.value, required this.label, this.venueCount = 0});

  factory FieldType.fromJson(Map<String, dynamic> json) {
    return FieldType(
      value: json['value'] ?? json['type'] ?? '',
      label: json['label'] ?? json['name'] ?? '',
      venueCount: json['venue_count'] ?? json['count'] ?? 0,
    );
  }

  // Get icon based on field type value
  IconData get icon {
    switch (value.toLowerCase()) {
      case 'futsal':
        return Icons.sports_soccer;
      case 'badminton':
        return Icons.sports_tennis;
      case 'basketball':
        return Icons.sports_basketball;
      case 'volleyball':
        return Icons.sports_volleyball;
      case 'tennis':
        return Icons.sports_tennis;
      case 'mini_soccer':
        return Icons.sports_soccer;
      case 'swimming':
        return Icons.pool;
      case 'gym':
        return Icons.fitness_center;
      case 'padel':
      case 'squash':
      case 'table_tennis':
        return Icons.sports_tennis;
      case 'football':
        return Icons.sports_soccer;
      case 'sepak_takraw':
        return Icons.sports_volleyball;
      case 'billiard':
        return Icons.sports_bar_outlined;
      case 'bowling':
        return Icons.sports_score;
      case 'golf':
        return Icons.golf_course;
      case 'archery':
        return Icons.my_location;
      case 'climbing':
        return Icons.terrain;
      case 'martial_arts':
        return Icons.sports_martial_arts;
      case 'yoga':
        return Icons.self_improvement;
      case 'dance':
        return Icons.music_note;
      case 'athletics':
        return Icons.directions_run;
      case 'skateboard':
        return Icons.skateboarding;
      case 'ice_skating':
        return Icons.ice_skating;
      default:
        // Cabang yang belum punya ikonnya sendiri tetap tampil, bukan
        // hilang: daftarnya datang dari server, jadi backend bisa
        // menambah cabang tanpa aplikasi ini dirilis ulang.
        return Icons.sports;
    }
  }

  /// Indeks warna kategori, bukan warnanya langsung.
  ///
  /// Dulu getter ini mengembalikan `Colors.green`, `Colors.purple`,
  /// `Colors.brown` dan sepuluh lainnya: empat belas warna bawaan
  /// Material yang tidak satu pun berasal dari palet Sportago, dan yang
  /// tetap sama di tema gelap sehingga kontrasnya jebol. Sekarang yang
  /// dikembalikan cuma nomor slot, dan pemanggilnya menerjemahkannya
  /// lewat `context.c.kategori(...)` yang sudah sadar tema.
  int get indeksWarna {
    const urutan = [
      'futsal',
      'badminton',
      'basketball',
      'volleyball',
      'tennis',
      'mini_soccer',
      'swimming',
      'gym',
      'padel',
      'billiard',
      'bowling',
      'golf',
      'table_tennis',
    ];
    final i = urutan.indexOf(value.toLowerCase());
    // Jenis yang belum dikenal tetap dapat slot yang tetap, diturunkan
    // dari namanya, supaya warnanya tidak berubah-ubah tiap render.
    return i >= 0 ? i : value.hashCode.abs();
  }

  // Fallback field types if API fails
  static List<FieldType> get defaults => [
    FieldType(value: 'futsal', label: 'Futsal'),
    FieldType(value: 'badminton', label: 'Badminton'),
    FieldType(value: 'basketball', label: 'Basket'),
    FieldType(value: 'volleyball', label: 'Voli'),
    FieldType(value: 'tennis', label: 'Tenis'),
    FieldType(value: 'mini_soccer', label: 'Mini Soccer'),
    FieldType(value: 'swimming', label: 'Renang'),
    FieldType(value: 'gym', label: 'Gym'),
    FieldType(value: 'padel', label: 'Padel'),
  ];
}
