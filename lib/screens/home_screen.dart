import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _voltage    = 0.0;
  double _current    = 0.0;
  final int _battery = 72;
  bool _connected    = false;
  bool _loading      = true;
  String _status     = 'Connecting...';
  String _lastUpdate = '';

  static const String _dbUrl =
      'https://solarmonitor-8db42-default-rtdb.asia-southeast1.firebasedatabase.app';

  @override
  void initState() {
    super.initState();
    _listenLatest();
  }

  void _listenLatest() {
    setState(() {
      _loading   = true;
      _connected = false;
      _status    = 'Connecting...';
    });

    try {
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final db    = FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: _dbUrl,
      );

      final ref = db.ref('solar/$today');

      ref.limitToLast(1).onValue.listen(
        (DatabaseEvent event) {
          print('📡 Event received');
          print('📦 Raw: ${event.snapshot.value}');

          if (!mounted) return;

          final raw = event.snapshot.value;
          if (raw == null) {
            setState(() {
              _loading   = false;
              _connected = false;
              _status    = 'No data for today';
            });
            return;
          }

          double voltage = 0.0;
          double current = 0.0;
          String timeKey = '';

          if (raw is Map) {
            raw.forEach((key, value) {
              timeKey = key.toString();
              if (value is Map) {
                voltage = _toDouble(value['voltage']);
                current = _toDouble(value['current']);
              }
            });
          }

          print('✅ Time: $timeKey | V: $voltage | A: $current');

          setState(() {
            _voltage     = voltage;
            _current     = current;
            _connected   = true;
            _loading     = false;
            _lastUpdate  = timeKey.replaceAll('-', ':');
            _status      = 'Live';
          });
        },
        onError: (error) {
          print('❌ Error: $error');
          if (mounted) {
            setState(() {
              _loading   = false;
              _connected = false;
              _status    = 'Error: $error';
            });
          }
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      setState(() {
        _loading   = false;
        _connected = false;
        _status    = 'Exception: $e';
      });
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  String _dayName() => DateFormat('EEEE').format(DateTime.now());
  String _dateStr() => DateFormat('dd MMMM yyyy').format(DateTime.now());
  String _timeStr() => DateFormat('hh:mm a').format(DateTime.now());

  // ─────────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_loading)    return _buildLoadingScreen(isDark);
    if (!_connected) return _buildErrorScreen(isDark);
    return _buildHomeContent(isDark);
  }

  // ─────────────────────────────────────────────────
  //  LOADING SCREEN
  // ─────────────────────────────────────────────────
  Widget _buildLoadingScreen(bool isDark) => Container(
    decoration: _bgDecoration(isDark),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: const Color(0xFF1565C0),
              backgroundColor:
                  const Color(0xFF1565C0).withOpacity(0.15),
              strokeWidth: 4,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Solar Monitor',
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0D47A1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Connecting to Firebase...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please wait',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey[400],
            ),
          ),
        ],
      ),
    ),
  );

  // ─────────────────────────────────────────────────
  //  ERROR SCREEN
  // ─────────────────────────────────────────────────
  Widget _buildErrorScreen(bool isDark) => Container(
    decoration: _bgDecoration(isDark),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Connection Failed',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0D47A1),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.red.withOpacity(0.25)),
              ),
              child: Text(
                _status,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.red[400],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _checkItem('Firebase rules set to public?', isDark),
            _checkItem('Internet permission in AndroidManifest?', isDark),
            _checkItem('databaseURL correct in firebase_options?', isDark),
            _checkItem('Phone has active internet connection?', isDark),
            _checkItem('Data exists at /solar/today in Firebase?', isDark),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _listenLatest,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Retry',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 40, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _checkItem(String text, bool isDark) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      const Icon(Icons.check_circle_outline_rounded,
          size: 18, color: Color(0xFF1565C0)),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white60 : Colors.grey[600],
          ),
        ),
      ),
    ]),
  );

  // ─────────────────────────────────────────────────
  //  HOME CONTENT
  // ─────────────────────────────────────────────────
  Widget _buildHomeContent(bool isDark) => Container(
    decoration: _bgDecoration(isDark),
    child: SafeArea(
      child: RefreshIndicator(
        onRefresh: () async => _listenLatest(),
        color: const Color(0xFF1565C0),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark),
              const SizedBox(height: 16),
              _buildStatusBadge(),
              const SizedBox(height: 22),
              _buildDateTimeCard(),
              const SizedBox(height: 22),

              // Voltage + Current
              Row(children: [
                Expanded(child: _buildMetricCard(
                  icon: Icons.bolt_rounded,
                  label: 'Solar Voltage',
                  value: '${_voltage.toStringAsFixed(1)} V',
                  unit: 'Volts',
                  color: const Color(0xFF1E88E5),
                  isDark: isDark,
                )),
                const SizedBox(width: 16),
                Expanded(child: _buildMetricCard(
                  icon: Icons.electric_meter_rounded,
                  label: 'Solar Current',
                  value: '${_current.toStringAsFixed(2)} A',
                  unit: 'Amperes',
                  color: const Color(0xFF0D47A1),
                  isDark: isDark,
                )),
              ]),
              const SizedBox(height: 22),

              // Power output
              _buildPowerCard(isDark),
              const SizedBox(height: 22),

              // Battery
              _buildBatteryCard(isDark),
              const SizedBox(height: 22),

              // Last update
              if (_lastUpdate.isNotEmpty)
                Center(
                  child: Text(
                    'Last reading at $_lastUpdate',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark
                          ? Colors.white30
                          : Colors.grey[400],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );

  // ─────────────────────────────────────────────────
  //  WIDGETS
  // ─────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Solar Monitor',
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0D47A1),
          ),
        ),
        Text(
          'IoT Dashboard',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.grey[600],
          ),
        ),
      ]),
      GestureDetector(
        onTap: _listenLatest,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFF1565C0).withOpacity(0.3),
            ),
          ),
          child: const Icon(
            Icons.refresh_rounded,
            color: Color(0xFF1565C0),
            size: 24,
          ),
        ),
      ),
    ],
  );

  Widget _buildStatusBadge() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    decoration: BoxDecoration(
      color: _connected
          ? Colors.green.withOpacity(0.1)
          : Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: _connected
            ? Colors.green.withOpacity(0.3)
            : Colors.orange.withOpacity(0.3),
      ),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _connected ? Colors.green : Colors.orange,
          boxShadow: [
            BoxShadow(
              color: (_connected ? Colors.green : Colors.orange)
                  .withOpacity(0.5),
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
      const SizedBox(width: 8),
      Text(
        _connected ? 'Live — Firebase Connected' : _status,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _connected ? Colors.green : Colors.orange,
        ),
      ),
    ]),
  );

  Widget _buildDateTimeCard() => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(22),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1565C0).withOpacity(0.4),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(children: [
      const Icon(Icons.calendar_today_rounded,
          color: Colors.white70, size: 22),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _dayName(),
              style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 12),
            ),
            Text(
              _dateStr(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          _timeStr(),
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    ]),
  );

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
    required bool isDark,
  }) =>
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark ? Colors.white54 : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.orbitron(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF0D1B2A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              unit,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );

  Widget _buildPowerCard(bool isDark) {
    final power = _voltage * _current;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.power_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Solar Power Output',
              style: GoogleFonts.poppins(
                color: Colors.white70, fontSize: 13),
            ),
            Text(
              '${power.toStringAsFixed(2)} W',
              style: GoogleFonts.orbitron(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Voltage × Current',
              style: GoogleFonts.poppins(
                color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ]),
    );
  }

  Widget _buildBatteryCard(bool isDark) {
    final pct = _battery / 100;
    final Color battColor = _battery > 60
        ? const Color(0xFF1565C0)
        : _battery > 30
            ? Colors.orange
            : Colors.red;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: battColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _battery > 60
                  ? Icons.battery_full_rounded
                  : _battery > 30
                      ? Icons.battery_4_bar_rounded
                      : Icons.battery_alert_rounded,
              color: battColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Battery Status',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: isDark
                      ? Colors.white
                      : const Color(0xFF0D1B2A),
                ),
              ),
              Text(
                _battery > 60
                    ? 'Good condition'
                    : _battery > 30
                        ? 'Moderate'
                        : 'Low — charge needed',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: battColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$_battery%',
            style: GoogleFonts.orbitron(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: battColor,
            ),
          ),
        ]),
        const SizedBox(height: 18),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 14,
            backgroundColor: battColor.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(battColor),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('0%',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey)),
            Text('50%',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey)),
            Text('100%',
                style: GoogleFonts.poppins(
                    fontSize: 11, color: Colors.grey)),
          ],
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────
  //  HELPERS
  // ─────────────────────────────────────────────────
  BoxDecoration _bgDecoration(bool isDark) => BoxDecoration(
    gradient: LinearGradient(
      colors: isDark
          ? [const Color(0xFF0A0E1A), const Color(0xFF0D1B2A)]
          : [const Color(0xFFE3F2FD), const Color(0xFFF0F4FF)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}