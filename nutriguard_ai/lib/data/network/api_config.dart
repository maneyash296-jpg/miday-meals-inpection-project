import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const _baseUrlKey = 'api_base_url';
  static const _localDefaultUrl = 'http://10.156.48.124:8000/api/v1';
  static String? _customBaseUrl;

  /// Load the backend chosen by the user before the app is shown.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_baseUrlKey);
    if (savedUrl != null && savedUrl.trim().isNotEmpty) {
      _customBaseUrl = _normaliseUrl(savedUrl);
    }
  }

  static String _normaliseUrl(String url) {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api/v1')) {
      cleanUrl = '$cleanUrl/api/v1';
    }
    return cleanUrl;
  }

  /// Saves a public (HTTPS) or local development backend for future launches.
  static Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = _normaliseUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_baseUrlKey, _customBaseUrl!);
  }

  static Future<void> clearCustomBaseUrl() async {
    _customBaseUrl = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_baseUrlKey);
  }

  /// Base URL configured dynamically via build environment, user setting, or platform detection
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    } else if (Platform.isAndroid) {
      // Development fallback. For a shareable APK, set a public HTTPS URL
      // through the Backend Settings link on the sign-in screen.
      return _localDefaultUrl;
    }
    return 'http://localhost:8000/api/v1';
  }

  static bool get hasCustomBaseUrl =>
      _customBaseUrl != null && _customBaseUrl!.isNotEmpty;

  // Auth
  static String get login => '$baseUrl/auth/login';
  static String get register => '$baseUrl/auth/register';
  static String get me => '$baseUrl/auth/me';

  // Schools
  static String get schools => '$baseUrl/schools';

  // Meals
  static String get meals => '$baseUrl/meals';

  // Search
  static String get search => '$baseUrl/search/query';
  static String get aiSearch => '$baseUrl/search/ai';

  // AI & ML Endpoints
  static String get aiPredictWaste => '$baseUrl/ai/predict-waste';
  static String get aiModelMetrics => '$baseUrl/ai/model-metrics';
  static String get aiTrainModel => '$baseUrl/ai/train-model';

  // Ration Shops
  static String get rationShops => '$baseUrl/ration-shops';
  static String get rationShopDashboard => '$baseUrl/ration-shops/dashboard';
  static String get rationShopSearchInventory => '$baseUrl/ration-shops/search/inventory';
  static String get rationShopSearchSchools => '$baseUrl/ration-shops/search/schools';

  // Districts
  static String get districts => '$baseUrl/districts';
  static String get districtDashboard => '$baseUrl/districts/dashboard';

  // Alerts
  static String get alerts => '$baseUrl/alerts';

  // Dynamic paths
  static String teacherDashboard(String schoolId) => '$schools/$schoolId/dashboard/teacher';
  static String analyzeMeal(String mealId) => '$meals/$mealId/analyze';
  static String shopInventory(String shopId) => '$rationShops/$shopId/inventory';
  static String shopAllocations(String shopId) => '$rationShops/$shopId/allocations';
  static String shopDeliveries(String shopId) => '$rationShops/$shopId/deliveries';
  static String shopReceive(String shopId) => '$rationShops/$shopId/inventory/receive';
  static String districtSchools(String districtId) => '$districts/$districtId/schools';
}
