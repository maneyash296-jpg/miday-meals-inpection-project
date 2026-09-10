import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../data/network/school_service.dart';
import '../../data/models/school.dart';
import '../../theme/app_colors.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({Key? key}) : super(key: key);

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final SchoolService _schoolService = SchoolService();
  TeacherDashboard? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final data = await _schoolService.getTeacherDashboard();
    setState(() {
      _dashboardData = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_dashboardData == null) {
      return const Center(child: Text('Failed to load dashboard data.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Good Morning, Teacher',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            '${_dashboardData!.school?.name ?? "Unknown School"} • ${DateTime.now().toString().split(' ')[0]}',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              KpiCard(
                title: 'Students Present',
                value: '${_dashboardData!.studentsPresent}',
                icon: Icons.people,
              ),
              KpiCard(
                title: 'Meals Served',
                value: '${_dashboardData!.mealsServedToday}',
                icon: Icons.restaurant,
              ),
              KpiCard(
                title: 'Compliance',
                value: '${_dashboardData!.compliancePercent}%',
                icon: Icons.check_circle,
                color: AppColors.primaryGreen,
              ),
              KpiCard(
                title: 'Food Waste',
                value: '${_dashboardData!.foodWasteKg} kg',
                icon: Icons.delete_outline,
                color: AppColors.danger,
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/teacher/capture');
              },
              icon: const Icon(Icons.camera_alt, size: 28),
              label: const Text('CAPTURE TODAY\'S MEAL', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const ChartCard(
            title: '7-Day Food Waste Trend (kg)',
            dataPoints: [
              FlSpot(0, 4.2),
              FlSpot(1, 3.8),
              FlSpot(2, 5.1),
              FlSpot(3, 4.7),
              FlSpot(4, 6.2),
              FlSpot(5, 5.8),
              FlSpot(6, 6.2),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ActionChip(
                label: const Text('MENU COMPLIANCE'),
                avatar: const Icon(Icons.restaurant_menu, size: 16, color: AppColors.cyan),
                onPressed: () => context.go('/teacher/menu'),
              ),
              ActionChip(
                label: const Text('FOOD WASTE'),
                avatar: const Icon(Icons.delete, size: 16, color: AppColors.danger),
                onPressed: () => context.go('/teacher/waste'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Attention Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _dashboardData!.alerts.length,
            itemBuilder: (context, index) {
              final alert = _dashboardData!.alerts[index];
              final isCritical = alert['severity'] == 'CRITICAL';
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: Icon(
                    isCritical ? Icons.error : Icons.warning,
                    color: isCritical ? AppColors.danger : AppColors.warning,
                  ),
                  title: Text(alert['title'] ?? ''),
                  subtitle: Text(alert['message'] ?? ''),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
