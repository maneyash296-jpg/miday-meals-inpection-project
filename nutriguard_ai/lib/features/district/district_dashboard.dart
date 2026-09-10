import 'package:flutter/material.dart';
import '../../widgets/kpi_card.dart';
import '../../data/network/district_ration_services.dart';
import '../../theme/app_colors.dart';

class DistrictDashboard extends StatefulWidget {
  const DistrictDashboard({Key? key}) : super(key: key);

  @override
  State<DistrictDashboard> createState() => _DistrictDashboardState();
}

class _DistrictDashboardState extends State<DistrictDashboard> {
  final DistrictService _service = DistrictService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getDashboard();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final highRiskSchools =
        _data?['high_risk_schools'] as List<dynamic>? ?? [];
    final alerts = _data?['alerts'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'District Resource Intelligence',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-Time Nutrition & Supply Monitoring',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                KpiCard(
                  title: 'Schools',
                  value: '${_data?['total_schools'] ?? '--'}',
                  icon: Icons.school,
                ),
                KpiCard(
                  title: 'Ration Shops',
                  value: '${_data?['total_ration_shops'] ?? '--'}',
                  icon: Icons.store,
                ),
                KpiCard(
                  title: 'Meals Monitored',
                  value: '${_data?['meals_monitored_today'] ?? '--'}',
                  icon: Icons.restaurant,
                ),
                KpiCard(
                  title: 'Total Waste',
                  value:
                      '${(_data?['total_waste_kg'] as num?)?.toStringAsFixed(1) ?? '--'} kg',
                  icon: Icons.delete_outline,
                  color: AppColors.danger,
                ),
                KpiCard(
                  title: 'Avg Compliance',
                  value:
                      '${(_data?['avg_compliance'] as num?)?.toStringAsFixed(1) ?? '--'}%',
                  icon: Icons.check_circle,
                  color: AppColors.primaryGreen,
                ),
                KpiCard(
                  title: 'High Risk Schools',
                  value: '${highRiskSchools.length}',
                  icon: Icons.warning,
                  color: AppColors.warning,
                ),
              ],
            ),

            // High-risk schools list
            if (highRiskSchools.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('High Risk Schools',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Card(
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: highRiskSchools.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final school =
                        highRiskSchools[index] as Map<String, dynamic>;
                    return ListTile(
                      leading: const Icon(Icons.warning, color: AppColors.danger),
                      title: Text(school['name'] as String? ?? ''),
                      subtitle: Text(
                        'Compliance: ${school['compliance_score'] ?? '--'}% • Waste: ${school['waste_kg'] ?? '--'} kg',
                      ),
                    );
                  },
                ),
              ),
            ],

            // Active alerts
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Active Alerts',
                  style:
                      TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...alerts.map((a) {
                final alert = a as Map<String, dynamic>;
                final isCritical = alert['severity'] == 'CRITICAL';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      isCritical ? Icons.error : Icons.warning,
                      color: isCritical ? AppColors.danger : AppColors.warning,
                    ),
                    title: Text(alert['title'] as String? ?? ''),
                    subtitle: Text(alert['message'] as String? ?? ''),
                  ),
                );
              }),
            ],

            const SizedBox(height: 24),
            const Text('District Map',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Map Visualisation',
                        style: TextStyle(color: Colors.grey)),
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
