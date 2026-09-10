import 'meal.dart';

class SchoolResponse {
  final String id;
  final String name;
  final String schoolCode;

  SchoolResponse({
    required this.id,
    required this.name,
    required this.schoolCode,
  });

  factory SchoolResponse.fromJson(Map<String, dynamic> json) {
    return SchoolResponse(
      id: json['id'],
      name: json['name'],
      schoolCode: json['school_code'],
    );
  }
}

class TeacherDashboard {
  final SchoolResponse? school;
  final int studentsPresent;
  final int mealsServedToday;
  final double compliancePercent;
  final double foodWasteKg;
  final List<MealResponse> recentMeals;
  final List<dynamic> alerts;

  TeacherDashboard({
    this.school,
    required this.studentsPresent,
    required this.mealsServedToday,
    required this.compliancePercent,
    required this.foodWasteKg,
    required this.recentMeals,
    required this.alerts,
  });

  factory TeacherDashboard.fromJson(Map<String, dynamic> json) {
    return TeacherDashboard(
      school: json['school'] != null ? SchoolResponse.fromJson(json['school']) : null,
      studentsPresent: json['students_present'] ?? 0,
      mealsServedToday: json['meals_served_today'] ?? 0,
      compliancePercent: (json['compliance_percent'] as num?)?.toDouble() ?? 0.0,
      foodWasteKg: (json['food_waste_kg'] as num?)?.toDouble() ?? 0.0,
      recentMeals: (json['recent_meals'] as List?)?.map((m) => MealResponse.fromJson(m)).toList() ?? [],
      alerts: json['alerts'] ?? [],
    );
  }
}
