import 'package:flutter/material.dart';
import '../../data/network/school_service.dart';
import '../../theme/app_colors.dart';

class SchoolInventoryScreen extends StatefulWidget {
  const SchoolInventoryScreen({Key? key}) : super(key: key);

  @override
  State<SchoolInventoryScreen> createState() => _SchoolInventoryScreenState();
}

class _SchoolInventoryScreenState extends State<SchoolInventoryScreen> {
  final SchoolService _schoolService = SchoolService();
  bool _isLoading = true;
  List<dynamic> _inventory = [];
  List<dynamic> _filteredInventory = [];

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    final data = await _schoolService.getInventory();
    setState(() {
      _inventory = data;
      _filteredInventory = data;
      _isLoading = false;
    });
  }

  void _filterInventory(String query) {
    setState(() {
      _filteredInventory = _inventory.where((item) {
        final name = (item['item_name'] ?? '').toString().toLowerCase();
        return name.contains(query.toLowerCase());
      }).toList();
    });
  }

  void _showInfoDialog(String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: const Text('This feature is coming soon.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
    }

    return RefreshIndicator(
      onRefresh: _fetchInventory,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              onChanged: _filterInventory,
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', true),
                  _buildFilterChip('Grains', false),
                  _buildFilterChip('Pulses', false),
                  _buildFilterChip('Oil', false),
                  _buildFilterChip('Vegetables', false),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _filteredInventory.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(child: Text('No inventory items found.')),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _filteredInventory.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _filteredInventory[index];
                      final isLowStock = (item['quantity'] ?? 0) < 10;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['item_name']?.toString() ?? 'Unknown',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  if (isLowStock)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Low Stock',
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              Text(
                                '${item['quantity']} ${item['unit'] ?? 'kg'}',
                                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showInfoDialog('Receive Stock'),
              icon: const Icon(Icons.download),
              label: const Text('RECEIVE STOCK'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showInfoDialog('Adjust Stock'),
              child: const Text('ADJUST STOCK'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _showInfoDialog('View History'),
              child: const Text('VIEW HISTORY'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (val) {},
        selectedColor: AppColors.primaryGreen.withValues(alpha: 0.2),
        checkmarkColor: AppColors.primaryGreen,
      ),
    );
  }
}
