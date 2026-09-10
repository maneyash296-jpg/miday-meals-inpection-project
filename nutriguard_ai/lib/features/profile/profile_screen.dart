import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../main.dart';
import '../../theme/app_colors.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentRole = context.watch<AppState>().currentRole;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: AppColors.primaryGreen,
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Demo User ($currentRole)',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 32),
          const Text('Role Switcher (Demo Only)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                _buildRoleOption(context, 'Teacher', currentRole),
                const Divider(height: 1),
                _buildRoleOption(context, 'Principal', currentRole),
                const Divider(height: 1),
                _buildRoleOption(context, 'Ration Shop', currentRole),
                const Divider(height: 1),
                _buildRoleOption(context, 'District Officer', currentRole),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.dark_mode),
                  title: const Text('Theme Mode'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme switching available in next update')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wifi_off),
                  title: const Text('Offline Mode'),
                  trailing: Switch(
                    value: false,
                    onChanged: (val) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Offline mode requires local database sync')),
                      );
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildRoleOption(BuildContext context, String role, String currentRole) {
    final isSelected = role == currentRole;
    return ListTile(
      title: Text(role, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.primaryGreen) : null,
      onTap: () {
        context.read<AppState>().setRole(role);
        // Map role to route
        if (role == 'Teacher') context.go('/teacher');
        else if (role == 'Ration Shop') context.go('/ration-shop');
        else if (role == 'District Officer') context.go('/district');
        else if (role == 'Principal') context.go('/principal');
      },
    );
  }
}
