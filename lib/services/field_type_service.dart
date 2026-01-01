import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/field_type.dart';

class FieldTypeService {
  static List<FieldType>? _cachedTypes;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);

  /// Get all field types from API
  static Future<List<FieldType>> getFieldTypes({bool forceRefresh = false}) async {
    // Return cached data if available and not expired
    if (!forceRefresh && _cachedTypes != null && _cacheTime != null) {
      if (DateTime.now().difference(_cacheTime!) < _cacheDuration) {
        return _cachedTypes!;
      }
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.fieldTypesUrl),
        headers: ApiConfig.defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        List<FieldType> types = [];

        // Handle different response formats
        if (data is List) {
          types = data.map((t) => FieldType.fromJson(t)).toList();
        } else if (data is Map && data['data'] != null) {
          types = (data['data'] as List).map((t) => FieldType.fromJson(t)).toList();
        } else if (data is Map && data['field_types'] != null) {
          types = (data['field_types'] as List).map((t) => FieldType.fromJson(t)).toList();
        } else if (data is Map && data['types'] != null) {
          types = (data['types'] as List).map((t) => FieldType.fromJson(t)).toList();
        }

        if (types.isNotEmpty) {
          _cachedTypes = types;
          _cacheTime = DateTime.now();
          return types;
        }
      }

      debugPrint('Failed to fetch field types: ${response.statusCode}');
    } catch (e) {
      debugPrint('Error fetching field types: $e');
    }

    // Return cached data if available, otherwise defaults
    return _cachedTypes ?? FieldType.defaults;
  }

  /// Clear cache
  static void clearCache() {
    _cachedTypes = null;
    _cacheTime = null;
  }
}
