import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class PrincipalService {
  final AuthService _authService = AuthService();

  Future<Map<String, dynamic>?> getPrincipalDashboard() async {
    try {
      final schoolId = await _authService.getSchoolId();
      if (schoolId == null) return null;
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.schools}/$schoolId/dashboard/principal'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching principal dashboard: $e');
      return null;
    }
  }

  Future<List<dynamic>> getRecommendations(String schoolId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/recommendations?school_id=$schoolId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching recommendations: $e');
      return [];
    }
  }
}
