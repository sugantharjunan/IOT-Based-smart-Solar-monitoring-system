import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Safe initialization — never crashes if already initialized
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    print('⚠️ Firebase init error: $e');
  }

  final prefs  = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDark') ?? false;

  runApp(SolarMonitorApp(isDark: isDark));
}

class SolarMonitorApp extends StatefulWidget {
  final bool isDark;
  const SolarMonitorApp({super.key, required this.isDark});

  static _SolarMonitorAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_SolarMonitorAppState>();

  @override
  State<SolarMonitorApp> createState() => _SolarMonitorAppState();
}

class _SolarMonitorAppState extends State<SolarMonitorApp> {
  late bool _isDark;

  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }

  void toggleTheme(bool val) async {
    setState(() => _isDark = val);
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', val);
  }

  bool get isDark => _isDark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solar Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}