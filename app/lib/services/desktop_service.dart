import 'dart:async';
import 'dart:io';

import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'email_checker.dart';

class DesktopService with TrayListener, WindowListener {
  static final DesktopService _instance = DesktopService._internal();
  factory DesktopService() => _instance;
  DesktopService._internal();

  Timer? _timer;
  bool _isInitialized = false;

  Future<void> init() async {
    if (_isInitialized) return;
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    _isInitialized = true;

    await windowManager.ensureInitialized();
    await trayManager.setIcon(
      Platform.isWindows ? 'assets/logo.ico' : 'assets/logo.png',
    );

    Menu menu = Menu(
      items: [
        MenuItem(
          key: 'show_window',
          label: 'Show App',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'exit_app',
          label: 'Exit',
        ),
      ],
    );
    await trayManager.setContextMenu(menu);

    trayManager.addListener(this);
    windowManager.addListener(this);

    // Prevent closing, minimize to tray instead
    await windowManager.setPreventClose(true);
  }

  void startBackgroundCheck() {
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      EmailChecker.checkNewEmails();
    });
    // Initial check
    EmailChecker.checkNewEmails();
  }

  void stopBackgroundCheck() {
    _timer?.cancel();
  }

  @override
  void onTrayIconMouseDown() {
    windowManager.show();
    windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    if (menuItem.key == 'show_window') {
      windowManager.show();
      windowManager.focus();
    } else if (menuItem.key == 'exit_app') {
      windowManager.destroy();
    }
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      windowManager.hide();
    }
  }
}
