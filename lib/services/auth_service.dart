import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user.dart';

class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? token;
  final Map<String, List<String>>? errors;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.token,
    this.errors,
  });
}

class AuthService {
  static String? _token;
  static User? _currentUser;

  static String? get token => _token;
  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null && _currentUser != null;

  /// Login dengan email dan password
  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.loginUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        return AuthResult(
          success: true,
          message: data['message'],
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'],
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map((key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Register user baru
  static Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    File? avatar,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.registerUrl));

      // Add headers
      request.headers.addAll(ApiConfig.defaultHeaders);
      request.headers.remove('Content-Type'); // Let it set automatically for multipart

      // Add fields
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['password'] = password;
      request.fields['password_confirmation'] = passwordConfirmation;

      // Add avatar if provided
      if (avatar != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user']);

        return AuthResult(
          success: true,
          message: data['message'],
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'],
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(
                  data['errors'].map((key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Get current user data
  static Future<AuthResult> getUser() async {
    if (_token == null) {
      return AuthResult(success: false, message: 'Tidak ada token');
    }

    try {
      final response = await http.get(
        Uri.parse(ApiConfig.userUrl),
        headers: ApiConfig.authHeaders(_token!),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(data['user']);
        return AuthResult(
          success: true,
          user: _currentUser,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Update profile
  static Future<AuthResult> updateProfile({
    String? name,
    String? phone,
    File? avatar,
  }) async {
    if (_token == null) {
      return AuthResult(success: false, message: 'Tidak ada token');
    }

    try {
      var request = http.MultipartRequest('POST', Uri.parse(ApiConfig.userUrl));

      request.headers.addAll(ApiConfig.multipartHeaders(_token!));
      request.fields['_method'] = 'PUT';

      if (name != null) request.fields['name'] = name;
      if (phone != null) request.fields['phone'] = phone;

      if (avatar != null) {
        request.files.add(await http.MultipartFile.fromPath('avatar', avatar.path));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _currentUser = User.fromJson(data['user']);
        return AuthResult(
          success: true,
          message: data['message'],
          user: _currentUser,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Logout
  static Future<AuthResult> logout() async {
    if (_token == null) {
      return AuthResult(success: false, message: 'Tidak ada token');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logoutUrl),
        headers: ApiConfig.authHeaders(_token!),
      );

      final data = jsonDecode(response.body);

      // Clear local data regardless of response
      _token = null;
      _currentUser = null;

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'],
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      // Still clear local data
      _token = null;
      _currentUser = null;

      return AuthResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Logout from all devices
  static Future<AuthResult> logoutAll() async {
    if (_token == null) {
      return AuthResult(success: false, message: 'Tidak ada token');
    }

    try {
      final response = await http.post(
        Uri.parse(ApiConfig.logoutAllUrl),
        headers: ApiConfig.authHeaders(_token!),
      );

      final data = jsonDecode(response.body);

      // Clear local data
      _token = null;
      _currentUser = null;

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'],
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'],
        );
      }
    } catch (e) {
      _token = null;
      _currentUser = null;

      return AuthResult(
        success: false,
        message: 'Gagal terhubung ke server: $e',
      );
    }
  }

  /// Set token manually (untuk restore session)
  static void setToken(String token) {
    _token = token;
  }

  /// Clear session
  static void clearSession() {
    _token = null;
    _currentUser = null;
  }
}
