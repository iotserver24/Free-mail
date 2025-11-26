import 'dart:async';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Stream controller to handle notification taps
  static final StreamController<String> _notificationTapStream =
      StreamController<String>.broadcast();
  static Stream<String> get notificationTapStream =>
      _notificationTapStream.stream;

  static Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
      macOS: initializationSettingsDarwin,
      linux: initializationSettingsLinux,
    );

    await _notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle notification tap
        if (details.payload != null && details.payload!.isNotEmpty) {
          final messageId = details.payload!;
          debugPrint('Notification tapped for message: $messageId');
          _notificationTapStream.add(messageId);
        }
      },
    );

    // Request permission for Android 13+
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? sender,
  }) async {
    final BigTextStyleInformation bigTextStyleInformation =
        BigTextStyleInformation(
      body,
      htmlFormatBigText: true,
      contentTitle: title,
      htmlFormatContentTitle: true,
      summaryText: sender,
      htmlFormatSummaryText: true,
    );

    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'new_email_channel',
      'New Emails',
      channelDescription: 'Notifications for new emails',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      styleInformation: bigTextStyleInformation,
      /* actions: <AndroidNotificationAction>[
        const AndroidNotificationAction(
          'archive',
          'Archive',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'mark_read',
          'Mark as read',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        const AndroidNotificationAction(
          'reply',
          'Reply',
          inputs: <AndroidNotificationActionInput>[
            AndroidNotificationActionInput(
              label: 'Reply',
            ),
          ],
        ),
      ], */
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _notificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  static void dispose() {
    _notificationTapStream.close();
  }
}
