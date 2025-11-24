import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  final StorageService _storageService;
  bool _isAuthenticated = false;
  String? _backendUrl;
  String? _sessionCookie;

  AuthService(this._storageService);

  Future<bool> isAuthenticated() async {
    _backendUrl = await _storageService.getBackendUrl();
    _sessionCookie = await _storageService.getSessionCookie();
    _isAuthenticated = _backendUrl != null && _sessionCookie != null;
    return _isAuthenticated;
  }

  Future<String?> getBackendUrl() async {
    _backendUrl ??= await _storageService.getBackendUrl();
    return _backendUrl;
  }

  Future<bool> login({
    required String backendUrl,
    required String email,
    required String password,
  }) async {
    try {
      // Remove trailing slash from backend URL
      final cleanUrl = backendUrl.endsWith('/')
          ? backendUrl.substring(0, backendUrl.length - 1)
          : backendUrl;

      final response = await http.post(
        Uri.parse('$cleanUrl/api/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        // Extract session cookie from response
        final cookies = response.headers['set-cookie'];
        
        if (cookies != null) {
          // Save backend URL and session cookie
          await _storageService.saveBackendUrl(cleanUrl);
          await _storageService.saveSessionCookie(cookies);
          await _storageService.saveCredentials(email, password);
          
          _backendUrl = cleanUrl;
          _sessionCookie = cookies;
          _isAuthenticated = true;
          
          notifyListeners();
          return true;
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Try to logout from backend
      if (_backendUrl != null && _sessionCookie != null) {
        await http.post(
          Uri.parse('$_backendUrl/api/auth/logout'),
          headers: {
            'Cookie': _sessionCookie!,
          },
        );
      }
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      // Clear local storage
      await _storageService.clearAll();
      _backendUrl = null;
      _sessionCookie = null;
      _isAuthenticated = false;
      notifyListeners();
    }
  }

  Future<Map<String, String>> getAuthHeaders() async {
    final cookie = await _storageService.getSessionCookie();
    return {
      'Content-Type': 'application/json',
      if (cookie != null) 'Cookie': cookie,
    };
  }
}
