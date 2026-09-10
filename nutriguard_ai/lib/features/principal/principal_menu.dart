import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import '../../data/network/principal_service.dart';
import '../../theme/app_colors.dart';

class PrincipalMenuScreen extends StatefulWidget {
  const PrincipalMenuScreen({super.key});

  @override
  State<PrincipalMenuScreen> createState() => _PrincipalMenuScreenState();
}

class _PrincipalMenuScreenState extends State<PrincipalMenuScreen> {
  final PrincipalService _principalService = PrincipalService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _principalService.getPrincipalDashboard();
    setState(() {
      _dashboardData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    // Determine menu info (if available in dashboard or use placeholder)
    final dailyMenu = [
      {'item': 'Rice', 'nutrition': 'Carbs'},
      {'item': 'Dal', 'nutrition': 'Protein'},
      {'item': 'Vegetables', 'nutrition': 'Vitamins'},
    ];

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Today\'s Menu & Nutrition Targets', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Energy Target:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('700 kcal', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Protein Target:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('20g', style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Planned Items', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: dailyMenu.length,
              itemBuilder: (context, index) {
                final item = dailyMenu[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ListTile(
                    leading: const Icon(Icons.restaurant_menu, color: AppColors.cyan),
                    title: Text(item['item']!),
                    subtitle: Text('Provides: ${item['nutrition']}'),
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
