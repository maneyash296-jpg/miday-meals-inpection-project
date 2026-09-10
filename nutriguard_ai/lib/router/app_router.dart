import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/auth/login_screen.dart';
import '../features/teacher/teacher_scaffold.dart';
import '../features/teacher/teacher_dashboard.dart';
import '../features/teacher/meal_capture.dart';
import '../features/teacher/ai_meal_analysis.dart';
import '../data/models/meal.dart';
import '../features/teacher/school_inventory.dart';
import '../features/ration_shop/ration_shop_scaffold.dart';
import '../features/ration_shop/ration_shop_dashboard.dart';
import '../features/ration_shop/school_allocation.dart';
import '../features/ration_shop/ration_dispatch.dart';
import '../features/district/district_scaffold.dart';
import '../features/district/district_dashboard.dart';
import '../features/principal/principal_scaffold.dart';
import '../features/principal/principal_dashboard.dart';
import '../features/profile/profile_screen.dart';
import '../features/district/district_map.dart';
import '../features/district/district_supply.dart';
import '../features/district/district_analytics.dart';
import '../features/principal/principal_menu.dart';
import '../features/principal/principal_students.dart';
import '../features/principal/principal_inventory.dart';
import '../data/network/auth_service.dart';
import '../features/teacher/food_waste.dart';
import '../features/teacher/menu_compliance.dart';


class AppRouter {
  static final AuthService _authService = AuthService();

  static final router = GoRouter(
    initialLocation: '/login',
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await _authService.isLoggedIn();
      final isGoingToLogin = state.matchedLocation == '/login';

      // Not logged in and not going to login → redirect to login
      if (!isLoggedIn && !isGoingToLogin) return '/login';

      // Already logged in and going to login → redirect to correct dashboard
      if (isLoggedIn && isGoingToLogin) {
        return await _authService.getInitialRoute();
      }

      return null; // No redirect needed
    },
    routes: [
      // ── Login ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // ── Teacher ──────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return TeacherScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/teacher',
            builder: (context, state) => const TeacherDashboardScreen(),
          ),
          GoRoute(
            path: '/teacher/capture',
            builder: (context, state) => const MealCaptureScreen(),
          ),
          GoRoute(
            path: '/teacher/analysis',
            builder: (context, state) => AiMealAnalysisScreen(
              analysisResult: state.extra as MealAnalysisResult?,
            ),
          ),
          GoRoute(
            path: '/teacher/inventory',
            builder: (context, state) => const SchoolInventoryScreen(),
          ),
          GoRoute(
            path: '/teacher/menu',
            builder: (context, state) => const MenuComplianceScreen(),
          ),
          GoRoute(
            path: '/teacher/waste',
            builder: (context, state) => const FoodWasteScreen(),
          ),
          GoRoute(
            path: '/teacher/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Ration Shop ──────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return RationShopScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/ration-shop',
            builder: (context, state) => const RationShopDashboard(),
          ),
          GoRoute(
            path: '/ration-shop/allocation',
            builder: (context, state) => const SchoolAllocationScreen(),
          ),
          GoRoute(
            path: '/ration-shop/dispatch',
            builder: (context, state) => RationDispatchScreen(
              shopId: state.extra as String?,
            ),
          ),
          GoRoute(
            path: '/ration-shop/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── District ─────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return DistrictScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/district',
            builder: (context, state) => const DistrictDashboard(),
          ),
          GoRoute(
            path: '/district/map',
            builder: (context, state) => const DistrictMapScreen(),
          ),
          GoRoute(
            path: '/district/supply',
            builder: (context, state) => const DistrictSupplyScreen(),
          ),
          GoRoute(
            path: '/district/analytics',
            builder: (context, state) => const DistrictAnalyticsScreen(),
          ),
          GoRoute(
            path: '/district/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // ── Principal ────────────────────────────────────────────────────────
      ShellRoute(
        builder: (context, state, child) {
          return PrincipalScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/principal',
            builder: (context, state) => const PrincipalDashboard(),
          ),
          GoRoute(
            path: '/principal/menu',
            builder: (context, state) => const PrincipalMenuScreen(),
          ),
          GoRoute(
            path: '/principal/students',
            builder: (context, state) => const PrincipalStudentsScreen(),
          ),
          GoRoute(
            path: '/principal/inventory',
            builder: (context, state) => const PrincipalInventoryScreen(),
          ),
          GoRoute(
            path: '/principal/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}
