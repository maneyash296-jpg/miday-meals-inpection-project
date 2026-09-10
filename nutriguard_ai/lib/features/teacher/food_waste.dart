import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/chart_card.dart';
import '../../data/network/school_service.dart';
import '../../theme/app_colors.dart';

class FoodWasteScreen extends StatefulWidget {
  const FoodWasteScreen({Key? key}) : super(key: key);

  @override
  State<FoodWasteScreen> createState() => _FoodWasteScreenState();
}

class _FoodWasteScreenState extends State<FoodWasteScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  double _foodWasteKg = 0.0;
  List<dynamic> _alerts = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _schoolService.getTeacherDashboard();
    setState(() {
      if (data != null) {
        _foodWasteKg = data.foodWasteKg;
        _alerts = data.alerts;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    // Prepare dynamic waste items based on the overall waste.
    // If it's just a single number from backend, we show it generically or divide it up as an example.
    final wasteCategories = [
      {'item': 'Cooked Rice', 'qty': (_foodWasteKg * 0.6).toStringAsFixed(1), 'unit': 'kg'},
      {'item': 'Dal', 'qty': (_foodWasteKg * 0.3).toStringAsFixed(1), 'unit': 'kg'},
      {'item': 'Vegetables', 'qty': (_foodWasteKg * 0.1).toStringAsFixed(1), 'unit': 'kg'},
    ];

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_alerts.isNotEmpty)
              ..._alerts.map((alert) => Card(
                color: AppColors.warning.withOpacity(0.1),
                child: ListTile(
                  leading: const Icon(Icons.warning, color: AppColors.warning),
                  title: Text(alert['message'] ?? 'Alert', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )).toList(),
            const SizedBox(height: 12),
            Text('Total Food Waste Today: ${_foodWasteKg.toStringAsFixed(1)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.danger)),
            const SizedBox(height: 16),
            const Text('Estimated Waste Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: wasteCategories.length,
              itemBuilder: (context, index) {
                final item = wasteCategories[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    leading: const Icon(Icons.delete, color: AppColors.danger),
                    title: Text(item['item'] as String),
                    trailing: Text("${item['qty']} ${item['unit']}"),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const ChartCard(
              title: '7‑Day Waste Trend (kg)',
              dataPoints: [
                FlSpot(0, 1.8),
                FlSpot(1, 2.0),
                FlSpot(2, 2.3),
                FlSpot(3, 2.1),
                FlSpot(4, 2.5),
                FlSpot(5, 2.4),
                FlSpot(6, 2.6),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
