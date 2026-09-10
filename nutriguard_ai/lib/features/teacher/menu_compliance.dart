import 'package:flutter/material.dart';
import '../../data/network/school_service.dart';
import '../../theme/app_colors.dart';

class MenuComplianceScreen extends StatefulWidget {
  const MenuComplianceScreen({Key? key}) : super(key: key);

  @override
  State<MenuComplianceScreen> createState() => _MenuComplianceScreenState();
}

class _MenuComplianceScreenState extends State<MenuComplianceScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  double _compliancePercent = 0.0;
  List<dynamic> _recentMeals = [];

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
        _compliancePercent = data.compliancePercent;
        _recentMeals = data.recentMeals;
      }
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: AppColors.primaryGreen.withOpacity(0.1),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Overall Compliance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('${_compliancePercent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primaryGreen)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Recent Meals Detected', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _recentMeals.isEmpty
                ? const Text('No recent meals data available.')
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _recentMeals.length,
                    itemBuilder: (context, index) {
                      final meal = _recentMeals[index];
                      // Fallback logic if meal data is just a generic object since we don't have its strict definition
                      final mealName = (meal.mealType ?? 'Lunch').toString();
                      final compliance = (meal.complianceScore ?? 0).toString();
                      return Card(
                        color: Theme.of(context).cardColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.restaurant_menu, color: AppColors.cyan),
                          title: Text(mealName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Compliance: $compliance%'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {},
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}
