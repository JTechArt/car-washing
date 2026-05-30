import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/client_app/auth/auth_provider.dart';

void main() {
  test('AuthState.unknown has unknown status', () {
    final s = AuthState.unknown();
    expect(s.status, AuthStatus.unknown);
    expect(s.token, isNull);
  });

  test('AuthState.authenticated carries token', () {
    final s = AuthState.authenticated('my-token');
    expect(s.status, AuthStatus.authenticated);
    expect(s.token, 'my-token');
  });

  test('AuthState.unauthenticated has no token', () {
    final s = AuthState.unauthenticated();
    expect(s.status, AuthStatus.unauthenticated);
    expect(s.token, isNull);
  });
}
