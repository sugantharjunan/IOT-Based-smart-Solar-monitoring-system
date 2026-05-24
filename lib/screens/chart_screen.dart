import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ChartScreen extends StatefulWidget {
  const ChartScreen({super.key});
  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  // date string → highest watt value that day
  Map<String, double> _dailyMaxWatts = {};
  bool _loading = true;
  String _error = '';
  int _touchedIndex = -1;

  static const String _dbUrl =
      'https://solarmonitor-8db42-default-rtdb.asia-southeast1.firebasedatabase.app';

  @override
  void initState() {
    super.initState();
    _loadChartData();
  }

  Future<void> _loadChartData() async {
    setState(() {
      _loading = true;
      _error   = '';
    });

    try {
      final db       = FirebaseDatabase.instanceFor(
          app: Firebase.app(), databaseURL: _dbUrl);
      final snapshot = await db.ref('solar').get();

      if (snapshot.value == null) {
        setState(() {
          _dailyMaxWatts = {};
          _loading       = false;
        });
        return;
      }

      final Map raw          = snapshot.value as Map;
      final Map<String, double> dailyMax = {};

      raw.forEach((dateKey, timeMap) {
        if (timeMap is! Map) return;
        double maxWatts = 0.0;

        timeMap.forEach((timeKey, reading) {
          if (reading is! Map) return;
          final v = _toDouble(reading['voltage']);
          final c = _toDouble(reading['current']);
          final w = v * c;
          if (w > maxWatts) maxWatts = w;
        });

        dailyMax[dateKey.toString()] = maxWatts;
      });

      // Sort by date
      final sorted = Map.fromEntries(
        dailyMax.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key)),
      );

      setState(() {
        _dailyMaxWatts = sorted;
        _loading       = false;
      });
    } catch (e) {
      print('❌ Chart load error: $e');
      setState(() {
        _loading = false;
        _error   = e.toString();
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

  String _shortDate(String date) {
    final dt = DateTime.tryParse(date);
    if (dt == null) return date;
    final today     = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));
    if (DateFormat('yyyy-MM-dd').format(today) == date)     return 'Today';
    if (DateFormat('yyyy-MM-dd').format(yesterday) == date) return 'Yest.';
    return DateFormat('dd\nMMM').format(dt);
  }

  bool _isToday(String date) =>
      DateFormat('yyyy-MM-dd').format(DateTime.now()) == date;

  bool _isYesterday(String date) =>
      DateFormat('yyyy-MM-dd')
          .format(DateTime.now().subtract(const Duration(days: 1))) ==
      date;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: _bgDecoration(isDark),
      child: SafeArea(
        child: Column(children: [
          _buildHeader(isDark),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF1565C0)))
                : _error.isNotEmpty
                    ? _buildError(isDark)
                    : _dailyMaxWatts.isEmpty
                        ? _buildEmpty(isDark)
                        : _buildContent(isDark),
          ),
        ]),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────
  Widget _buildHeader(bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
    child: Row(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Analytics',
          style: GoogleFonts.orbitron(
            fontSize: 22, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0D47A1))),
        Text('Daily peak power output',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.grey[600])),
      ]),
      const Spacer(),
      GestureDetector(
        onTap: _loadChartData,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF1565C0).withOpacity(0.12),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF1565C0).withOpacity(0.3)),
          ),
          child: const Icon(Icons.refresh_rounded,
              color: Color(0xFF1565C0), size: 22),
        ),
      ),
    ]),
  );

  // ── MAIN CONTENT ───────────────────────────────────
  Widget _buildContent(bool isDark) {
    final dates  = _dailyMaxWatts.keys.toList();
    final values = _dailyMaxWatts.values.toList();
    final maxVal = values.isEmpty
        ? 10.0
        : values.reduce((a, b) => a > b ? a : b);
    final yMax   = (maxVal * 1.25).clamp(10.0, double.infinity);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(children: [
        // Summary cards row
        _buildSummaryCards(isDark, dates, values, maxVal),
        const SizedBox(height: 24),

        // Bar chart card
        _buildBarChartCard(isDark, dates, values, yMax),
        const SizedBox(height: 24),

        // Daily breakdown list
        _buildDailyList(isDark, dates, values, maxVal),
      ]),
    );
  }

  // ── SUMMARY CARDS ──────────────────────────────────
  Widget _buildSummaryCards(
    bool isDark,
    List<String> dates,
    List<double> values,
    double maxVal,
  ) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yest  = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    final todayVal = _dailyMaxWatts[today]  ?? 0.0;
    final yesterVal= _dailyMaxWatts[yest]   ?? 0.0;
    final totalDays= dates.length;

    return Row(children: [
      Expanded(child: _summaryCard(
        label: 'Today Peak',
        value: '${todayVal.toStringAsFixed(1)} W',
        icon: Icons.wb_sunny_rounded,
        color: const Color(0xFF1565C0),
        isDark: isDark,
      )),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(
        label: 'Yesterday',
        value: '${yesterVal.toStringAsFixed(1)} W',
        icon: Icons.history_rounded,
        color: const Color(0xFF1976D2),
        isDark: isDark,
      )),
      const SizedBox(width: 12),
      Expanded(child: _summaryCard(
        label: 'All-time Peak',
        value: '${maxVal.toStringAsFixed(1)} W',
        icon: Icons.emoji_events_rounded,
        color: const Color(0xFFFFA000),
        isDark: isDark,
      )),
    ]);
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withOpacity(0.2)),
      boxShadow: [BoxShadow(
        color: color.withOpacity(0.08),
        blurRadius: 8, offset: const Offset(0, 3),
      )],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(height: 10),
        Text(value,
          style: GoogleFonts.orbitron(
            fontSize: 13, fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0D1B2A))),
        const SizedBox(height: 2),
        Text(label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isDark ? Colors.white38 : Colors.grey[500])),
      ],
    ),
  );

  // ── BAR CHART ──────────────────────────────────────
  Widget _buildBarChartCard(
    bool isDark,
    List<String> dates,
    List<double> values,
    double yMax,
  ) => Container(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.07),
        blurRadius: 12, offset: const Offset(0, 4),
      )],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Chart header
        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Color(0xFF1565C0), size: 20),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Peak Watts Per Day',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 14,
                color: isDark
                    ? Colors.white
                    : const Color(0xFF0D1B2A))),
            Text('Tap a bar for details',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: isDark
                    ? Colors.white38
                    : Colors.grey[500])),
          ]),
        ]),
        const SizedBox(height: 24),

        // Chart
        SizedBox(
          height: 240,
          child: BarChart(
            BarChartData(
              maxY: yMax,
              minY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF1565C0),
                  tooltipRoundedRadius: 10,
                  getTooltipItem: (group, _, rod, __) {
                    final date  = dates[group.x];
                    final label = _isToday(date)
                        ? 'Today'
                        : _isYesterday(date)
                            ? 'Yesterday'
                            : DateFormat('dd MMM').format(
                                DateTime.parse(date));
                    return BarTooltipItem(
                      '$label\n',
                      GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: '${rod.toY.toStringAsFixed(1)} W',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                touchCallback: (event, response) {
                  setState(() {
                    if (response == null ||
                        response.spot == null ||
                        event is FlTapUpEvent == false) {
                      if (event is FlPointerExitEvent ||
                          event is FlTapUpEvent) {
                        _touchedIndex = -1;
                      }
                      return;
                    }
                    _touchedIndex =
                        response.spot!.touchedBarGroupIndex;
                  });
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    interval: yMax / 4,
                    getTitlesWidget: (val, _) => Text(
                      '${val.toInt()}W',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: isDark
                            ? Colors.white38
                            : Colors.grey[500]),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (val, _) {
                      final i = val.toInt();
                      if (i < 0 || i >= dates.length) {
                        return const SizedBox();
                      }
                      final label = _shortDate(dates[i]);
                      final isSpecial = _isToday(dates[i]) ||
                          _isYesterday(dates[i]);
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: isSpecial
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSpecial
                                ? const Color(0xFF1565C0)
                                : isDark
                                    ? Colors.white38
                                    : Colors.grey[500],
                            height: 1.3,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: yMax / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: isDark
                      ? Colors.white.withOpacity(0.06)
                      : Colors.grey.withOpacity(0.15),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  left: BorderSide(
                    color: isDark
                        ? Colors.white12
                        : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                  right: BorderSide.none,
                  top: BorderSide.none,
                ),
              ),
              barGroups: List.generate(dates.length, (i) {
                final isTouched = _touchedIndex == i;
                final isToday   = _isToday(dates[i]);
                final isYest    = _isYesterday(dates[i]);

                // Colors
                final Color barColor = isToday
                    ? const Color(0xFF1565C0)
                    : isYest
                        ? const Color(0xFF42A5F5)
                        : isDark
                            ? const Color(0xFF1976D2).withOpacity(0.5)
                            : const Color(0xFF90CAF9);

                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: values[i],
                      width: dates.length > 7 ? 18 : 28,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        topRight: Radius.circular(6),
                      ),
                      color: isTouched
                          ? Colors.white
                          : barColor,
                      backDrawRodData: BackgroundBarChartRodData(
                        show: true,
                        toY: yMax,
                        color: isDark
                            ? Colors.white.withOpacity(0.03)
                            : Colors.grey.withOpacity(0.06),
                      ),
                      gradient: isTouched
                          ? null
                          : LinearGradient(
                              colors: isToday
                                  ? [
                                      const Color(0xFF1565C0),
                                      const Color(0xFF42A5F5),
                                    ]
                                  : isYest
                                      ? [
                                          const Color(0xFF1976D2),
                                          const Color(0xFF64B5F6),
                                        ]
                                      : [
                                          barColor,
                                          barColor.withOpacity(0.6),
                                        ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                    ),
                  ],
                );
              }),
            ),
            duration: const Duration(milliseconds: 500),
          ),
        ),

        const SizedBox(height: 16),

        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(const Color(0xFF1565C0), 'Today'),
            const SizedBox(width: 16),
            _legendDot(const Color(0xFF42A5F5), 'Yesterday'),
            const SizedBox(width: 16),
            _legendDot(const Color(0xFF90CAF9), 'Past days'),
          ],
        ),
      ],
    ),
  );

  Widget _legendDot(Color color, String label) => Row(
    children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 5),
      Text(label,
        style: GoogleFonts.poppins(
          fontSize: 11, color: Colors.grey[500])),
    ],
  );

  // ── DAILY LIST ─────────────────────────────────────
  Widget _buildDailyList(
    bool isDark,
    List<String> dates,
    List<double> values,
    double maxVal,
  ) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 12, offset: const Offset(0, 4),
      )],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Breakdown',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600, fontSize: 15,
            color: isDark ? Colors.white : const Color(0xFF0D1B2A))),
        const SizedBox(height: 16),
        ...List.generate(dates.length, (i) {
          // Show newest first in list
          final idx    = dates.length - 1 - i;
          final date   = dates[idx];
          final watts  = values[idx];
          final pct    = maxVal > 0 ? watts / maxVal : 0.0;
          final isToday = _isToday(date);
          final isYest  = _isYesterday(date);

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  // Date label
                  SizedBox(
                    width: 80,
                    child: Text(
                      isToday
                          ? 'Today'
                          : isYest
                              ? 'Yesterday'
                              : DateFormat('dd MMM')
                                  .format(DateTime.parse(date)),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: isToday || isYest
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isToday
                            ? const Color(0xFF1565C0)
                            : isDark
                                ? Colors.white70
                                : Colors.black87,
                      ),
                    ),
                  ),
                  // Progress bar
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.grey.withOpacity(0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isToday
                              ? const Color(0xFF1565C0)
                              : isYest
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFF90CAF9),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Watt value
                  SizedBox(
                    width: 58,
                    child: Text(
                      '${watts.toStringAsFixed(1)} W',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isToday
                            ? const Color(0xFF1565C0)
                            : isDark
                                ? Colors.white54
                                : Colors.grey[700],
                      ),
                    ),
                  ),
                ]),
              ],
            ),
          );
        }),
      ],
    ),
  );

  // ── EMPTY / ERROR ──────────────────────────────────
  Widget _buildEmpty(bool isDark) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.bar_chart_rounded, size: 64, color: Colors.grey[400]),
        const SizedBox(height: 12),
        Text('No data yet',
          style: GoogleFonts.poppins(
            fontSize: 16, color: Colors.grey[600])),
        const SizedBox(height: 6),
        Text('Data will appear once ESP32 sends readings',
          style: GoogleFonts.poppins(
            fontSize: 12, color: Colors.grey[400])),
      ],
    ),
  );

  Widget _buildError(bool isDark) => Center(
    child: Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 56, color: Colors.red[400]),
          const SizedBox(height: 16),
          Text('Failed to load chart',
            style: GoogleFonts.poppins(
              fontSize: 16, fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 8),
          Text(_error,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12, color: Colors.red[400])),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadChartData,
            icon: const Icon(Icons.refresh_rounded),
            label: Text('Retry',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                  horizontal: 32, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    ),
  );

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