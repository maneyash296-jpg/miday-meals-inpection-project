import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/kpi_card.dart';
import '../../widgets/chart_card.dart';
import '../../data/network/district_ration_services.dart';
import '../../data/network/auth_service.dart';
import '../../theme/app_colors.dart';

class RationShopDashboard extends StatefulWidget {
  const RationShopDashboard({Key? key}) : super(key: key);

  @override
  State<RationShopDashboard> createState() => _RationShopDashboardState();
}

class _RationShopDashboardState extends State<RationShopDashboard> {
  final RationShopService _service = RationShopService();
  final AuthService _authService = AuthService();
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  // Search state
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<dynamic> _filteredInventory = [];
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  String? _shopId;

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    setState(() {
      _searchQuery = query;
    });
    if (query.isNotEmpty) {
      _performSearch(query);
    } else {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _filteredInventory = _data?['inventory'] as List<dynamic>? ?? [];
      });
    }
  }

  Future<void> _performSearch(String query) async {
    setState(() => _isSearching = true);
    final results = await _service.searchInventory(query);
    if (mounted) {
      setState(() {
        _searchResults = results;
        _isSearching = false;
        // Also filter local inventory
        final allInventory = _data?['inventory'] as List<dynamic>? ?? [];
        _filteredInventory = allInventory.where((item) {
          final name = (item['food_item']?['name'] as String? ?? '').toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final data = await _service.getDashboard();
    _shopId = await _authService.getRationShopId();
    setState(() {
      _data = data;
      _isLoading = false;
      _filteredInventory = data?['inventory'] as List<dynamic>? ?? [];
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final shop = _data?['shop'] as Map<String, dynamic>?;
    final inventory = _data?['inventory'] as List<dynamic>? ?? [];
    final alerts = _data?['alerts'] as List<dynamic>? ?? [];

    return RefreshIndicator(
      onRefresh: _load,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop?['name'] ?? 'Ration Shop Monitoring',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        shop != null
                            ? 'Code: ${shop['shop_code']} • ${shop['address'] ?? ''}'
                            : 'Government Supply & Resource Management',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_data?['risk_score'] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (_data!['risk_score'] as num) > 0.5
                          ? AppColors.danger.withOpacity(0.12)
                          : AppColors.primaryGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shield,
                          size: 14,
                          color: (_data!['risk_score'] as num) > 0.5
                              ? AppColors.danger
                              : AppColors.primaryGreen,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Risk ${((_data!['risk_score'] as num) * 100).toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (_data!['risk_score'] as num) > 0.5
                                ? AppColors.danger
                                : AppColors.primaryGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // 🔍 Search Bar
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search inventory, food items...',
                prefixIcon: const Icon(Icons.search, color: AppColors.primaryGreen),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _searchResults = [];
                            _filteredInventory = inventory;
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),

            // Search results
            if (_isSearching) ...[
              const SizedBox(height: 8),
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ] else if (_searchQuery.isNotEmpty && _searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(
                        '${_searchResults.length} result(s) for "$_searchQuery"',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _searchResults.take(5).length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final r = _searchResults[i] as Map<String, dynamic>;
                        final isLow = r['is_low_stock'] as bool? ?? false;
                        return ListTile(
                          dense: true,
                          leading: Icon(
                            Icons.inventory_2,
                            size: 20,
                            color: isLow ? AppColors.danger : AppColors.primaryGreen,
                          ),
                          title: Text(r['food_item_name'] as String? ?? ''),
                          subtitle: Text(
                            '${r['quantity']} ${r['unit']} • ${r['category']}',
                          ),
                          trailing: isLow
                              ? const Text(
                                  'LOW',
                                  style: TextStyle(
                                      color: AppColors.danger,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11),
                                )
                              : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // KPI Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
              children: [
                KpiCard(
                  title: 'Inventory Items',
                  value: '${_data?['total_stock_items'] ?? '--'}',
                  icon: Icons.inventory_2,
                ),
                KpiCard(
                  title: 'Schools Served',
                  value: '${_data?['schools_served'] ?? '--'}',
                  icon: Icons.school,
                ),
                KpiCard(
                  title: 'Pending Deliveries',
                  value: '${_data?['pending_deliveries'] ?? '--'}',
                  icon: Icons.local_shipping,
                  color: AppColors.warning,
                ),
                KpiCard(
                  title: 'Low Stock Items',
                  value: '${_data?['low_stock_count'] ?? '--'}',
                  icon: Icons.warning_amber,
                  color: (_data?['low_stock_count'] ?? 0) > 0
                      ? AppColors.danger
                      : AppColors.primaryGreen,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Forecast Chart
            const ChartCard(
              title: '30-Day Demand Forecast (kg)',
              dataPoints: [
                FlSpot(0, 720),
                FlSpot(1, 715),
                FlSpot(2, 710),
                FlSpot(3, 700),
                FlSpot(4, 690),
                FlSpot(5, 680),
                FlSpot(6, 650),
              ],
            ),

            // Active Alerts
            if (alerts.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text('Active Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...alerts.map((a) {
                final alert = a as Map<String, dynamic>;
                final isCritical = alert['severity'] == 'CRITICAL';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  child: ListTile(
                    leading: Icon(
                      isCritical ? Icons.error : Icons.warning_amber,
                      color: isCritical ? AppColors.danger : AppColors.warning,
                    ),
                    title: Text(alert['title'] as String? ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(alert['message'] as String? ?? '',
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                  ),
                );
              }).toList(),
            ],

            // Live Inventory
            const SizedBox(height: 24),
            Row(
              children: [
                const Text('Live Inventory',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_filteredInventory.length} items',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.primaryGreen),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_filteredInventory.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'No inventory items found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _filteredInventory.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item =
                        _filteredInventory[index] as Map<String, dynamic>;
                    final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
                    final minQty =
                        (item['minimum_quantity'] as num?)?.toDouble() ?? 0;
                    final isLow = qty <= minQty;
                    final foodItem = item['food_item'] as Map<String, dynamic>?;
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isLow
                              ? AppColors.danger.withOpacity(0.1)
                              : AppColors.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isLow ? Icons.warning : Icons.check_circle,
                          color: isLow
                              ? AppColors.danger
                              : AppColors.primaryGreen,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        foodItem?['name'] as String? ?? 'Item',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${qty.toStringAsFixed(1)} ${item['unit']} '
                        '${isLow ? "⚠ LOW STOCK (min: ${minQty.toStringAsFixed(0)})" : ""}',
                        style: TextStyle(
                          color: isLow ? AppColors.danger : null,
                          fontSize: 12,
                        ),
                      ),
                      trailing: foodItem != null
                          ? Text(
                              foodItem['category'] as String? ?? '',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            )
                          : null,
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),
            const Text('Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip(context, 'RECEIVE STOCK', Icons.download, () {
                  _showReceiveStockDialog(context);
                }),
                _chip(context, 'DISPATCH RATION', Icons.upload,
                    () => context.go('/ration-shop/dispatch', extra: _shopId)),
                _chip(context, 'SCHOOL ALLOCATION', Icons.assignment,
                    () => context.go('/ration-shop/allocation')),
                _chip(context, 'DELIVERIES', Icons.local_shipping, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Deliveries screen coming soon')),
                  );
                }),
                _chip(context, 'STOCK AUDIT', Icons.fact_check, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Stock audit screen coming soon')),
                  );
                }),
                _chip(context, 'AI ANALYSIS', Icons.analytics, () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('AI analysis fetching...')),
                  );
                }),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showReceiveStockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Receive Stock'),
        content: const Text(
            'Stock receiving interface will connect to your inventory. '
            'Contact district officer to log incoming deliveries.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _load(); // Refresh inventory
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen),
            child: const Text('Refresh Inventory'),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: AppColors.primaryGreen),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: Theme.of(context).cardColor,
      side: const BorderSide(color: AppColors.border),
    );
  }
}
