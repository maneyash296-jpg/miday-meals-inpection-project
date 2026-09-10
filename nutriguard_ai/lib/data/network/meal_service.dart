import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/meal.dart';
import 'api_config.dart';
import 'auth_service.dart';

class MealService {
  final AuthService _authService = AuthService();

  Future<MealResponse?> recordMealSession({
    required int studentsPresent,
    required int studentsServed,
  }) async {
    try {
      final schoolId = await _authService.getSchoolId();
      if (schoolId == null) return null;

      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.meals),
        headers: headers,
        body: jsonEncode({
          'school_id': schoolId,
          'meal_date': DateTime.now().toIso8601String().split('T')[0],
          'meal_session': 'LUNCH',
          'students_present': studentsPresent,
          'students_served': studentsServed,
        }),
      );

      if (response.statusCode == 201) {
        return MealResponse.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      print('Error recording meal session: $e');
      return null;
    }
  }

  Future<MealAnalysisResult?> analyzeMealImage(String mealId, String imagePath) async {
    try {
      final headers = await _authService.getAuthHeaders();
      // Remove content-type from headers for multipart request
      headers.remove('Content-Type');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(ApiConfig.analyzeMeal(mealId)),
      );
      request.headers.addAll(headers);

      final isPng = imagePath.toLowerCase().endsWith('.png');
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imagePath,
          contentType: MediaType('image', isPng ? 'png' : 'jpeg'),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return MealAnalysisResult.fromJson(jsonDecode(response.body));
      }
      print('Failed to analyze meal: ${response.statusCode} - ${response.body}');
      return null;
    } catch (e) {
      print('Error analyzing meal image: $e');
      return null;
    }
  }
}
