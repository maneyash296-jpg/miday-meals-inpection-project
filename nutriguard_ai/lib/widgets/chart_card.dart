import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_colors.dart';

class ChartCard extends StatelessWidget {
  final String title;
  final List<FlSpot> dataPoints;

  const ChartCard({
    Key? key,
    required this.title,
    required this.dataPoints,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final maxDataY = dataPoints.isEmpty ? 10.0 : dataPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b);
    final minDataY = dataPoints.isEmpty ? 0.0 : dataPoints.map((p) => p.y).reduce((a, b) => a < b ? a : b);
    final rangeY = (maxDataY - minDataY) == 0 ? 10.0 : (maxDataY - minDataY);
    final dynamicMinY = (minDataY - rangeY * 0.1).clamp(0.0, double.infinity);
    final dynamicMaxY = maxDataY + rangeY * 0.1;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 40, interval: ((dynamicMaxY - dynamicMinY) / 4).ceilToDouble().clamp(1.0, double.infinity)),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: true, reservedSize: 22, interval: 1),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: dataPoints.length.toDouble() - 1,
                  minY: dynamicMinY,
                  maxY: dynamicMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: dataPoints,
                      isCurved: true,
                      color: AppColors.primaryGreen,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.primaryGreen.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
