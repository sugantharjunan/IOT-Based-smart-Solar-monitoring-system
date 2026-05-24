import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'chart_screen.dart';
import 'about_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _index = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    ChartScreen(),
    AboutScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      extendBody: true,
      body: _screens[_index],
      bottomNavigationBar: CurvedNavigationBar(
        index: _index,
        backgroundColor: Colors.transparent,
        color: isDark
            ? const Color(0xFF0D1B2A)
            : const Color(0xFF1565C0),
        buttonBackgroundColor: isDark
            ? const Color(0xFF1565C0)
            : const Color(0xFF0D47A1),
        animationDuration: const Duration(milliseconds: 350),
        height: 62,
        items: const [
          Icon(Icons.home_rounded,
              color: Colors.white, size: 26),
          Icon(Icons.history_rounded,
              color: Colors.white, size: 26),
          Icon(Icons.bar_chart_rounded,      // ← new chart tab
              color: Colors.white, size: 26),
          Icon(Icons.info_outline_rounded,
              color: Colors.white, size: 26),
          Icon(Icons.settings_rounded,
              color: Colors.white, size: 26),
        ],
        onTap: (i) => setState(() => _index = i),
      ),
    );
  }
}