import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_header.dart';
import '../../widgets/kpi_card.dart';
import '../../data/models/meal.dart';
import '../../theme/app_colors.dart';

/// Displays the AI vision pipeline results.
/// Accepts an optional [MealAnalysisResult] via route extra.
class AiMealAnalysisScreen extends StatelessWidget {
  final MealAnalysisResult? analysisResult;

  const AiMealAnalysisScreen({Key? key, this.analysisResult}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final result = analysisResult;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Status banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: result == null
                  ? AppColors.card
                  : (result.overallScore >= 70
                      ? AppColors.primaryGreen.withOpacity(0.15)
                      : AppColors.danger.withOpacity(0.15)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: result == null
                    ? AppColors.border
                    : (result.overallScore >= 70
                        ? AppColors.primaryGreen
                        : AppColors.danger),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  result == null
                      ? Icons.hourglass_bottom
                      : (result.overallScore >= 70
                          ? Icons.check_circle
                          : Icons.warning),
                  color: result == null
                      ? Colors.grey
                      : (result.overallScore >= 70
                          ? AppColors.primaryGreen
                          : AppColors.danger),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    result == null
                        ? 'No analysis result available'
                        : (result.overallScore >= 70
                            ? 'Analysis Complete — COMPLIANT'
                            : 'Analysis Complete — NON-COMPLIANT'),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: result == null
                          ? Colors.grey
                          : (result.overallScore >= 70
                              ? AppColors.primaryGreen
                              : AppColors.danger),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          const Text('Detected Food Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          // Detected Items List
          Card(
            child: result == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No items detected')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        (result.visionResult['food_items'] as List?)?.length ?? 0,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final items =
                          result.visionResult['food_items'] as List? ?? [];
                      final item = items[index] as Map<String, dynamic>;
                      final confidence =
                          ((item['confidence'] as num?)?.toDouble() ?? 0) * 100;
                      final isLow = confidence < 75;
                      return ListTile(
                        leading: Icon(
                          isLow ? Icons.warning : Icons.check_circle,
                          color: isLow ? AppColors.warning : AppColors.primaryGreen,
                        ),
                        title: Text(
                          item['name'] as String? ?? 'Unknown',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${item['estimated_quantity']} ${item['unit']}  •  Confidence: ${confidence.toStringAsFixed(0)}%',
                        ),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 24),
          const Text('Score Cards',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              KpiCard(
                title: 'Nutrition',
                value: '${result?.nutritionScore.toStringAsFixed(0) ?? '--'}%',
                icon: Icons.monitor_weight,
              ),
              KpiCard(
                title: 'Quantity',
                value: '${result?.quantityScore.toStringAsFixed(0) ?? '--'}%',
                icon: Icons.scale,
              ),
              KpiCard(
                title: 'Hygiene',
                value: '${result?.hygieneScore.toStringAsFixed(0) ?? '--'}%',
                icon: Icons.cleaning_services,
              ),
              KpiCard(
                title: 'Overall',
                value: '${result?.overallScore.toStringAsFixed(0) ?? '--'}%',
                icon: Icons.star,
                color: AppColors.primaryGreen,
              ),
            ],
          ),

          // Alerts from backend
          if (result != null && result.alerts.isNotEmpty) ...[
            const SizedBox(height: 24),
            ...result.alerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.warning),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.warning),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert)),
                  ],
                ),
              ),
            ),
          ],

          // AI Explanation from Groq LLM
          if (result != null && result.explanation.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('AI Explanation',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome,
                      color: AppColors.cyan, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.explanation,
                      style: const TextStyle(height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/teacher'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('CONFIRM & RETURN TO DASHBOARD'),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.go('/teacher/capture'),
            child: const Text('REANALYZE WITH NEW IMAGE'),
          ),
        ],
      ),
    );
  }
}
