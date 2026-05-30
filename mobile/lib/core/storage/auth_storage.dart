import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) =>
      _storage.write(key: AppConfig.tokenKey, value: token);

  static Future<String?> getToken() =>
      _storage.read(key: AppConfig.tokenKey);

  static Future<void> clearToken() =>
      _storage.delete(key: AppConfig.tokenKey);

  static Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
