import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import '../../data/network/principal_service.dart';
import '../../widgets/kpi_card.dart';
import '../../theme/app_colors.dart';

class PrincipalStudentsScreen extends StatefulWidget {
  const PrincipalStudentsScreen({super.key});

  @override
  State<PrincipalStudentsScreen> createState() => _PrincipalStudentsScreenState();
}

class _PrincipalStudentsScreenState extends State<PrincipalStudentsScreen> {
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

    if (_dashboardData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Failed to load student data.'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchData, child: const Text('Retry')),
          ],
        ),
      );
    }

    final totalStudents = _dashboardData?['total_students'] ?? 0;
    final presentStudents = _dashboardData?['present_students'] ?? 0;
    final mealsServed = _dashboardData?['meals_served_today'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Student Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Total Students',
                    value: totalStudents.toString(),
                    icon: Icons.people,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: KpiCard(
                    title: 'Attendance',
                    value: presentStudents.toString(),
                    icon: Icons.how_to_reg,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
             Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Meals Served',
                    value: mealsServed.toString(),
                    icon: Icons.restaurant,
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(child: SizedBox()), // Empty space for alignment
              ],
            ),
          ],
        ),
      ),
    );
  }
}
