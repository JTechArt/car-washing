import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/auth_provider.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'discovery/discovery_screen.dart';
import 'garage/garage_screen.dart';
import 'garage/add_vehicle_screen.dart';
import 'history/history_screen.dart';
import 'booking/booking_flow_screen.dart';
import 'booking/booking_confirmed_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      if (isLoading) return null;

      final status =
          authState.value?.status ?? AuthStatus.unauthenticated;
      final isAuth = status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!isAuth && !isLoginRoute) return '/login';
      if (isAuth && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => _ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/',
              builder: (_, __) => const DiscoveryScreen(),
              routes: [
                GoRoute(
                  path: 'booking/:carWashId',
                  builder: (_, s) => BookingFlowScreen(
                      carWashId: s.pathParameters['carWashId']!),
                ),
                GoRoute(
                  path: 'confirmed',
                  builder: (_, s) => BookingConfirmedScreen(
                    bookingId: s.uri.queryParameters['bookingId'] ?? '',
                    carWashName: s.uri.queryParameters['name'] ?? '',
                  ),
                ),
              ],
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/bookings',
              builder: (_, __) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/garage',
              builder: (_, __) => const GarageScreen(),
              routes: [
                GoRoute(
                    path: 'add',
                    builder: (_, __) => const AddVehicleScreen()),
              ],
            ),
          ]),
        ],
      ),
    ],
  );
});

class _ScaffoldWithNav extends StatelessWidget {
  final StatefulNavigationShell shell;
  const _ScaffoldWithNav({required this.shell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: shell.goBranch,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.local_car_wash_outlined), label: 'Find'),
          NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined), label: 'Bookings'),
          NavigationDestination(
              icon: Icon(Icons.directions_car_outlined), label: 'Garage'),
        ],
      ),
    );
  }
}
