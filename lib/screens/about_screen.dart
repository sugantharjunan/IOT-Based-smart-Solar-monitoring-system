import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

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
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'About',
                  style: GoogleFonts.orbitron(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0D47A1),
                  ),
                ),
                const SizedBox(height: 24),

                // ✅ Solar Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.asset(
                    'assets/images/solar.jpg',
                    // ✅ Change 'solar.jpg' to whatever your file is named
                    // e.g. 'assets/images/solar_panel.png'
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _imagePlaceholder(),
                  ),
                ),
                const SizedBox(height: 8),

                // Image caption
                Center(
                  child: Text(
                    'Solar Panel Monitoring System',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? Colors.white38 : Colors.grey[500],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Info cards
                _infoCard(
                  title: 'Solar Energy Monitor',
                  body:
                      'This IoT project monitors real-time solar panel performance. '
                      'It reads voltage and current from the solar panel via sensors '
                      'and uploads the data to Firebase Realtime Database, which is '
                      'then streamed live to this app.',
                  icon: Icons.solar_power_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _infoCard(
                  title: 'Technology Stack',
                  body: 'Flutter · Firebase · IoT Sensors\n'
                      'Real-time database streaming · Cloud sync',
                  icon: Icons.code_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _infoCard(
                  title: 'How It Works',
                  body:
                      'Sensors measure solar voltage (V) and current (A). '
                      'The microcontroller uploads readings to Firebase. '
                      'The app receives these values in real time and displays '
                      'them on a live dashboard.',
                  icon: Icons.settings_input_antenna_rounded,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),

                // Developer card
                _infoCard(
                  title: 'Developer',
                  body: 'Built with Flutter & Firebase\n'
                      'IoT Solar Monitoring Project\n'
                      'Version 1.0.0',
                  icon: Icons.person_rounded,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Shown if image file is missing
  Widget _imagePlaceholder() => Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF1565C0).withOpacity(0.1),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.image_outlined,
              size: 48,
              color: Color(0xFF1565C0),
            ),
            const SizedBox(height: 10),
            Text(
              'Add solar.jpg to assets/images/',
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      );

  Widget _infoCard({
    required String title,
    required String body,
    required IconData icon,
    required bool isDark,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color:
                          isDark ? Colors.white : const Color(0xFF0D1B2A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      height: 1.6,
                      color: isDark ? Colors.white60 : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}