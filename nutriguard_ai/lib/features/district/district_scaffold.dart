import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import 'package:go_router/go_router.dart';

class DistrictScaffold extends StatefulWidget {
  final Widget child;
  const DistrictScaffold({Key? key, required this.child}) : super(key: key);

  @override
  State<DistrictScaffold> createState() => _DistrictScaffoldState();
}

class _DistrictScaffoldState extends State<DistrictScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'NutriGuard AI (District)'),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
            // Navigate based on selected tab
            if (index == 0) {
              context.go('/district');
            } else if (index == 1) {
              context.go('/district/map');
            } else if (index == 2) {
              context.go('/district/supply');
            } else if (index == 3) {
              context.go('/district/analytics');
            } else if (index == 4) {
              context.go('/district/profile');
            }
          },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.map), label: 'MAP'),
          BottomNavigationBarItem(icon: Icon(Icons.device_hub), label: 'SUPPLY'),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: 'ANALYTICS'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }
}
