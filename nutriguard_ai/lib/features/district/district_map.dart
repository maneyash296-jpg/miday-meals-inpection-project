import 'package:flutter/material.dart';
import '../../data/network/district_ration_services.dart';
import '../../theme/app_colors.dart';

class DistrictMapScreen extends StatefulWidget {
  const DistrictMapScreen({Key? key}) : super(key: key);

  @override
  State<DistrictMapScreen> createState() => _DistrictMapScreenState();
}

class _DistrictMapScreenState extends State<DistrictMapScreen> {
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

    final schools = _dashboardData?['high_risk_schools'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Schools & Ration Shops Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${_dashboardData?['total_schools'] ?? '--'} schools • ${_dashboardData?['total_ration_shops'] ?? '--'} ration shops',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            const Text('High Risk Schools',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            if (schools.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: const [
                        Icon(Icons.check_circle, size: 40, color: AppColors.primaryGreen),
                        SizedBox(height: 8),
                        Text('No high risk schools identified', style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: schools.length,
                itemBuilder: (context, index) {
                  final school = schools[index] as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning, color: AppColors.danger, size: 20),
                      ),
                      title: Text(school['name'] as String? ?? 'Unknown School',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        'Compliance: ${school['compliance_score'] ?? '--'}% • Waste: ${school['waste_kg'] ?? '--'} kg',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            const Text('Ration Shops',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: AppColors.primaryGreen, size: 20),
                ),
                title: const Text('Central Civil Supplies Depot'),
                subtitle: const Text('Status: Active • Capacity: 10,000 kg'),
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.store, color: AppColors.primaryGreen, size: 20),
                ),
                title: const Text('Fair Price Shop #12'),
                subtitle: const Text('Status: Active • Capacity: 8,000 kg'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
