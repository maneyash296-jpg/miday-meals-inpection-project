import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../theme/app_colors.dart';
import '../../data/network/district_ration_services.dart';
import '../../data/network/auth_service.dart';
import 'package:go_router/go_router.dart';

class RationDispatchScreen extends StatefulWidget {
  final String? shopId;
  const RationDispatchScreen({Key? key, this.shopId}) : super(key: key);

  @override
  State<RationDispatchScreen> createState() => _RationDispatchScreenState();
}

class _RationDispatchScreenState extends State<RationDispatchScreen> {
  final RationShopService _service = RationShopService();
  final AuthService _authService = AuthService();

  final _vehicleController = TextEditingController();
  final _driverController = TextEditingController();
  final _schoolSearchController = TextEditingController();

  List<dynamic> _schools = [];
  List<dynamic> _filteredSchools = [];
  Map<String, dynamic>? _selectedSchool;
  List<dynamic> _inventory = [];
  List<Map<String, dynamic>> _dispatchItems = [];

  bool _isLoading = true;
  bool _isDispatching = false;
  bool _showSchoolDropdown = false;
  String? _shopId;

  @override
  void initState() {
    super.initState();
    _load();
    _schoolSearchController.addListener(_onSchoolSearch);
  }

  @override
  void dispose() {
    _vehicleController.dispose();
    _driverController.dispose();
    _schoolSearchController.dispose();
    super.dispose();
  }

