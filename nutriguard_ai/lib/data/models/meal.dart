class MealResponse {
  final String id;
  final String schoolId;
  final String status;
  final double? nutritionScore;
  final double? quantityScore;
  final double? hygieneScore;
  final double? overallScore;
  final String createdAt;

  MealResponse({
    required this.id,
    required this.schoolId,
    required this.status,
    this.nutritionScore,
    this.quantityScore,
    this.hygieneScore,
    this.overallScore,
    required this.createdAt,
  });

  factory MealResponse.fromJson(Map<String, dynamic> json) {
    return MealResponse(
      id: json['id'],
      schoolId: json['school_id'],
      status: json['status'],
      nutritionScore: (json['nutrition_score'] as num?)?.toDouble(),
      quantityScore: (json['quantity_score'] as num?)?.toDouble(),
      hygieneScore: (json['hygiene_score'] as num?)?.toDouble(),
      overallScore: (json['overall_score'] as num?)?.toDouble(),
      createdAt: json['created_at'],
    );
  }
}

class MealAnalysisResult {
  final String mealId;
  final String status;
  final double overallScore;
  final double hygieneScore;
  final double quantityScore;
  final double nutritionScore;
  final String explanation;
  final List<String> alerts;
  final Map<String, dynamic> visionResult;
  final Map<String, dynamic> menuCompliance;

  MealAnalysisResult({
    required this.mealId,
    required this.status,
    required this.overallScore,
    required this.hygieneScore,
    required this.quantityScore,
    required this.nutritionScore,
    required this.explanation,
    required this.alerts,
    required this.visionResult,
    required this.menuCompliance,
  });

  factory MealAnalysisResult.fromJson(Map<String, dynamic> json) {
    return MealAnalysisResult(
      mealId: json['meal_id'],
      status: json['status'],
      overallScore: (json['overall_score'] as num).toDouble(),
      hygieneScore: (json['hygiene_score'] as num).toDouble(),
      quantityScore: (json['quantity_score'] as num).toDouble(),
      nutritionScore: (json['nutrition_score'] as num).toDouble(),
      explanation: json['explanation'] ?? '',
      alerts: List<String>.from(json['alerts'] ?? []),
      visionResult: json['vision_result'] ?? {},
      menuCompliance: json['menu_compliance'] ?? {},
    );
  }
}
