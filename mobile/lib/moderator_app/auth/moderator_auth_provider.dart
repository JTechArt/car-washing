import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/storage/auth_storage.dart';

enum ModeratorAuthStatus { unknown, authenticated, unauthenticated }

class ModeratorAuthState {
  final ModeratorAuthStatus status;
  final String? token;
  final String? role;

  const ModeratorAuthState({
    required this.status,
    this.token,
    this.role,
  });

  factory ModeratorAuthState.unknown() =>
      const ModeratorAuthState(status: ModeratorAuthStatus.unknown);

  factory ModeratorAuthState.authenticated(String token, String role) =>
      ModeratorAuthState(
          status: ModeratorAuthStatus.authenticated,
          token: token,
          role: role);

  factory ModeratorAuthState.unauthenticated() =>
      const ModeratorAuthState(status: ModeratorAuthStatus.unauthenticated);
}

class ModeratorAuthNotifier extends AsyncNotifier<ModeratorAuthState> {
  @override
  Future<ModeratorAuthState> build() async {
    final token = await AuthStorage.getToken();
    if (token == null || token.isEmpty) {
      return ModeratorAuthState.unauthenticated();
    }
    return ModeratorAuthState.authenticated(token, 'MODERATOR');
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ApiClient().login(phone, password);
      final token = data['token'] as String;
      final role = data['role'] as String;

      if (role == 'CUSTOMER') {
        throw const ApiException(
          statusCode: 403,
          message:
              'Not authorized for staff access. Use the customer app instead.',
        );
      }

      await AuthStorage.saveToken(token);
      return ModeratorAuthState.authenticated(token, role);
    });
  }

  Future<void> logout() async {
    await AuthStorage.clearToken();
    state = AsyncData(ModeratorAuthState.unauthenticated());
  }
}

final moderatorAuthProvider =
    AsyncNotifierProvider<ModeratorAuthNotifier, ModeratorAuthState>(
        ModeratorAuthNotifier.new);
