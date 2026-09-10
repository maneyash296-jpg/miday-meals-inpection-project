import 'package:flutter/material.dart';
import '../../data/network/district_ration_services.dart';
import '../../theme/app_colors.dart';
import '../../widgets/kpi_card.dart';

class DistrictSupplyScreen extends StatefulWidget {
  const DistrictSupplyScreen({super.key});

  @override
  State<DistrictSupplyScreen> createState() => _DistrictSupplyScreenState();
}

class _DistrictSupplyScreenState extends State<DistrictSupplyScreen> {
  final DistrictService _districtService = DistrictService();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final data = await _districtService.getDashboard();
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

    final totalRationShops = _dashboardData?['total_ration_shops'] ?? 0;
    final totalSchools = _dashboardData?['total_schools'] ?? 0;

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Supply Chain Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: KpiCard(
                    title: 'Ration Shops',
                    value: '$totalRationShops',
                    icon: Icons.store,
                    color: AppColors.cyan,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: KpiCard(
                    title: 'Total Schools',
                    value: '$totalSchools',
                    icon: Icons.school,
                    color: AppColors.primaryGreen,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Pending Deliveries',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping, color: AppColors.warning, size: 20),
                ),
                title: const Text('Pending Dispatch to Zone A'),
                subtitle: const Text('3 Schools Awaiting Supply'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.local_shipping, color: AppColors.warning, size: 20),
                ),
                title: const Text('Pending Dispatch to Zone B'),
                subtitle: const Text('1 School Awaiting Supply'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
