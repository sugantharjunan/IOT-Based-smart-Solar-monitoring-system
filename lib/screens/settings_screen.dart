import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDark = false;
  String _language = 'English';

  final List<String> _languages = ['English', 'Tamil', 'Hindi', 'Arabic'];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool('isDark') ?? false;
      _language = prefs.getString('language') ?? 'English';
    });
  }

  Future<void> _deleteAllHistory() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete All History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('All historical readings will be permanently deleted.',
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('history_'));
      for (final k in keys) prefs.remove(k);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All history deleted', style: GoogleFonts.poppins()),
            backgroundColor: const Color(0xFF1565C0),
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Logout', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Are you sure you want to logout?', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [const Color(0xFF0A0E1A), const Color(0xFF0D1B2A)]
                : [const Color(0xFFE3F2FD), const Color(0xFFF0F4FF)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: GoogleFonts.orbitron(
                  fontSize: 22, fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0D47A1))),

                const SizedBox(height: 8),
                Text('Welcome to Solar Monitor',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark ? Colors.white54 : Colors.grey[600])),

                const SizedBox(height: 28),

                // Appearance
                _sectionLabel('Appearance', isDark),
                _settingCard(isDark, children: [
                  _switchTile(
                    icon: _isDark
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    title: 'Dark Mode',
                    subtitle: _isDark ? 'Dark theme active' : 'Light theme active',
                    value: _isDark,
                    onChanged: (v) async {
                      setState(() => _isDark = v);
                      SolarMonitorApp.of(context)?.toggleTheme(v);
                      final prefs = await SharedPreferences.getInstance();
                      prefs.setBool('isDark', v);
                    },
                    isDark: isDark,
                  ),
                ]),

                const SizedBox(height: 16),

                // Language
                _sectionLabel('Language', isDark),
                _settingCard(isDark, children: [
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1565C0).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.language_rounded,
                          color: Color(0xFF1565C0), size: 20),
                    ),
                    title: Text('Language', style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black87)),
                    subtitle: Text(_language, style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white54 : Colors.grey)),
                    trailing: DropdownButton<String>(
                      value: _language,
                      underline: const SizedBox(),
                      items: _languages.map((l) => DropdownMenuItem(
                        value: l, child: Text(l, style: GoogleFonts.poppins()),
                      )).toList(),
                      onChanged: (v) async {
                        if (v != null) {
                          setState(() => _language = v);
                          final prefs = await SharedPreferences.getInstance();
                          prefs.setString('language', v);
                        }
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: 16),

                // Data
                _sectionLabel('Data', isDark),
                _settingCard(isDark, children: [
                  _actionTile(
                    icon: Icons.delete_sweep_rounded,
                    title: 'Delete All History',
                    subtitle: 'Remove all saved readings',
                    color: Colors.red,
                    onTap: _deleteAllHistory,
                    isDark: isDark,
                  ),
                ]),

                const SizedBox(height: 16),

                // Notifications (bonus)
                _sectionLabel('Notifications', isDark),
                _settingCard(isDark, children: [
                  _switchTile(
                    icon: Icons.notifications_rounded,
                    title: 'Voltage Alerts',
                    subtitle: 'Alert when voltage drops below 10V',
                    value: true,
                    onChanged: (_) {},
                    isDark: isDark,
                  ),
                ]),

                const SizedBox(height: 16),

                // Account
                _sectionLabel('Account', isDark),
                _settingCard(isDark, children: [
                  _actionTile(
                    icon: Icons.logout_rounded,
                    title: 'Logout',
                    subtitle: 'Sign out of your account',
                    color: const Color(0xFF1565C0),
                    onTap: _logout,
                    isDark: isDark,
                  ),
                ]),

                const SizedBox(height: 16),

                // App info
                Center(
                  child: Text('Solar Monitor v1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white30 : Colors.grey[400])),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(label.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11, fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: const Color(0xFF1565C0))),
  );

  Widget _settingCard(bool isDark, {required List<Widget> children}) => Container(
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 10, offset: const Offset(0, 3),
      )],
    ),
    child: Column(children: children),
  );

  Widget _switchTile({
    required IconData icon, required String title,
    required String subtitle, required bool value,
    required ValueChanged<bool> onChanged, required bool isDark,
  }) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1565C0).withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: const Color(0xFF1565C0), size: 20),
    ),
    title: Text(title, style: GoogleFonts.poppins(
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87)),
    subtitle: Text(subtitle, style: GoogleFonts.poppins(
      fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
    trailing: Switch.adaptive(
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFF1565C0),
    ),
  );

  Widget _actionTile({
    required IconData icon, required String title,
    required String subtitle, required Color color,
    required VoidCallback onTap, required bool isDark,
  }) => ListTile(
    onTap: onTap,
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    ),
    title: Text(title, style: GoogleFonts.poppins(
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87)),
    subtitle: Text(subtitle, style: GoogleFonts.poppins(
      fontSize: 12, color: isDark ? Colors.white54 : Colors.grey)),
    trailing: Icon(Icons.chevron_right_rounded, color: color),
  );
}