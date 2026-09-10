import 'package:flutter/material.dart';

import 'package:flutter/material.dart';
import '../../data/network/principal_service.dart';
import '../../theme/app_colors.dart';

class PrincipalInventoryScreen extends StatefulWidget {
  const PrincipalInventoryScreen({super.key});

  @override
  State<PrincipalInventoryScreen> createState() => _PrincipalInventoryScreenState();
}

class _PrincipalInventoryScreenState extends State<PrincipalInventoryScreen> {
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

    final inventory = _dashboardData?['inventory'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: inventory.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Container(
                height: MediaQuery.of(context).size.height * 0.8,
                alignment: Alignment.center,
                child: const Text('No inventory data available.'),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: inventory.length,
              itemBuilder: (context, index) {
                final item = inventory[index];
                final isLowStock = item['quantity'] < 10; // basic low stock threshold
                return Card(
                  margin: const EdgeInsets.only(bottom: 12.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item_name'] ?? 'Unknown Item',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Low Stock',
                                  style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                        Text(
                          '${item['quantity']} ${item['unit'] ?? 'kg'}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