  void _onSchoolSearch() {
    final q = _schoolSearchController.text.toLowerCase();
    setState(() {
      _filteredSchools = _schools.where((s) {
        final name = (s['name'] as String? ?? '').toLowerCase();
        final code = (s['school_code'] as String? ?? '').toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
      _showSchoolDropdown = q.isNotEmpty || _filteredSchools.isNotEmpty;
    });
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    _shopId = widget.shopId ?? await _authService.getRationShopId();
    final schools = await _service.getAllSchools();

    List<dynamic> inventory = [];
    if (_shopId != null) {
      inventory = await _service.getInventory(_shopId!);
    }

    // Build default dispatch items from inventory
    final defaultItems = inventory.take(3).map((inv) {
      return {
        'food_item_id': inv['food_item_id'] as String? ?? '',
        'name': inv['food_item']?['name'] as String? ?? 'Item',
        'unit': inv['unit'] as String? ?? 'kg',
        'available': (inv['quantity'] as num?)?.toDouble() ?? 0.0,
        'quantity_controller': TextEditingController(text: '0'),
        'dispatch_quantity': 0.0,
      };
    }).toList();

    setState(() {
      _schools = schools;
      _filteredSchools = schools;
      _inventory = inventory;
      _dispatchItems = defaultItems;
      _isLoading = false;
    });
  }

  Future<void> _dispatch() async {
    if (_selectedSchool == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a destination school'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_vehicleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter vehicle number'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() => _isDispatching = true);

    final items = _dispatchItems
        .where((item) => (item['dispatch_quantity'] as double) > 0)
        .map((item) => {
              'food_item_id': item['food_item_id'],
              'expected_quantity': item['dispatch_quantity'],
              'dispatched_quantity': item['dispatch_quantity'],
            })
        .toList();

    if (items.isEmpty) {
      setState(() => _isDispatching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set quantity for at least one item'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_shopId == null) {
      setState(() => _isDispatching = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop ID not found. Please re-login.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final result = await _service.dispatchDelivery(
      shopId: _shopId!,
      schoolId: _selectedSchool!['id'] as String,
      vehicleNumber: _vehicleController.text.trim(),
      driverName: _driverController.text.trim(),
      items: items,
    );

    if (!mounted) return;
    setState(() => _isDispatching = false);

    if (result != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.primaryGreen),
              SizedBox(width: 8),
              Text('Dispatched!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery #${result['delivery_number']} created successfully.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Destination: ${_selectedSchool!['name']}',
                style: const TextStyle(fontSize: 13),
              ),
              Text(
                'Vehicle: ${_vehicleController.text}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                context.go('/ration-shop');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
              ),
              child: const Text('DONE'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to dispatch. Please try again.'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Route Section ──────────────────────────────────────
                const Text(
                  'Dispatch Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 12),
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildRouteRow(
                          'FROM',
                          Icons.store,
                          'Ration Shop (${_shopId?.substring(0, 8) ?? 'RS'}...)',
                          AppColors.primaryGreen,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Icon(Icons.arrow_downward,
                              color: Colors.grey, size: 16),
                        ),

                        // ── Destination School Search ──────────────────
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.school,
                                  color: Colors.blue, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('TO (School)',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  if (_selectedSchool != null) ...[
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            _selectedSchool!['name']
                                                    as String? ??
                                                '',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _selectedSchool = null;
                                            _schoolSearchController.clear();
                                          }),
                                          child: const Icon(Icons.close,
                                              size: 16, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${_selectedSchool!['student_count'] ?? ''} students • ${_selectedSchool!['school_code'] ?? ''}',
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey),
                                    ),
                                  ] else ...[
                                    TextField(
                                      controller: _schoolSearchController,
                                      decoration: InputDecoration(
                                        hintText: 'Search and select school...',
                                        hintStyle: const TextStyle(
                                            fontSize: 13, color: Colors.grey),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 6),
                                        border: InputBorder.none,
                                        suffixIcon: const Icon(Icons.search,
                                            size: 16, color: Colors.grey),
                                      ),
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                    // School dropdown results
                                    if (_filteredSchools.isNotEmpty &&
                                        _schoolSearchController
                                            .text.isNotEmpty)
                                      Container(
                                        constraints: const BoxConstraints(
                                            maxHeight: 160),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                              color: AppColors.border),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: ListView.builder(
                                          shrinkWrap: true,
                                          itemCount:
                                              _filteredSchools.take(5).length,
                                          itemBuilder: (context, i) {
                                            final s = _filteredSchools[i]
                                                as Map<String, dynamic>;
                                            return ListTile(
                                              dense: true,
                                              title: Text(
                                                s['name'] as String? ?? '',
                                                style: const TextStyle(
                                                    fontSize: 13),
                                              ),
                                              subtitle: Text(
                                                s['school_code'] as String? ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 11),
                                              ),
                                              onTap: () {
                                                setState(() {
                                                  _selectedSchool = s;
                                                  _schoolSearchController
                                                      .clear();
                                                });
                                              },
                                            );
                                          },
                                        ),
                                      ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Dispatch Items ─────────────────────────────────────
                const Text(
                  'Items to Dispatch',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 8),
                if (_dispatchItems.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Center(
                        child: Text('No inventory items available to dispatch',
                            style: TextStyle(color: Colors.grey)),
                      ),
                    ),
                  )
                else
                  ..._dispatchItems.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    return _buildDispatchItemCard(i, item);
                  }).toList(),

                const SizedBox(height: 20),

                // ── Delivery Info ──────────────────────────────────────
                const Text(
                  'Delivery Information',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _vehicleController,
                  decoration: InputDecoration(
                    labelText: 'Vehicle Number *',
                    hintText: 'e.g. AP09AB1234',
                    prefixIcon: const Icon(Icons.directions_car),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _driverController,
                  decoration: InputDecoration(
                    labelText: 'Driver Name',
                    prefixIcon: const Icon(Icons.person),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                  ),
                ),
                const SizedBox(height: 24),

                // ── Dispatch Button ────────────────────────────────────
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isDispatching ? null : _dispatch,
                    icon: _isDispatching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.local_shipping),
                    label: Text(
                      _isDispatching ? 'DISPATCHING...' : 'MARK DISPATCHED',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: () => context.pop(),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('CANCEL'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
  }

  Widget _buildRouteRow(
      String label, IconData icon, String value, Color color) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold)),
            Text(value,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ],
    );
  }

  Widget _buildDispatchItemCard(int index, Map<String, dynamic> item) {
    final available = item['available'] as double;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2,
                  color: AppColors.primaryGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String? ?? 'Item',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  Text(
                    'Available: ${available.toStringAsFixed(1)} ${item['unit']}',
                    style:
                        const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 90,
              child: TextField(
                controller:
                    item['quantity_controller'] as TextEditingController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: item['unit'] as String? ?? 'kg',
                  labelStyle: const TextStyle(fontSize: 11),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 10),
                  isDense: true,
                ),
                onChanged: (val) {
                  final qty = double.tryParse(val) ?? 0.0;
                  setState(() {
                    _dispatchItems[index]['dispatch_quantity'] = qty;
                  });
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
