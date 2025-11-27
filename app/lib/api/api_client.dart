import 'dart:async';
import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/notification_service.dart';
import '../services/background_service.dart';
import '../services/desktop_service.dart';

class ApiClient extends ChangeNotifier {
  ApiClient({String? baseUrl}) {
    if (baseUrl != null && baseUrl.isNotEmpty) {
      _baseUrl = _normalizeBaseUrl(baseUrl);
      _init();
    }
    // Initialize notification service
    Future.microtask(() async {
      try {
        await NotificationService.initialize();
      } catch (_) {
        // Ignore initialization errors
      }
    });
  }

  Dio? _dio;
  String? _baseUrl;
  PersistCookieJar? _cookieJar;

  bool _isLoggedIn = false;
  bool _mailBootstrapped = false;
  bool _bootstrappingMail = false;
  bool _loadingMessages = false;
  String? _mailError;

  Map<String, dynamic>? _user;
  List<Map<String, dynamic>> _domains = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _emails = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _inboxes = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _messages = <Map<String, dynamic>>[];
  String? _activeInboxId;
  String? _currentFolder;
  bool? _currentIsStarred;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get baseUrl => _baseUrl;
  Map<String, dynamic>? get user => _user;

  List<Map<String, dynamic>> get domains => List.unmodifiable(_domains);
  List<Map<String, dynamic>> get emails => List.unmodifiable(_emails);
  List<Map<String, dynamic>> get inboxes => List.unmodifiable(_inboxes);
  List<Map<String, dynamic>> get messages => List.unmodifiable(_messages);

  bool get mailBootstrapped => _mailBootstrapped;
  bool get isBootstrappingMail => _bootstrappingMail;
  bool get loadingMessages => _loadingMessages;
  String? get mailError => _mailError;

  String? get activeInboxId => _activeInboxId;

  String get activeInboxTitle {
    if (_activeInboxId == null) {
      return _mailBootstrapped ? "All Mail" : "Mailboxes";
    }
    final inbox = _inboxes.firstWhere(
      (item) => item["id"] == _activeInboxId,
      orElse: () => <String, dynamic>{},
    );
    if (inbox.isEmpty) {
      return "Inbox";
    }
    final name = inbox["name"] as String?;
    final email = inbox["email"] as String?;
    if (name != null && name.isNotEmpty) return name;
    if (email != null && email.isNotEmpty) return email;
    return "Inbox";
  }

  String? get activeFromAddress {
    if (_activeInboxId == null && _emails.isEmpty) {
      return null;
    }
    final match = _emails.firstWhere(
      (email) => email["inbox_id"] == _activeInboxId,
      orElse: () => _emails.isNotEmpty ? _emails.first : <String, dynamic>{},
    );
    return match["email"] as String?;
  }

  Future<void> _init() async {
    await _loadUserFromPrefs();
    await _initDio();
    await _hydrateExistingSession();
  }

  Future<void> _initDio() async {
    if (_baseUrl == null) return;

    if (_cookieJar == null) {
      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final cookiePath = "${appDocDir.path}/.cookies/";
        _cookieJar = PersistCookieJar(
          storage: FileStorage(cookiePath),
        );
      } catch (e) {
        // Fallback to memory cookie jar if file storage fails
        _cookieJar =
            null; // Will use default memory jar logic if needed, or fail
      }
    }

