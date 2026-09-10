import 'package:flutter/material.dart';
import '../../widgets/kpi_card.dart';
import '../../data/network/principal_service.dart';
import '../../theme/app_colors.dart';

class PrincipalDashboard extends StatefulWidget {
  const PrincipalDashboard({Key? key}) : super(key: key);

  @override
  State<PrincipalDashboard> createState() => _PrincipalDashboardState();
}

class _PrincipalDashboardState extends State<PrincipalDashboard> {
  final PrincipalService _service = PrincipalService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await _service.getPrincipalDashboard();
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_data == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Could not load dashboard data', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }

    final school = _data!['school'] as Map<String, dynamic>?;
    final recommendations = _data!['recommendations'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              school?['name'] ?? 'School Overview',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Date: ${DateTime.now().toString().split(' ')[0]}',
              style: const TextStyle(color: Colors.grey),
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
                  title: 'Total Students',
                  value: '${_data!['total_students'] ?? '--'}',
                  icon: Icons.people,
                ),
                KpiCard(
                  title: 'Meals Today',
                  value: '${_data!['meals_today'] ?? '--'}',
                  icon: Icons.restaurant,
                ),
                KpiCard(
                  title: 'Compliance',
                  value: '${(_data!['compliance_score'] as num?)?.toStringAsFixed(1) ?? '--'}%',
                  icon: Icons.check_circle,
                  color: AppColors.primaryGreen,
                ),
                KpiCard(
                  title: 'Food Waste',
                  value: '${(_data!['waste_kg'] as num?)?.toStringAsFixed(1) ?? '--'} kg',
                  icon: Icons.delete_outline,
                  color: AppColors.danger,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('AI Recommendations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (recommendations.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: AppColors.primaryGreen),
                    SizedBox(width: 8),
                    Text('No pending recommendations — all clear!'),
                  ],
                ),
              )
            else
              ...recommendations.map((rec) => _RecommendationCard(rec: rec as Map<String, dynamic>)),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final Map<String, dynamic> rec;
  const _RecommendationCard({required this.rec});

  @override
  Widget build(BuildContext context) {
    final priority = rec['priority'] as String? ?? 'LOW';
    final priorityColor = priority == 'HIGH'
        ? AppColors.danger
        : priority == 'MEDIUM'
            ? AppColors.warning
            : AppColors.primaryGreen;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16),
                const SizedBox(width: 6),
                Text(
                  priority,
                  style: TextStyle(
                      color: priorityColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              rec['title'] as String? ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              rec['description'] as String? ?? '',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Approved: ${rec['title'] ?? 'Recommendation'}'),
                        backgroundColor: AppColors.primaryGreen,
                      ),
                    );
                  },
                  child: const Text('APPROVE'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Dismissed: ${rec['title'] ?? 'Recommendation'}'),
                      ),
                    );
                  },
                  child: const Text('DISMISS'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
