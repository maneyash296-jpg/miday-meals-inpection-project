import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import '../../theme/app_colors.dart';
import '../../data/network/district_ration_services.dart';
import '../../data/network/auth_service.dart';
import 'package:go_router/go_router.dart';

class SchoolAllocationScreen extends StatefulWidget {
  const SchoolAllocationScreen({Key? key}) : super(key: key);

  @override
  State<SchoolAllocationScreen> createState() => _SchoolAllocationScreenState();
}

class _SchoolAllocationScreenState extends State<SchoolAllocationScreen> {
  final RationShopService _service = RationShopService();
  final AuthService _authService = AuthService();

  List<dynamic> _schools = [];
  List<dynamic> _filteredSchools = [];
  Map<String, dynamic>? _selectedSchool;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _shopId;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSchools();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final q = _searchController.text.toLowerCase();
    setState(() {
      _filteredSchools = _schools.where((s) {
        final name = (s['name'] as String? ?? '').toLowerCase();
        final code = (s['school_code'] as String? ?? '').toLowerCase();
        return name.contains(q) || code.contains(q);
      }).toList();
    });
  }

  Future<void> _loadSchools() async {
    setState(() => _isLoading = true);
    _shopId = await _authService.getRationShopId();
    final schools = await _service.getAllSchools();
    setState(() {
      _schools = schools;
      _filteredSchools = schools;
      _isLoading = false;
    });
  }

  Future<void> _approveAllocation() async {
    if (_selectedSchool == null || _shopId == null) return;
    setState(() => _isSubmitting = true);

    // Navigate to dispatch with the selected school data
    if (!mounted) return;
    context.go('/ration-shop/dispatch', extra: _shopId);
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
                // Search schools
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Schools',
                    hintText: 'Enter school name or code...',
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.primaryGreen),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _filteredSchools = _schools);
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Schools list
                if (_filteredSchools.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Center(
                        child: Text(
                          'No schools found',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                          child: Text(
                            '${_filteredSchools.length} school(s)',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _filteredSchools.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final school =
                                _filteredSchools[i] as Map<String, dynamic>;
                            final isSelected =
                                _selectedSchool?['id'] == school['id'];
                            return ListTile(
                              selected: isSelected,
                              selectedColor: AppColors.primaryGreen,
                              selectedTileColor:
                                  AppColors.primaryGreen.withOpacity(0.08),
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryGreen.withOpacity(0.15)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.school,
                                  size: 20,
                                  color: isSelected
                                      ? AppColors.primaryGreen
                                      : Colors.grey,
                                ),
                              ),
                              title: Text(
                                school['name'] as String? ?? '',
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  fontSize: 13,
                                ),
                              ),
                              subtitle: Text(
                                'Code: ${school['school_code']} • ${school['student_count']} students',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                      color: AppColors.primaryGreen)
                                  : null,
                              onTap: () {
                                setState(() => _selectedSchool = school);
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                if (_selectedSchool != null) ...[
                  const SizedBox(height: 24),
                  // School Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.school,
                                  color: AppColors.primaryGreen, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'School Information',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          _buildInfoRow(
                              'Name', _selectedSchool!['name'] as String? ?? ''),
                          _buildInfoRow(
                              'Code', _selectedSchool!['school_code'] as String? ?? ''),
                          _buildInfoRow(
                              'Students',
                              '${_selectedSchool!['student_count'] ?? '--'}'),
                          _buildInfoRow(
                              'Address',
                              _selectedSchool!['address'] as String? ?? 'N/A'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Standard vs AI Allocation
                  const Text(
                    'Standard Allocation vs AI Suggestion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  _buildComparisonCard('Fortified Rice', '500 kg', '465 kg'),
                  _buildComparisonCard('Toor Dal', '120 kg', '115 kg'),
                  _buildComparisonCard('Sunflower Oil', '40 L', '38 L'),
                  _buildComparisonCard('Eggs', '1500 pcs', '1420 pcs'),

                  const SizedBox(height: 24),

                  // AI Insight Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primaryGreen.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: AppColors.primaryGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'AI recommendation based on ${_selectedSchool!['student_count']} students '
                            'and historical consumption patterns. Saves ~8% over standard allocation.',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.primaryGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _approveAllocation,
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child:
                                CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check_circle),
                    label: const Text('APPROVE AI ALLOCATION'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.edit),
                    label: const Text('EDIT MANUAL ALLOCATION'),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(String item, String std, String ai) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                item,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Standard: $std',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome,
                        color: AppColors.primaryGreen, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'AI: $ai',
                      style: const TextStyle(
                          color: AppColors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
