import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/school.dart';
import 'api_config.dart';
import 'auth_service.dart';

class SchoolService {
  final AuthService _authService = AuthService();

  Future<TeacherDashboard?> getTeacherDashboard() async {
    try {
      final schoolId = await _authService.getSchoolId();
      if (schoolId == null) return null;

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.teacherDashboard(schoolId)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return TeacherDashboard.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching teacher dashboard: $e');
      return null;
    }
  }

  Future<List<dynamic>> getInventory() async {
    try {
      final schoolId = await _authService.getSchoolId();
      if (schoolId == null) return [];

      final headers = await _authService.getAuthHeaders();
      final response = await http.get(
        Uri.parse('${ApiConfig.schools}/$schoolId/inventory'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      }
      return [];
    } catch (e) {
      print('Error fetching school inventory: $e');
      return [];
    }
  }
}
