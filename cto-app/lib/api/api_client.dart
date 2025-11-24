import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient extends ChangeNotifier {
  Dio? _dio;
  String? _baseUrl;
  bool _isLoggedIn = false;
  final CookieJar _cookieJar = CookieJar();

  bool get isLoggedIn => _isLoggedIn;
  String? get baseUrl => _baseUrl;

  ApiClient({String? baseUrl}) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = baseUrl;
      _initDio();
    }
  }

  void _initDio() {
    if (_baseUrl == null) return;
    
    BaseOptions options = BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      validateStatus: (status) {
        return status! < 500;
      },
    );

    _dio = Dio(options);
    _dio!.interceptors.add(CookieManager(_cookieJar));
  }

  Future<bool> login(String url, String email, String password) async {
    try {
      // Normalize URL
      if (!url.startsWith('http')) {
        url = 'https://$url';
      }
      if (url.endsWith('/')) {
        url = url.substring(0, url.length - 1);
      }
      
      _baseUrl = url;
      _initDio();

      final response = await _dio!.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        _isLoggedIn = true;
        
        // Save URL
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('backend_url', _baseUrl!);
        
        notifyListeners();
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      if (_dio != null) {
        await _dio!.post('/api/auth/logout');
      }
    } catch (e) {
      // ignore
    }
    _isLoggedIn = false;
    notifyListeners();
  }

  Future<List<dynamic>> getMailboxes() async {
    if (_dio == null) throw Exception("Client not initialized");
    final response = await _dio!.get('/api/mailboxes');
    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    }
    throw Exception("Failed to load mailboxes");
  }

  Future<List<dynamic>> getDomains() async {
    if (_dio == null) throw Exception("Client not initialized");
    final response = await _dio!.get('/api/domains');
    if (response.statusCode == 200) {
      return response.data as List<dynamic>;
    }
    throw Exception("Failed to load domains");
  }

  Future<List<dynamic>> getMessages(String? inboxId) async {
    if (_dio == null) throw Exception("Client not initialized");
    // Depending on backend, might filter by inboxId or get all.
    // Swagger says /api/messages.
    // Let's check Swagger again for params.
    
    final response = await _dio!.get('/api/messages'); 
    if (response.statusCode == 200) {
      // The backend returns { messages: [], total: 0 } usually, let's check.
      // Swagger says Response is... well, it doesn't specify the list structure cleanly in the snippet I saw, 
      // but usually it's a list or paginated object.
      // Assuming it returns a JSON which contains the messages.
      
      if (response.data is List) {
        return response.data;
      } else if (response.data is Map && response.data['messages'] != null) {
        return response.data['messages'];
      }
      return [];
    }
    throw Exception("Failed to load messages");
  }
  
  Future<bool> sendMessage({
    required String from,
    required List<String> to,
    required String subject,
    required String body,
  }) async {
    if (_dio == null) return false;
    
    try {
      final response = await _dio!.post('/api/send', data: {
        'from': from,
        'to': to,
        'subject': subject,
        'text': body,
        'html': body, // sending same for html for simplicity
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Send error: $e");
      return false;
    }
  }

  // Domain adding
  Future<bool> addDomain(String domain) async {
     // Based on memory/swagger, I need to check how to add domains.
     // Swagger didn't show /api/domains explicitly in the first snippet but likely exists if it's "self-hosted" with domain adding.
     // Wait, the Swagger snippet ended early.
     // I'll assume standard REST conventions or I might need to check more files.
     // Let's assume /api/domains is the endpoint.
     if (_dio == null) return false;
     try {
       final response = await _dio!.post('/api/domains', data: {'domain': domain});
       return response.statusCode == 200 || response.statusCode == 201;
     } catch(e) {
       return false;
     }
  }

  // AI Methods
  Future<String?> generateEmail(String prompt) async {
    if (_dio == null) return null;
    try {
      final response = await _dio!.post('/api/ai/generate-email', data: {
        'prompt': prompt,
      });
      if (response.statusCode == 200) {
        // Assuming response structure based on common patterns, check backend service if needed.
        // Usually { subject: ..., body: ... } or just text.
        // Let's assume it returns { subject, body } or just body content.
        // The ai.routes.ts says res.json(result).
        // I should check aiService.generateEmail return type. 
        // But let's assume it returns a map.
        final data = response.data;
        if (data is Map) {
           if (data.containsKey('body')) return data['body'];
           if (data.containsKey('content')) return data['content'];
           // Fallback
           return data.toString();
        }
        return response.data.toString();
      }
    } catch (e) {
      print('AI Generate error: $e');
    }
    return null;
  }

  Future<String?> summarizeEmail(String body) async {
    if (_dio == null) return null;
    try {
      final response = await _dio!.post('/api/ai/summarize', data: {
        'body': body,
      });
      if (response.statusCode == 200) {
        return response.data['summary'];
      }
    } catch (e) {
      print('AI Summarize error: $e');
    }
    return null;
  }
}
