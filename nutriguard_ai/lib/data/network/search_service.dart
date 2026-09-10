import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';
import 'auth_service.dart';

class SearchResult {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final double score;
  final Map<String, dynamic> details;
  final String? badge;

  SearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.score,
    required this.details,
    this.badge,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) {
    return SearchResult(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      category: json['category'] as String? ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      details: json['details'] as Map<String, dynamic>? ?? {},
      badge: json['badge'] as String?,
    );
  }
}

class AiSearchResponse {
  final String query;
  final String aiSynthesis;
  final List<String> keyFindings;
  final List<String> suggestedActions;
  final List<SearchResult> matchedItems;

  AiSearchResponse({
    required this.query,
    required this.aiSynthesis,
    required this.keyFindings,
    required this.suggestedActions,
    required this.matchedItems,
  });

  factory AiSearchResponse.fromJson(Map<String, dynamic> json) {
    return AiSearchResponse(
      query: json['query'] as String? ?? '',
      aiSynthesis: json['ai_synthesis'] as String? ?? '',
      keyFindings: (json['key_findings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      suggestedActions: (json['suggested_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      matchedItems: (json['matched_items'] as List<dynamic>?)
              ?.map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class SearchService {
  final AuthService _authService = AuthService();

  /// Fast keyword search across schools, meals, ration shops, and alerts
  Future<List<SearchResult>> quickSearch(
    String query, {
    String category = 'all',
    int limit = 20,
  }) async {
    if (query.trim().isEmpty) return [];
    try {
      final headers = await _authService.getAuthHeaders();
      final uri = Uri.parse(ApiConfig.search).replace(queryParameters: {
        'q': query.trim(),
        'category': category,
        'limit': limit.toString(),
      });
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((e) => SearchResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      print('Quick search error: $e');
      return [];
    }
  }

  /// AI-powered natural language search with Groq synthesis
  Future<AiSearchResponse?> aiSearch(String query) async {
    if (query.trim().isEmpty) return null;
    try {
      final headers = await _authService.getAuthHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.aiSearch),
        headers: headers,
        body: jsonEncode({
          'query': query.trim(),
          'context_role': 'admin',
        }),
      );
      if (response.statusCode == 200) {
        return AiSearchResponse.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('AI search error: $e');
      return null;
    }
  }
}
