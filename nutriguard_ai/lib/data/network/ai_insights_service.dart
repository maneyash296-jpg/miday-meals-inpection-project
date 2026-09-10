import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class AiInsightsService {
  final AuthService _authService = AuthService();

  /// Generate a human-readable explanation for a stored prediction.
  Future<String?> explainPrediction(String predictionId) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ai/prediction/$predictionId/explain'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['explanation'] as String?;
      }
      return null;
    } catch (e) {
      print('Error explaining prediction: $e');
      return null;
    }
  }

  /// Ask Groq LLM to summarise a dashboard payload in plain language.
  Future<String?> summarizeDashboard(Map<String, dynamic> dashboardData) async {
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ai/dashboard/summarize'),
        headers: headers,
        body: jsonEncode(dashboardData),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['summary'] as String?;
      }
      return null;
    } catch (e) {
      print('Error summarizing dashboard: $e');
      return null;
    }
  }
}
