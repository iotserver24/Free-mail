import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

Future<void> initializeService() async {
  try {
    final service = FlutterBackgroundService();

    /// OPTIONAL, using custom notification channel id
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'my_foreground', // id
      'MY FOREGROUND SERVICE', // title
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.low, // importance must be at low or higher level
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        // this will be executed when app is in foreground or background in separated isolate
        onStart: onStart,

        // auto start service
        autoStart: false,
        isForegroundMode: true,

        notificationChannelId: 'my_foreground',
        initialNotificationTitle: 'Free Mail Service',
        initialNotificationContent: 'Checking for new emails...',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        // auto start service
        autoStart: true,

        // this will be executed when app is in foreground in separated isolate
        onForeground: onStart,

        // you have to enable background fetch capability on xcode project
        onBackground: onIosBackground,
      ),
    );
  } catch (e) {
    debugPrint('Failed to initialize background service: $e');
  }
}

// to ensure this is executed
// run app from xcode, then from xcode menu, select Simulate Background Fetch
@pragma('vm:entry-point')
Future<bool> onIosBackground(ServiceInstance service) async {
  WidgetsFlutterBinding.ensureInitialized();
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void onStart(ServiceInstance service) async {
  // Only available for flutter 3.0.0 and later
  DartPluginRegistrant.ensureInitialized();

  // For flutter prior to 3.0.0
  // We have to register the plugin manually

  if (service is AndroidServiceInstance) {
    service.on('setAsForeground').listen((event) {
      service.setAsForegroundService();
    });

    service.on('setAsBackground').listen((event) {
      service.setAsBackgroundService();
    });
  }

  service.on('stopService').listen((event) {
    service.stopSelf();
  });

  // Initialize notifications
  await NotificationService.initialize();

  // Bring to foreground
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        /// OPTIONAL for use custom notification
        /// the notification id must be equals with AndroidConfiguration when you call configure()
        // flutterLocalNotificationsPlugin.show(
        //   888,
        //   'COOL SERVICE',
        //   'Awesome ${DateTime.now()}',
        //   const NotificationDetails(
        //     android: AndroidNotificationDetails(
        //       'my_foreground',
        //       'MY FOREGROUND SERVICE',
        //       icon: 'ic_bg_service_small',
        //       ongoing: true,
        //     ),
        //   ),
        // );

        // We don't want to spam the foreground notification
      }
    }

    // Perform the check
    await _checkNewEmails();
  });
}

Future<void> _checkNewEmails() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('backend_url');
    if (baseUrl == null) return;

    // We need cookies. Since we can't easily share the PersistCookieJar instance across isolates
    // (it locks the file), we might need a way to share the session.
    // However, PersistCookieJar *files* can be read if we are careful.
    // Or, we can just try to use the same path.

    // NOTE: In a real production app, you might want to store the session token in SecureStorage
    // and pass it to the isolate, or use a shared cookie jar if thread-safe.
    // For now, let's try to re-instantiate the cookie jar on the same path.

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
    // We need to store the "last known message ID" in SharedPreferences to compare.
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
        final from = latestMsg['from'] ?? 'Unknown';

        await NotificationService.showNotification(
          id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          title: 'New Email from $from',
          body: subject,
        );
      }

      // Update last known
      await prefs.setString('last_known_message_id', latestId);
    }
  } catch (e) {
    debugPrint("Background check error: $e");
  }
}
