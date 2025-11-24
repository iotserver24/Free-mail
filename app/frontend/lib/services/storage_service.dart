import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyBackendUrl = 'backend_url';
  static const String _keySessionCookie = 'session_cookie';
  static const String _keyEmail = 'email';
  static const String _keyPassword = 'password';

  late final FlutterSecureStorage _secureStorage;
  late final SharedPreferences _prefs;

  Future<void> init() async {
    _secureStorage = const FlutterSecureStorage(
      aOptions: AndroidOptions(
        encryptedSharedPreferences: true,
      ),
    );
    _prefs = await SharedPreferences.getInstance();
  }

  // Backend URL
  Future<void> saveBackendUrl(String url) async {
    await _prefs.setString(_keyBackendUrl, url);
  }

  Future<String?> getBackendUrl() async {
    return _prefs.getString(_keyBackendUrl);
  }

  // Session Cookie (secure storage)
  Future<void> saveSessionCookie(String cookie) async {
    await _secureStorage.write(key: _keySessionCookie, value: cookie);
  }

  Future<String?> getSessionCookie() async {
    return await _secureStorage.read(key: _keySessionCookie);
  }

  // Credentials (secure storage)
  Future<void> saveCredentials(String email, String password) async {
    await _secureStorage.write(key: _keyEmail, value: email);
    await _secureStorage.write(key: _keyPassword, value: password);
  }

  Future<Map<String, String>?> getCredentials() async {
    final email = await _secureStorage.read(key: _keyEmail);
    final password = await _secureStorage.read(key: _keyPassword);
    
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }

  // Clear all data
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }
}
