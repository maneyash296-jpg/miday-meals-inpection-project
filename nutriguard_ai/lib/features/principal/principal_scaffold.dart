import 'package:flutter/material.dart';
import '../../widgets/app_header.dart';
import 'package:go_router/go_router.dart';

class PrincipalScaffold extends StatefulWidget {
  final Widget child;
  const PrincipalScaffold({Key? key, required this.child}) : super(key: key);

  @override
  State<PrincipalScaffold> createState() => _PrincipalScaffoldState();
}

class _PrincipalScaffoldState extends State<PrincipalScaffold> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location == '/principal') _currentIndex = 0;
    if (location == '/principal/students') _currentIndex = 1;
    if (location == '/principal/menu') _currentIndex = 2;
    if (location == '/principal/inventory') _currentIndex = 3;
    if (location == '/principal/profile') _currentIndex = 4;

    return Scaffold(
      appBar: const AppHeader(title: 'NutriGuard AI (Principal)'),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 0) {
            context.go('/principal');
          } else if (index == 1) {
            context.go('/principal/students');
          } else if (index == 2) {
            context.go('/principal/menu');
          } else if (index == 3) {
            context.go('/principal/inventory');
          } else if (index == 4) {
            context.go('/principal/profile');
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'STUDENTS'),
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'MEALS'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'INVENTORY'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'PROFILE'),
        ],
      ),
    );
  }
}
