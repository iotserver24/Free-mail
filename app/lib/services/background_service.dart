import 'dart:async';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'notification_service.dart';
import 'email_checker.dart';

@pragma('vm:entry-point')
Future<bool> onStart(ServiceInstance service) async {
  // Initialize notifications
  await NotificationService.initialize();

  // Create foreground service notification channel and set as foreground
  if (service is AndroidServiceInstance) {
    const AndroidNotificationChannel foregroundChannel = AndroidNotificationChannel(
      'foreground_service_channel',
      'Background Service',
      description: 'Keeps the email sync service running',
      importance: Importance.low,
      enableVibration: false,
      playSound: false,
      showBadge: false,
    );

    final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(foregroundChannel);

    // Set as foreground service manually with notification
    service.setAsForegroundService();

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

  // Start the periodic check every 10 seconds
  Timer.periodic(const Duration(seconds: 10), (timer) async {
    if (service is AndroidServiceInstance) {
      if (await service.isForegroundService()) {
        // Perform the email check
        await EmailChecker.checkNewEmails();
      }
    } else {
      // For other platforms or when not foreground
      await EmailChecker.checkNewEmails();
    }
  });

  // Perform an immediate check
  await EmailChecker.checkNewEmails();

  return true;
}

class BackgroundService {
  static Future<void> init() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: true,
        isForegroundMode: false,
        notificationChannelId: 'foreground_service_channel',
        initialNotificationTitle: 'Free Mail',
        initialNotificationContent: 'Syncing mail in background',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: onStart,
        onBackground: onStart,
      ),
    );
  }

  static Future<void> startService() async {
    final service = FlutterBackgroundService();
    if (await service.isRunning()) {
      return;
    }
    await service.startService();
  }

  static Future<void> stopService() async {
    final service = FlutterBackgroundService();
    service.invoke('stopService');
  }
}
