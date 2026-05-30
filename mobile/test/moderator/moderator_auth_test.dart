import 'package:flutter_test/flutter_test.dart';
import 'package:lva_mobile/moderator_app/auth/moderator_auth_provider.dart';

void main() {
  test('ModeratorAuthState.unauthenticated has unauthenticated status', () {
    final s = ModeratorAuthState.unauthenticated();
    expect(s.status, ModeratorAuthStatus.unauthenticated);
    expect(s.token, isNull);
  });

  test('ModeratorAuthState.authenticated carries token and role', () {
    final s = ModeratorAuthState.authenticated('token-123', 'MODERATOR');
    expect(s.status, ModeratorAuthStatus.authenticated);
    expect(s.token, 'token-123');
    expect(s.role, 'MODERATOR');
  });

  test('OWNER role is allowed as authenticated', () {
    final s = ModeratorAuthState.authenticated('token-abc', 'OWNER');
    expect(s.status, ModeratorAuthStatus.authenticated);
    expect(s.role, 'OWNER');
  });
}
