import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/api_client.dart';
import '../../core/storage/auth_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;

  const AuthState({required this.status, this.token});

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);
  factory AuthState.authenticated(String token) =>
      AuthState(status: AuthStatus.authenticated, token: token);
  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);
}

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token = await AuthStorage.getToken();
    if (token != null && token.isNotEmpty) {
      return AuthState.authenticated(token);
    }
    return AuthState.unauthenticated();
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ApiClient().login(phone, password);
      final token = data['token'] as String;
      await AuthStorage.saveToken(token);
      return AuthState.authenticated(token);
    });
  }

  Future<void> register(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final data = await ApiClient().register(phone, password);
      final token = data['token'] as String;
      await AuthStorage.saveToken(token);
      return AuthState.authenticated(token);
    });
  }

  Future<void> logout() async {
    await AuthStorage.clearToken();
    state = AsyncData(AuthState.unauthenticated());
  }
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