    final options = BaseOptions(
      baseUrl: _baseUrl!,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {"Accept": "application/json"},
      validateStatus: (status) => status != null && status < 500,
    );
    _dio = Dio(options);
    if (_cookieJar != null) {
      _dio!.interceptors.add(CookieManager(_cookieJar!));
    }
  }

  Future<void> _hydrateExistingSession() async {
    try {
      if (_cookieJar != null && _baseUrl != null) {
        await _cookieJar!.loadForRequest(Uri.parse(_baseUrl!));
      }
      await _hydrateUser();
      if (_isLoggedIn) {
        await bootstrapMail();
        BackgroundService.startService();
        DesktopService().startBackgroundCheck();
      }
    } catch (_) {
      // Silent failure
    }
  }

  Future<void> _hydrateUser() async {
    if (_dio == null) return;
    try {
      final response = await _dio!.get("/api/auth/me");
      final payload = response.data;
      if (response.statusCode == 200 &&
          payload is Map &&
          payload["user"] is Map) {
        _user =
            _normalizeUser(Map<String, dynamic>.from(payload["user"] as Map));
        _isLoggedIn = true;
        await _saveUserToPrefs();
      } else {
        _user = null;
        _isLoggedIn = false;
        await _clearUserFromPrefs();
      }
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        _user = null;
        _isLoggedIn = false;
        await _clearUserFromPrefs();
      }
    } finally {
      notifyListeners();
    }
  }

  Future<bool> login(String url, String email, String password) async {
    try {
      if (_baseUrl == null || _baseUrl != _normalizeBaseUrl(url)) {
        final verified = await verifyBackend(url);
        if (verified == null) return false;
      }
      final normalizedUrl = _baseUrl ?? _normalizeBaseUrl(url);

      final response = await _dio!.post("/api/auth/login", data: {
        "email": email,
        "password": password,
      });

      if (response.statusCode == 200) {
        _isLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString("backend_url", normalizedUrl);

        await _hydrateUser();
        await bootstrapMail(force: true);
        BackgroundService.startService();
        DesktopService().startBackgroundCheck();
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> verifyBackend(String url) async {
    try {
      final normalizedUrl = _normalizeBaseUrl(url);
      final tempDio = Dio(
        BaseOptions(
          baseUrl: normalizedUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );
      final response = await tempDio.get("/api/status");
      if (response.statusCode == 200) {
        _baseUrl = normalizedUrl;
        await _initDio();
        return normalizedUrl;
      }
    } catch (_) {
      // ignore errors here, caller handles feedback
    }
    return null;
  }

  Future<void> logout() async {
    stopPolling();
    try {
      await _dio?.post("/api/auth/logout");
    } catch (_) {
      // Ignore logout failures because we'll drop local session regardless.
    } finally {
      await _cookieJar?.deleteAll();
      _resetMailState();
      BackgroundService.stopService();
      DesktopService().stopBackgroundCheck();
      _isLoggedIn = false;
      _user = null;
      await _clearUserFromPrefs();
      notifyListeners();
    }
  }

  Future<void> bootstrapMail({bool force = false}) async {
    if (_dio == null || !_isLoggedIn) return;
    if (_bootstrappingMail) return;

    _bootstrappingMail = true;
    _mailError = null;
    notifyListeners();

    try {
      await Future.wait([
        loadDomains(force: force),
        loadEmails(force: force),
        loadInboxes(force: force),
      ]);

      if (_activeInboxId == null && _emails.isNotEmpty) {
        _activeInboxId = _emails.first["inbox_id"] as String?;
      }

      await loadMessages(force: true);
      _mailBootstrapped = true;
    } catch (_) {
      _mailError = "Failed to load mail data";
    } finally {
      _bootstrappingMail = false;
      notifyListeners();
    }
  }

  Future<void> refreshMail() async {
    await bootstrapMail(force: true);
  }

  Future<void> loadDomains({bool force = false}) async {
    if (_dio == null || (!_isLoggedIn && !force)) return;
    if (_domains.isNotEmpty && !force) return;

    try {
      final response = await _dio!.get("/api/domains");
      _domains = _mapList(response.data);
      notifyListeners();
    } catch (_) {
      if (_domains.isEmpty) {
        rethrow;
      }
    }
  }

  Future<void> loadEmails({bool force = false}) async {
    if (_dio == null || (!_isLoggedIn && !force)) return;
    if (_emails.isNotEmpty && !force) return;

    try {
      final response = await _dio!.get("/api/emails");
      _emails = _mapList(response.data);
      notifyListeners();
    } catch (_) {
      if (_emails.isEmpty) {
        rethrow;
      }
    }
  }

  Future<void> loadInboxes({bool force = false}) async {
    if (_dio == null || (!_isLoggedIn && !force)) return;
    if (_inboxes.isNotEmpty && !force) return;

    try {
      final response = await _dio!.get("/api/inboxes");
      _inboxes = _mapList(response.data);
      notifyListeners();
    } catch (_) {
      if (_inboxes.isEmpty) {
        rethrow;
      }
    }
  }

  Future<void> loadMessages({
    bool force = false,
    String? folder,
    bool? isStarred,
  }) async {
    if (_dio == null || !_isLoggedIn) return;

    _currentFolder = folder;
    _currentIsStarred = isStarred;

    if (_messages.isNotEmpty && !force && folder == null && isStarred == null) {
      return;
    }

    _loadingMessages = true;
    _mailError = null;
    notifyListeners();

    try {
      final query = <String, dynamic>{
        "limit": 50,
        if (_activeInboxId != null) "inboxId": _activeInboxId,
        if (folder != null) "folder": folder,
        if (isStarred != null) "isStarred": isStarred.toString(),
      };
      final response = await _dio!.get("/api/messages", queryParameters: query);
      _messages = _mapList(response.data);

      if (_messages.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'last_known_message_id', _messages.first['id'].toString());
      }

      if (_pollingTimer == null || !_pollingTimer!.isActive) {
        startPolling();
      }
    } catch (_) {
      // Start polling if not already started
      if (_pollingTimer == null || !_pollingTimer!.isActive) {
        startPolling();
      }
      _mailError = "Unable to load messages";
      _messages = <Map<String, dynamic>>[];
    } finally {
      _loadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> refreshMessages() => loadMessages(force: true);

  Future<void> setActiveInbox(String? inboxId) async {
    if (_activeInboxId == inboxId) return;
    _activeInboxId = inboxId;
    _messages = <Map<String, dynamic>>[];
    notifyListeners();
    await loadMessages(force: true);
  }

  Future<Map<String, dynamic>> fetchMessageDetail(String messageId) async {
    if (_dio == null) throw Exception("Client not initialized");
    final response = await _dio!.get("/api/messages/$messageId");
    return _mapObject(response.data);
  }

  Future<List<Map<String, dynamic>>> fetchThread(String threadId) async {
    if (_dio == null) throw Exception("Client not initialized");
    final response = await _dio!.get("/api/messages/thread/$threadId");
    return _mapList(response.data);
  }

  Future<bool> sendMessage({
    required String from,
    required List<String> to,
    required String subject,
    required String body,
    List<String>? cc,
    List<String>? bcc,
    String? threadId,
    List<Map<String, dynamic>>? attachments,
  }) async {
    if (_dio == null) return false;
    try {
      final response = await _dio!.post("/api/messages", data: {
        "from": from,
        "to": to,
        if (cc != null && cc.isNotEmpty) "cc": cc,
        if (bcc != null && bcc.isNotEmpty) "bcc": bcc,
        if (threadId != null) "threadId": threadId,
        "subject": subject,
        "text": body,
        "html": "<p>${body.replaceAll("\n", "<br />")}</p>",
        if (attachments != null && attachments.isNotEmpty)
          "attachments": attachments,
      });
      final success = response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202;
      if (success) {
        unawaited(loadMessages(force: true));
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateMessageStatus(String messageId, bool isRead) async {
    if (_dio == null) return false;
    try {
      final response = await _dio!.patch("/api/messages/$messageId", data: {
        "is_read": isRead,
      });
      if (response.statusCode == 200) {
        // Optimistic update in local list
        final index = _messages.indexWhere((m) => m['id'] == messageId);
        if (index != -1) {
          final updated = Map<String, dynamic>.from(_messages[index]);
          updated['is_read'] = isRead;
          _messages[index] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> starMessage(String messageId, bool isStarred) async {
    if (_dio == null) return false;
    try {
      final response = await _dio!.patch("/api/messages/$messageId", data: {
        "is_starred": isStarred,
      });
      if (response.statusCode == 200) {
        // Optimistic update in local list
        final index = _messages.indexWhere((m) => m['id'] == messageId);
        if (index != -1) {
          final updated = Map<String, dynamic>.from(_messages[index]);
          updated['is_starred'] = isStarred;
          _messages[index] = updated;
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> moveMessageToFolder(String messageId, String folder) async {
    if (_dio == null) return false;
    try {
      final response = await _dio!.patch("/api/messages/$messageId", data: {
        "folder": folder,
      });
      if (response.statusCode == 200) {
        // Optimistic update: remove from current list if we are viewing a specific folder
        // For now, just reload messages to be safe or remove locally
        _messages.removeWhere((m) => m['id'] == messageId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> addDomain(String domain) async {
    if (_dio == null) return false;
    try {
      final response =
          await _dio!.post("/api/domains", data: {"domain": domain});
      final success = response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202;
      if (success) {
        await loadDomains(force: true);
      }
      return success;
    } catch (_) {
      return false;
    }
  }

  Future<GeneratedEmail?> generateEmail(
    String prompt, {
    List<Map<String, dynamic>>? context,
  }) async {
    if (_dio == null) return null;
    try {
      final payload = {
        "prompt": prompt,
        if (context != null && context.isNotEmpty) "context": context,
      };
      final response =
          await _dio!.post("/api/ai/generate-email", data: payload);
      if (response.statusCode == 200) {
        final parsed = _parseGeneratedEmail(response.data);
        if (parsed != null) return parsed;
      }
      final fallback = response.data?.toString();
      if (fallback != null) {
        return GeneratedEmail(subject: null, body: fallback);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<String?> summarizeEmail(String body) async {
    if (_dio == null) return null;
    try {
      final response = await _dio!.post("/api/ai/summarize", data: {
        "body": body,
      });
      if (response.statusCode == 200 && response.data is Map) {
        return (response.data as Map)["summary"] as String?;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  void _resetMailState() {
    _domains = <Map<String, dynamic>>[];
    _emails = <Map<String, dynamic>>[];
    _inboxes = <Map<String, dynamic>>[];
    _messages = <Map<String, dynamic>>[];
    _activeInboxId = null;
    _mailBootstrapped = false;
    _bootstrappingMail = false;
    _loadingMessages = false;
    _mailError = null;
  }

  static String _normalizeBaseUrl(String raw) {
    var url = raw.trim();
    if (!url.startsWith("http")) {
      url = "https://$url";
    }
    url = url.endsWith("/") ? url.substring(0, url.length - 1) : url;
    return url;
  }

  static List<Map<String, dynamic>> _mapList(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map<Map<String, dynamic>>(Map<String, dynamic>.from)
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static Map<String, dynamic> _mapObject(dynamic data) {
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return <String, dynamic>{};
  }

  GeneratedEmail? _parseGeneratedEmail(dynamic data) {
    Map<String, dynamic>? mapData;
    if (data is Map) {
      mapData = Map<String, dynamic>.from(data);
    } else if (data is String) {
      final structured = _extractStructuredMap(data);
      if (structured != null) {
        mapData = structured;
      } else {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            mapData = Map<String, dynamic>.from(decoded);
          }
        } catch (_) {
          return GeneratedEmail(subject: null, body: data);
        }
      }
    }

    if (mapData != null) {
      final subject = mapData["subject"]?.toString();
      final bodyCandidate = mapData["body"] ??
          mapData["content"] ??
          mapData["text"] ??
          mapData["message"];
      if (bodyCandidate != null) {
        if (bodyCandidate is String) {
          final nested = _extractStructuredMap(bodyCandidate);
          if (nested != null) {
            final nestedBody = nested["body"] ??
                nested["content"] ??
                nested["text"] ??
                nested["message"];
            final nestedSubject = nested["subject"]?.toString();
            if (nestedBody != null) {
              return GeneratedEmail(
                subject: subject ?? nestedSubject,
                body: nestedBody.toString(),
              );
            }
          }
        }
        return GeneratedEmail(
          subject: subject,
          body: bodyCandidate.toString(),
        );
      }
    }
    return null;
  }

  Map<String, dynamic>? _extractStructuredMap(String raw) {
    final cleaned = raw.trim();
    final blockMatch =
        RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false)
            .firstMatch(cleaned);
    final candidate = blockMatch != null
        ? blockMatch.group(1)?.trim()
        : cleaned.startsWith('{')
            ? cleaned
            : null;
    if (candidate == null) return null;
    try {
      final decoded = jsonDecode(candidate);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<bool> updateProfile({
    String? displayName,
    String? personalEmail,
    String? avatarUrl,
  }) async {
    if (_dio == null || _user == null) return false;

    final payload = <String, dynamic>{
      if (displayName != null) 'display_name': displayName,
      if (personalEmail != null) 'personal_email': personalEmail,
      if (avatarUrl != null) 'pfp': avatarUrl,
    }..removeWhere(
        (key, value) => value == null || (value is String && value.isEmpty));

    if (payload.isEmpty) return true;

    try {
      final response =
          await _dio!.patch('/api/users/${_user!["id"]}', data: payload);
      if (response.statusCode == 200) {
        await _hydrateUser();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<bool> updateFcmToken(String token) async {
    if (_dio == null || _user == null) return false;
    try {
      final response = await _dio!.patch('/api/users/${_user!["id"]}', data: {
        'fcm_token': token,
      });
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Map<String, dynamic>? _normalizeUser(Map<String, dynamic>? raw) {
    if (raw == null) return null;
    final normalized = Map<String, dynamic>.from(raw);

    void setDual(String camel, String snake, dynamic value) {
      if (value == null) return;
      normalized[camel] = value;
      normalized[snake] = value;
    }

    setDual(
      "displayName",
      "display_name",
      raw["displayName"] ?? raw["display_name"],
    );
    setDual(
      "avatarUrl",
      "avatar_url",
      raw["avatarUrl"] ?? raw["avatar_url"],
    );
    setDual(
      "personalEmail",
      "personal_email",
      raw["personalEmail"] ?? raw["personal_email"],
    );

    return normalized;
  }

  Future<void> _saveUserToPrefs() async {
    if (_user == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_user_profile', jsonEncode(_user));
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _loadUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString('cached_user_profile');
      if (jsonStr != null) {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          _user = _normalizeUser(Map<String, dynamic>.from(decoded));
          _isLoggedIn = true;
          notifyListeners();
        }
      }
    } catch (_) {
      // Ignore
    }
  }

  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_user_profile');
    } catch (_) {
      // Ignore
    }
  }

  void startPolling() {
    _pollingTimer?.cancel();
    // Poll every 10 seconds
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      pollMessages();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> pollMessages() async {
    if (_dio == null || !_isLoggedIn) return;

    try {
      final query = <String, dynamic>{
        "limit": 50,
        if (_activeInboxId != null) "inboxId": _activeInboxId,
        if (_currentFolder != null) "folder": _currentFolder,
        if (_currentIsStarred != null)
          "isStarred": _currentIsStarred.toString(),
      };

      final response = await _dio!.get("/api/messages", queryParameters: query);
      final newMessages = _mapList(response.data);

      // Check for new emails
      if (newMessages.isNotEmpty && _messages.isNotEmpty) {
        // Find all new messages (those that don't exist in current list)
        final currentIds = _messages.map((m) => m['id']).toSet();
        final newEmailsList =
            newMessages.where((m) => !currentIds.contains(m['id'])).toList();

        // Show notification for each new email
        for (final newEmail in newEmailsList) {
          final subject = newEmail['subject'] ?? 'No Subject';
          final from = newEmail['from'] ?? 'Unknown Sender';
          final messageId = newEmail['id']?.toString() ?? '';

          try {
            await NotificationService.showNotification(
              id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: 'New Email from $from',
              body: subject,
              payload: messageId,
            );
          } catch (_) {
            // Ignore notification errors
          }
        }
      }

      bool changed = false;
      if (newMessages.length != _messages.length) {
        changed = true;
      } else if (newMessages.isNotEmpty && _messages.isNotEmpty) {
        if (newMessages.first['id'] != _messages.first['id']) {
          changed = true;
        }
      } else if (newMessages.isNotEmpty && _messages.isEmpty) {
        changed = true;
      }

      if (changed) {
        _messages = newMessages;
        notifyListeners();
      }
    } catch (_) {
      // Silent error
    }
  }
}

class GeneratedEmail {
  final String? subject;
  final String body;

  GeneratedEmail({this.subject, required this.body});
}
