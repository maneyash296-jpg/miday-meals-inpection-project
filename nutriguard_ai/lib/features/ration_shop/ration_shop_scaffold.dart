import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_header.dart';
import '../../theme/app_colors.dart';
import '../../data/network/auth_service.dart';

class RationShopScaffold extends StatefulWidget {
  final Widget child;
  const RationShopScaffold({Key? key, required this.child}) : super(key: key);

  @override
  State<RationShopScaffold> createState() => _RationShopScaffoldState();
}

class _RationShopScaffoldState extends State<RationShopScaffold> {
  int _currentIndex = 0;

  final List<String> _routes = [
    '/ration-shop',
    '/ration-shop/allocation',
    '/ration-shop/dispatch',
    '/ration-shop/profile',
  ];

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    // Sync bottom nav to current route
    if (location == '/ration-shop') _currentIndex = 0;
    else if (location == '/ration-shop/allocation') _currentIndex = 1;
    else if (location == '/ration-shop/dispatch') _currentIndex = 2;
    else if (location == '/ration-shop/profile') _currentIndex = 3;

    return Scaffold(
      appBar: AppHeader(
        title: 'NutriGuard — Ration Shop',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, size: 20),
            tooltip: 'Logout',
            onPressed: () async {
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
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger),
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await AuthService().logout();
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index < _routes.length) {
            context.go(_routes[index]);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Allocate',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Dispatch',
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
