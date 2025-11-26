import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'notification_service.dart';

class EmailChecker {
  static Future<void> checkNewEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final baseUrl = prefs.getString('backend_url');
      if (baseUrl == null) return;

      final appDocDir = await getApplicationDocumentsDirectory();
      final cookiePath = "${appDocDir.path}/.cookies/";
      final cookieJar = PersistCookieJar(
        storage: FileStorage(cookiePath),
      );

      final dio = Dio(BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: const {"Accept": "application/json"},
      ));
      dio.interceptors.add(CookieManager(cookieJar));

      // Check if logged in
      try {
        await dio.get("/api/auth/me");
      } catch (e) {
        // Not logged in or error
        return;
      }

      // Fetch messages to see if there are new ones
      final lastMsgId = prefs.getString('last_known_message_id');

      final response =
          await dio.get("/api/messages", queryParameters: {"limit": 1});

      if (response.statusCode == 200 &&
          response.data is List &&
          (response.data as List).isNotEmpty) {
        final latestMsg = (response.data as List).first;
        final latestId = latestMsg['id'].toString();

        if (lastMsgId != null && latestId != lastMsgId) {
          // New message!
          final subject = latestMsg['subject'] ?? 'No Subject';
          final sender =
              latestMsg['sender_email'] ?? latestMsg['from'] ?? 'Unknown';
          final preview = latestMsg['preview_text'] ?? '';

          // Construct body with subject and preview
          final body = preview.isNotEmpty ? '$subject\n$preview' : subject;

          await NotificationService.showNotification(
            id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
            title: sender,
            body: body,
            sender: sender,
            payload: latestId,
          );

          // Update last known
          await prefs.setString('last_known_message_id', latestId);
        } else if (lastMsgId == null) {
          // First run, just save the ID
          await prefs.setString('last_known_message_id', latestId);
        }
      }
    } catch (e) {
      // debugPrint("Background check error: $e");
    }
  }
}
