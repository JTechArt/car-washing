import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'auth/moderator_auth_provider.dart';
import 'auth/moderator_login_screen.dart';
import 'bays/bays_screen.dart';

final moderatorRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(moderatorAuthProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      if (authState.isLoading) return null;
      final status =
          authState.value?.status ?? ModeratorAuthStatus.unauthenticated;
      final isAuth = status == ModeratorAuthStatus.authenticated;
      final isLogin = state.matchedLocation == '/login';
      if (!isAuth && !isLogin) return '/login';
      if (isAuth && isLogin) return '/';
      return null;
    },
    routes: [
      GoRoute(
          path: '/login',
          builder: (_, __) => const ModeratorLoginScreen()),
      GoRoute(path: '/', builder: (_, __) => const BaysScreen()),
    ],
  );
});
