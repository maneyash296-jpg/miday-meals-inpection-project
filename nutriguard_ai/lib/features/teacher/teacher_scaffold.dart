import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_header.dart';
import '../../theme/app_colors.dart';
import '../../data/network/auth_service.dart';

class TeacherScaffold extends StatefulWidget {
  final Widget child;
  const TeacherScaffold({Key? key, required this.child}) : super(key: key);

  @override
  State<TeacherScaffold> createState() => _TeacherScaffoldState();
}

class _TeacherScaffoldState extends State<TeacherScaffold> {
  int _currentIndex = 0;

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style:
                ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await AuthService().logout();
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/teacher') _currentIndex = 0;
    else if (location == '/teacher/capture') _currentIndex = 1;
    else if (location == '/teacher/inventory') _currentIndex = 2;
    else if (location == '/teacher/profile') _currentIndex = 4;

    return Scaffold(
      appBar: AppHeader(
        title: 'NutriGuard AI',
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No new notifications')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Logout',
            onPressed: _logout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          switch (index) {
            case 0:
              context.go('/teacher');
              break;
            case 1:
              context.go('/teacher/capture');
              break;
            case 2:
              context.go('/teacher/inventory');
              break;
            case 3:
              context.go('/teacher');
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alerts shown on dashboard')),
              );
              break;
            case 4:
              context.go('/teacher/profile');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.camera_alt_outlined),
            selectedIcon: Icon(Icons.camera_alt),
            label: 'Capture',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.warning_amber_outlined),
            selectedIcon: Icon(Icons.warning_amber),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
