import 'dart:async';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'notification_service.dart';
import 'email_checker.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  Timer? _timer;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Initialize notifications
    await NotificationService.initialize();

    // Start the periodic check
    _timer = Timer.periodic(
        const Duration(seconds: 10), (_) => EmailChecker.checkNewEmails());

    // Perform an immediate check
    EmailChecker.checkNewEmails();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    // Not used for simple periodic timer
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isSystemStop) async {
    _timer?.cancel();
  }
}

class BackgroundService {
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.MIN,
        priority: NotificationPriority.MIN,
        enableVibration: false,
        playSound: false,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  static Future<void> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return;
    }

    await FlutterForegroundTask.startService(
      notificationTitle: 'Syncing mail',
      notificationText: '',
      callback: startCallback,
    );
  }

  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }
}
