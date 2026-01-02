import 'package:flutter/material.dart';

class FieldType {
  final String value; // e.g., 'futsal', 'badminton'
  final String label; // e.g., 'Futsal', 'Badminton'
  final int venueCount;

  FieldType({
    required this.value,
    required this.label,
    this.venueCount = 0,
  });

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
        return Icons.sports_tennis;
      case 'billiard':
        return Icons.circle;
      case 'bowling':
        return Icons.sports_cricket;
      case 'golf':
        return Icons.golf_course;
      case 'table_tennis':
        return Icons.sports_tennis;
      default:
        return Icons.sports;
    }
  }

  // Get color based on field type value
  Color get color {
    switch (value.toLowerCase()) {
      case 'futsal':
        return Colors.green;
      case 'badminton':
        return Colors.blue;
      case 'basketball':
        return Colors.orange;
      case 'volleyball':
        return Colors.purple;
      case 'tennis':
        return Colors.lime;
      case 'mini_soccer':
        return Colors.teal;
      case 'swimming':
        return Colors.cyan;
      case 'gym':
        return Colors.red;
      case 'padel':
        return Colors.indigo;
      case 'billiard':
        return Colors.brown;
      case 'bowling':
        return Colors.deepOrange;
      case 'golf':
        return Colors.lightGreen;
      case 'table_tennis':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
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
