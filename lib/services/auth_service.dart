import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user.dart';

class AuthResult {
  final bool success;
  final String? message;
  final User? user;
  final String? token;
  final Map<String, List<String>>? errors;
  final Map<String, dynamic>? data;

  AuthResult({
    required this.success,
    this.message,
    this.user,
    this.token,
    this.errors,
    this.data,
  });
}

class AuthService {
  static String? _token;
  static User? _currentUser;

  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _onboardingKey = 'has_seen_onboarding';

  // DEMO/OFFLINE BYPASS — hardcoded local account, dipakai saat server mati.
  // Hapus block ini begitu server stabil.
  static const String _demoEmail = 'demo';
  static const String _demoPassword = 'password';
  static const String _demoToken = 'demo_offline_token';
  static Map<String, dynamic> _demoUserJson() => {
        'id': 999999,
        'name': 'Demo User',
        'email': 'demo@sporta.local',
        'phone': '08000000000',
        'avatar': null,
        'avatar_url': null,
        'roles': [
          {'id': 1, 'name': 'user', 'guard_name': 'web'}
        ],
        'permissions': [],
      };
  static bool _isDemoSession() => _token == _demoToken;

  static String? get token => _token;
  static User? get currentUser => _currentUser;
  static bool get isLoggedIn => _token != null && _currentUser != null;

  /// Initialize auth state from storage
  static Future<bool> initializeAuth() async {
    final prefs = await SharedPreferences.getInstance();

    _token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson));
      } catch (e) {
        // Invalid user data, clear it
        await prefs.remove(_userKey);
        _currentUser = null;
      }
    }

    // If we have a token, verify it's still valid
    if (_token != null) {
      // Demo offline session — skip server verification
      if (_isDemoSession()) {
        return true;
      }
      final result = await getUser();
      if (!result.success) {
        // Token expired or invalid, clear session
        await clearSession();
        return false;
      }
      return true;
    }

    return false;
  }

  /// Check if user has seen onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingKey) ?? false;
  }

  /// Mark onboarding as seen
  static Future<void> setOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingKey, true);
  }

  /// Save auth data to storage
  static Future<void> _saveAuthData() async {
    final prefs = await SharedPreferences.getInstance();

    if (_token != null) {
      await prefs.setString(_tokenKey, _token!);
    }

    if (_currentUser != null) {
      await prefs.setString(_userKey, jsonEncode(_currentUser!.toJson()));
    }
  }

  /// Login dengan email dan password
  /// Sign in with Google. Uses native Google Sign-In to obtain an ID token,
  /// then exchanges it at POST /auth/google for a Sanctum token (mirrors the
  /// web flow). serverClientId makes the token's `aud` match the backend's
  /// GOOGLE_CLIENT_ID.
  static Future<AuthResult> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: ApiConfig.googleServerClientId,
      );

      // Sign out first so the account picker shows every time.
      await googleSignIn.signOut();

      final account = await googleSignIn.signIn();
      if (account == null) {
        return AuthResult(success: false, message: 'Login Google dibatalkan');
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      if (idToken == null) {
        return AuthResult(
            success: false, message: 'Gagal mendapatkan token dari Google');
      }

      final response = await http.post(
        Uri.parse(ApiConfig.googleLoginUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({'credential': idToken}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _token = data['token'];
        _currentUser = User.fromJson(data['user'] ?? data['data']);
        await _saveAuthData();
        return AuthResult(
          success: true,
          message: data['message'],
          user: _currentUser,
          token: _token,
        );
      } else {
        return AuthResult(
          success: false,
          message: data['message'] ?? 'Login Google gagal',
          errors: data['errors'] != null
              ? Map<String, List<String>>.from(data['errors'].map(
                  (key, value) => MapEntry(key, List<String>.from(value))))
              : null,
        );
      }
    } catch (e) {
      return AuthResult(success: false, message: 'Login Google gagal: $e');
    }
  }

  static Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    // DEMO/OFFLINE BYPASS — login lokal tanpa server
    if (email.trim().toLowerCase() == _demoEmail && password == _demoPassword) {
      _token = _demoToken;
      _currentUser = User.fromJson(_demoUserJson());
      await _saveAuthData();
      return AuthResult(
        success: true,
        message: 'Login demo berhasil (offline mode)',
        user: _currentUser,
        token: _token,
      );
    }

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
        // API may return 'user' or 'data'
        final userData = data['user'] ?? data['data'];
        _currentUser = User.fromJson(userData);

        // Save to persistent storage
        await _saveAuthData();

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

  /// Register user baru - Returns verification info, NOT auto-login
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
        // Registration successful - needs OTP verification
        // DO NOT save token or auto-login
        return AuthResult(
          success: true,
          message: data['message'],
          data: {
            'email': email,
            'verification': data['verification'],
          },
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

  /// Verify OTP code after registration
  static Future<AuthResult> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyOtpUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // OTP verified - now we have the token
        _token = data['token'];
        // API may return 'user' or 'data'
        final userData = data['user'] ?? data['data'];
        _currentUser = User.fromJson(userData);

        // Save to persistent storage
        await _saveAuthData();

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

  /// Resend OTP code
  static Future<AuthResult> resendOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resendOtpUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'],
          data: {
            'verification': data['verification'],
          },
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

  /// Request password reset - sends OTP to email
  static Future<AuthResult> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.forgotPasswordUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'],
          data: {
            'email': email,
            'reset': data['reset'],
          },
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

  /// Verify password reset OTP - returns reset token
  static Future<AuthResult> verifyResetOtp({
    required String email,
    required String code,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.verifyResetOtpUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'code': code,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'],
          data: {
            'reset_token': data['reset_token'],
          },
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

  /// Reset password with reset token
  static Future<AuthResult> resetPassword({
    required String email,
    required String resetToken,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.resetPasswordUrl),
        headers: ApiConfig.defaultHeaders,
        body: jsonEncode({
          'email': email,
          'reset_token': resetToken,
          'password': password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return AuthResult(
          success: true,
          message: data['message'],
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
        // API may return 'user' or 'data'
        final userData = data['user'] ?? data['data'];
        _currentUser = User.fromJson(userData);

        // Update stored user data
        await _saveAuthData();

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
        // API may return 'user' or 'data'
        final userData = data['user'] ?? data['data'];
        _currentUser = User.fromJson(userData);

        // Update stored user data
        await _saveAuthData();

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
      await clearSession();

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
      await clearSession();

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
      await clearSession();

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
      await clearSession();

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

  /// Clear session from memory and storage
  static Future<void> clearSession() async {
    _token = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
