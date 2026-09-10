import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/app_header.dart';
import '../../widgets/chart_card.dart';
import '../../data/mock_data.dart';
import '../../theme/app_colors.dart';

class DistrictAnalyticsScreen extends StatelessWidget {
  const DistrictAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ChartCard(
            title: '30‑Day Waste Trend (kg)',
            dataPoints: [
              FlSpot(0, 120),
              FlSpot(1, 115),
              FlSpot(2, 118),
              FlSpot(3, 112),
              FlSpot(4, 125),
              FlSpot(5, 119),
              FlSpot(6, 122),
            ],
          ),
          const SizedBox(height: 24),
          ChartCard(
            title: 'Compliance by School (%)',
            dataPoints: [
              FlSpot(0, 92),
              FlSpot(1, 94),
              FlSpot(2, 90),
              FlSpot(3, 95),
              FlSpot(4, 93),
              FlSpot(5, 96),
              FlSpot(6, 94),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Risk Ranking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: List.generate(6, (i) => Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: i % 2 == 0 ? AppColors.warning.withValues(alpha: 0.2) : AppColors.danger.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(child: Text('School ${i+1}\nRisk ${i*10+10}%', textAlign: TextAlign.center)),
            )),
          ),
        ],
      ),
    );
  }
}
