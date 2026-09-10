import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'router/app_router.dart';
import 'data/network/auth_service.dart';
import 'data/network/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiConfig.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppState()),
      ],
      child: const NutriGuardApp(),
    ),
  );
}

class AppState extends ChangeNotifier {
  final AuthService _authService = AuthService();
  String _currentRole = 'TEACHER';
  String get currentRole => _currentRole;
  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  AppState() {
    _init();
  }

  Future<void> _init() async {
    final role = await _authService.getRole();
    if (role != null) _currentRole = role;
    _isInitialized = true;
    notifyListeners();
  }

  void setRole(String role) {
    _currentRole = role;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentRole = 'TEACHER';
    notifyListeners();
  }
}

class NutriGuardApp extends StatelessWidget {
  const NutriGuardApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'NutriGuard AI',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: AppRouter.router,
    );
  }
}
