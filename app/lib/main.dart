import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/message_detail_screen.dart';
import 'api/api_client.dart';
import 'services/theme_service.dart';
import 'services/background_service.dart';
import 'services/desktop_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  await BackgroundService.init();
  await DesktopService().init();
  final prefs = await SharedPreferences.getInstance();
  const envUrl = String.fromEnvironment('BACKEND_URL');
  final savedUrl = envUrl.isNotEmpty ? envUrl : prefs.getString('backend_url');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiClient(baseUrl: savedUrl)),
        ChangeNotifierProvider(create: (_) => ThemeService()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _setupNotificationHandling();
  }

  void _setupNotificationHandling() {
    // Handle notification taps when app is in background/terminated
    NotificationService.notificationTapStream.listen((messageId) {
      _handleNotificationTap(messageId);
    });

    // Handle initial message if app was launched from notification
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null && message.data.containsKey('messageId')) {
        _handleNotificationTap(message.data['messageId']);
      }
    });
  }

  void _handleNotificationTap(String messageId) {
    // Navigate to message detail
    // We use a microtask to ensure the navigator is ready if called during init
    Future.microtask(() {
      navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (context) => MessageDetailScreen(messageId: messageId),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Free Mail',
      theme: FlexThemeData.light(
        scheme: themeService.scheme,
        useMaterial3: true,
      ),
      darkTheme: FlexThemeData.dark(
        scheme: themeService.scheme,
        useMaterial3: true,
      ),
      themeMode: themeService.themeMode,
      home: Consumer<ApiClient>(
        builder: (context, apiClient, child) {
          // Simple logic: if not logged in (or no base URL), show login.
          // Ideally we check session validity, but for now let's rely on isLoggedIn state in ApiClient
          if (apiClient.isLoggedIn) {
            return const HomeScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
