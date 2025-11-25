import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'api/api_client.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);

    return MaterialApp(
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
