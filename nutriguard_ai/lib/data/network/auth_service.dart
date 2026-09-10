import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class AuthService {
  static const String _tokenKey = 'jwt_token';
  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _schoolIdKey = 'school_id';
  static const String _rationShopIdKey = 'ration_shop_id';
  static const String _districtIdKey = 'district_id';
  static const String _userNameKey = 'user_name';
  static const String _userEmailKey = 'user_email';
  String? lastError;

  Future<bool> login(String email, String password) async {
    lastError = null;
    try {
      final response = await http.post(
        Uri.parse(ApiConfig.login),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'username': email, // OAuth2 specifies username
          'password': password,
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token']);

        // Cache user info
        final user = data['user'];
        await prefs.setString(_userRoleKey, user['role'] ?? 'TEACHER');
        await prefs.setString(_userIdKey, user['id'] ?? '');
        await prefs.setString(_userNameKey, user['name'] ?? '');
        await prefs.setString(_userEmailKey, user['email'] ?? '');

        if (user['school_id'] != null) {
          await prefs.setString(_schoolIdKey, user['school_id']);
        }
        if (user['ration_shop_id'] != null) {
          await prefs.setString(_rationShopIdKey, user['ration_shop_id']);
        }
        if (user['district_id'] != null) {
          await prefs.setString(_districtIdKey, user['district_id']);
        }
        return true;
      }
      if (response.statusCode == 401) {
        lastError = 'Incorrect email or password.';
      } else if (response.statusCode >= 500) {
        lastError = 'The server is unavailable. Please try again shortly.';
      } else {
        lastError = 'Could not sign in (server returned ${response.statusCode}).';
      }
      return false;
    } on SocketException {
      lastError = 'Cannot reach the backend. Check Backend Settings and your internet connection.';
      return false;
    } on TimeoutException {
      lastError = 'The backend took too long to respond. Please try again.';
      return false;
    } on http.ClientException {
      lastError = 'Cannot reach the backend. Check Backend Settings and your internet connection.';
      return false;
    } catch (_) {
      lastError = 'Sign-in failed unexpectedly. Please try again.';
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_schoolIdKey);
    await prefs.remove(_rationShopIdKey);
    await prefs.remove(_districtIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userRoleKey);
  }

  Future<String?> getSchoolId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_schoolIdKey);
  }

  Future<String?> getRationShopId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_rationShopIdKey);
  }

  Future<String?> getDistrictId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_districtIdKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Returns the initial route based on the user's role
  Future<String> getInitialRoute() async {
    final isAuthenticated = await isLoggedIn();
    if (!isAuthenticated) return '/login';

    final role = await getRole();
    switch (role) {
      case 'TEACHER':
        return '/teacher';
      case 'PRINCIPAL':
        return '/principal';
      case 'RATION_SHOP':
        return '/ration-shop';
      case 'DISTRICT_OFFICER':
      case 'ADMIN':
        return '/district';
      default:
        return '/teacher';
    }
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    if (token == null) return {};
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }
}
