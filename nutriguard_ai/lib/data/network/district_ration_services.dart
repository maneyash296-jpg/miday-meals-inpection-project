import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class RationShopService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.rationShopDashboard),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print('Dashboard error ${response.statusCode}: ${response.body}');
      return null;
    } catch (e) {
      print('Error fetching ration shop dashboard: $e');
      return null;
    }
  }

  Future<List<dynamic>> getInventory(String shopId, {String? q}) async {
    try {
      final headers = await _authService.getAuthHeaders();
      var url = ApiConfig.shopInventory(shopId);
      if (q != null && q.isNotEmpty) {
        url += '?q=${Uri.encodeComponent(q)}';
      }
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching inventory: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAllocations(String shopId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.shopAllocations(shopId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching allocations: $e');
      return [];
    }
  }

  Future<List<dynamic>> getDeliveries(String shopId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.shopDeliveries(shopId)),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching deliveries: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> dispatchDelivery({
    required String shopId,
    required String schoolId,
    required String vehicleNumber,
    required String driverName,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final body = jsonEncode({
        'school_id': schoolId,
        'vehicle_number': vehicleNumber,
        'driver_name': driverName,
        'items': items,
      });
      final response = await http.post(
        Uri.parse(ApiConfig.shopDeliveries(shopId)),
        headers: headers,
        body: body,
      );
      if (response.statusCode == 201) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print('Dispatch error: ${response.statusCode} ${response.body}');
      return null;
    } catch (e) {
      print('Error dispatching delivery: $e');
      return null;
    }
  }

  Future<List<dynamic>> searchInventory(String q) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final url =
          '${ApiConfig.rationShopSearchInventory}?q=${Uri.encodeComponent(q)}';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error searching inventory: $e');
      return [];
    }
  }

  Future<List<dynamic>> searchSchools(String q) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final url =
          '${ApiConfig.rationShopSearchSchools}?q=${Uri.encodeComponent(q)}';
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error searching schools: $e');
      return [];
    }
  }

  Future<List<dynamic>> getAllSchools() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.schools),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching schools: $e');
      return [];
    }
  }
}

class DistrictService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> getDashboard() async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.districtDashboard),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      print('District dashboard error: ${response.statusCode}');
      return null;
    } catch (e) {
      print('Error fetching district dashboard: $e');
      return null;
    }
  }
}
