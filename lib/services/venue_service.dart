import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/venue.dart';
import '../models/field.dart';
import 'auth_service.dart';

class VenueResult {
  final bool success;
  final String? message;
  final Venue? venue;
  final List<Venue>? venues;
  final Map<String, dynamic>? pagination;
  final Map<String, List<String>>? errors;

  VenueResult({
    required this.success,
    this.message,
    this.venue,
    this.venues,
    this.pagination,
    this.errors,
  });
}

class FieldResult {
  final bool success;
  final String? message;
  final Field? field;
  final List<Field>? fields;
  final List<TimeSlot>? slots;
  final Map<String, List<String>>? errors;

  FieldResult({
    required this.success,
    this.message,
    this.field,
    this.fields,
    this.slots,
    this.errors,
  });
}

class VenueService {
  /// Get all active venues (public)
  static Future<VenueResult> getVenues({
    String? city,
    String? search,
    int page = 1,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (city != null) queryParams['city'] = city;
      if (search != null) queryParams['search'] = search;
      queryParams['page'] = page.toString();

      final uri = Uri.parse(ApiConfig.venuesUrl).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: ApiConfig.defaultHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final venues = (data['data'] as List)
            .map((v) => Venue.fromJson(v))
            .toList();

        return VenueResult(
          success: true,
          venues: venues,
          pagination: {
            'current_page': data['meta']?['current_page'],
            'last_page': data['meta']?['last_page'],
            'total': data['meta']?['total'],
          },
        );
      } else {
        return VenueResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return VenueResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get venue detail (public)
  static Future<VenueResult> getVenueDetail(int id) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.venueDetailUrl(id)),
        headers: ApiConfig.defaultHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return VenueResult(
          success: true,
          venue: Venue.fromJson(data['venue']),
        );
      } else {
        return VenueResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return VenueResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get venue fields (public)
  static Future<FieldResult> getVenueFields(int venueId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.venueFieldsUrl(venueId)),
        headers: ApiConfig.defaultHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final fields = (data['fields'] as List)
            .map((f) => Field.fromJson(f))
            .toList();

        return FieldResult(
          success: true,
          fields: fields,
        );
      } else {
        return FieldResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return FieldResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get field detail (public)
  static Future<FieldResult> getFieldDetail(int venueId, int fieldId) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.fieldDetailUrl(venueId, fieldId)),
        headers: ApiConfig.defaultHeaders,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return FieldResult(
          success: true,
          field: Field.fromJson(data['field']),
        );
      } else {
        return FieldResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return FieldResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get available slots for a field (requires auth)
  static Future<FieldResult> getAvailableSlots(int fieldId, String date) async {
    if (AuthService.token == null) {
      return FieldResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final uri = Uri.parse(ApiConfig.availableSlotsUrl(fieldId))
          .replace(queryParameters: {'date': date});

      final response = await http.get(
        uri,
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final slots = (data['slots'] as List)
            .map((s) => TimeSlot.fromJson(s))
            .toList();

        return FieldResult(
          success: true,
          field: data['field'] != null ? Field.fromJson(data['field']) : null,
          slots: slots,
        );
      } else {
        return FieldResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return FieldResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  // ========== Partner Endpoints ==========

  /// Get my venues (partner)
  static Future<VenueResult> getMyVenues() async {
    if (AuthService.token == null) {
      return VenueResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.myVenuesUrl),
        headers: ApiConfig.authHeaders(AuthService.token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final venues = (data['data'] as List)
            .map((v) => Venue.fromJson(v))
            .toList();

        return VenueResult(
          success: true,
          venues: venues,
        );
      } else {
        return VenueResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return VenueResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Create venue (partner)
  static Future<VenueResult> createVenue({
    required String name,
    required String phone,
    required String address,
    required String city,
    String? description,
    List<String>? facilities,
    required String openHour,
    required String closeHour,
    double? latitude,
    double? longitude,
    File? coverImage,
  }) async {
    if (AuthService.token == null) {
      return VenueResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.venuesUrl));
      request.headers.addAll(ApiConfig.multipartHeaders(AuthService.token!));

      request.fields['name'] = name;
      request.fields['phone'] = phone;
      request.fields['address'] = address;
      request.fields['city'] = city;
      if (description != null) request.fields['description'] = description;
      request.fields['open_hour'] = openHour;
      request.fields['close_hour'] = closeHour;
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();

      if (facilities != null) {
        for (var i = 0; i < facilities.length; i++) {
          request.fields['facilities[$i]'] = facilities[i];
        }
      }

      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('cover_image', coverImage.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return VenueResult(
          success: true,
          message: data['message'],
          venue: Venue.fromJson(data['venue']),
        );
      } else {
        return VenueResult(
          success: false,
          message: data['message'],
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map((key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return VenueResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Create field for venue (partner)
  static Future<FieldResult> createField({
    required int venueId,
    required String name,
    required String type,
    String? description,
    required double pricePerHour,
  }) async {
    if (AuthService.token == null) {
      return FieldResult(success: false, message: 'Silakan login terlebih dahulu');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.venueFieldsUrl(venueId)),
        headers: ApiConfig.authHeaders(AuthService.token!),
        body: jsonEncode({
          'name': name,
          'type': type,
          'description': description,
          'price_per_hour': pricePerHour,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return FieldResult(
          success: true,
          message: data['message'],
          field: Field.fromJson(data['field']),
        );
      } else {
        return FieldResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return FieldResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }
}
