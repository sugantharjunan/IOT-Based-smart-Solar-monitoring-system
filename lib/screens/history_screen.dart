import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<String> _dates  = [];
  bool _loading        = true;

  static const String _dbUrl =
      'https://solarmonitor-8db42-default-rtdb.asia-southeast1.firebasedatabase.app';

  @override
  void initState() {
    super.initState();
    _loadDates();
  }

  Future<void> _loadDates() async {
    setState(() => _loading = true);
    try {
      final db  = FirebaseDatabase.instanceFor(
          app: Firebase.app(), databaseURL: _dbUrl);
      final snapshot = await db.ref('solar').get();

      if (snapshot.value == null) {
        setState(() { _dates = []; _loading = false; });
        return;
      }

      final Map data = snapshot.value as Map;
      final dates    = data.keys.map((k) => k.toString()).toList();
      dates.sort((a, b) => b.compareTo(a)); // newest first

      setState(() { _dates = dates; _loading = false; });
    } catch (e) {
      print('❌ History load error: $e');
      setState(() { _dates = []; _loading = false; });
    }
  }

  Future<void> _deleteDate(String date) async {
    try {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(), databaseURL: _dbUrl);
      await db.ref('solar/$date').remove();
      _loadDates();
    } catch (e) {
      print('❌ Delete error: $e');
    }
  }

  Future<void> _deleteAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete All History',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text(
          'This will permanently delete all readings from Firebase.',
          style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete All',
                style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(), databaseURL: _dbUrl);
      await db.ref('solar').remove();
      _loadDates();
    }
  }

  String _friendlyDate(String d) {
    final dt   = DateTime.tryParse(d);
    if (dt == null) return d;
    final diff = DateTime.now().difference(dt).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF0A0E1A), const Color(0xFF0D1B2A)]
              : [const Color(0xFFE3F2FD), const Color(0xFFF0F4FF)],
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(children: [
          _buildHeader(isDark),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(
                    color: Color(0xFF1565C0)))
                : _dates.isEmpty
                    ? _buildEmpty(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadDates,
                        color: const Color(0xFF1565C0),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
                          itemCount: _dates.length,
                          itemBuilder: (_, i) =>
                              _buildDateTile(_dates[i], isDark),
                        ),
                      ),
          ),
        ]),
      ),
    );
  }

  Widget _buildHeader(bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 8, 10),
    child: Row(children: [
      Text('History', style: GoogleFonts.orbitron(
        fontSize: 22, fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : const Color(0xFF0D47A1))),
      const Spacer(),
      IconButton(
        icon: const Icon(Icons.refresh_rounded,
            color: Color(0xFF1565C0)),
        onPressed: _loadDates,
      ),
      IconButton(
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
        onPressed: _deleteAll,
      ),
    ]),
  );

  Widget _buildEmpty(bool isDark) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history_rounded, size: 64, color: Colors.grey[400]),
      const SizedBox(height: 12),
      Text('No history yet',
        style: GoogleFonts.poppins(color: Colors.grey)),
      const SizedBox(height: 8),
      Text('Data will appear once ESP32 starts sending',
        style: GoogleFonts.poppins(
            fontSize: 12, color: Colors.grey[400])),
    ]),
  );

  Widget _buildDateTile(String date, bool isDark) => Dismissible(
    key: Key(date),
    direction: DismissDirection.endToStart,
    onDismissed: (_) => _deleteDate(date),
    background: Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      child: const Icon(Icons.delete_rounded, color: Colors.red),
    ),
    child: GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => DayDetailScreen(date: date))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10, offset: const Offset(0, 3),
          )],
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded,
                color: Color(0xFF1565C0), size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_friendlyDate(date), style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600, fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF0D1B2A))),
              Text(date, style: GoogleFonts.poppins(
                  fontSize: 12, color: Colors.grey)),
            ],
          )),
          const Icon(Icons.chevron_right_rounded,
              color: Color(0xFF1565C0)),
        ]),
      ),
    ),
  );
}

// ── Day Detail Screen ──────────────────────────────────
class DayDetailScreen extends StatefulWidget {
  final String date;
  const DayDetailScreen({super.key, required this.date});
  @override
  State<DayDetailScreen> createState() => _DayDetailScreenState();
}

class _DayDetailScreenState extends State<DayDetailScreen> {
  List<Map<String, dynamic>> _entries = [];
  bool _loading = true;

  static const String _dbUrl =
      'https://solarmonitor-8db42-default-rtdb.asia-southeast1.firebasedatabase.app';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final db = FirebaseDatabase.instanceFor(
          app: Firebase.app(), databaseURL: _dbUrl);
      final snapshot = await db.ref('solar/${widget.date}').get();

      if (snapshot.value == null) {
        setState(() { _entries = []; _loading = false; });
        return;
      }

      final Map raw    = snapshot.value as Map;
      final List<Map<String, dynamic>> entries = [];

      raw.forEach((timeKey, value) {
        if (value is Map) {
          entries.add({
            'time':    timeKey.toString().replaceAll('-', ':'),
            'voltage': _toDouble(value['voltage']),
            'current': _toDouble(value['current']),
            'power':   _toDouble(value['voltage']) *
                       _toDouble(value['current']),
          });
        }
      });

      // Sort by time
      entries.sort((a, b) =>
          a['time'].toString().compareTo(b['time'].toString()));

      setState(() { _entries = entries; _loading = false; });
    } catch (e) {
      print('❌ Detail load error: $e');
      setState(() { _loading = false; });
    }
  }

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0A0E1A) : const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(widget.date,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Text('${_entries.length} readings',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.white70)),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(
              color: Color(0xFF1565C0)))
          : _entries.isEmpty
              ? Center(child: Text('No data',
                  style: GoogleFonts.poppins()))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _entries.length,
                  itemBuilder: (_, i) =>
                      _buildEntryTile(_entries[i], isDark),
                ),
    );
  }

  Widget _buildEntryTile(Map<String, dynamic> e, bool isDark) =>
      Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1B2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF1565C0).withOpacity(0.15)),
        ),
        child: Row(children: [
          // Time
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1565C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(e['time'],
              style: GoogleFonts.orbitron(
                fontSize: 12, color: const Color(0xFF1565C0),
                fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),

          // Voltage
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${(e['voltage'] as double).toStringAsFixed(1)} V',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87)),
              Text('${(e['current'] as double).toStringAsFixed(2)} A',
                style: GoogleFonts.poppins(
                    fontSize: 12, color: Colors.grey)),
            ],
          )),

          // Power
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${(e['power'] as double).toStringAsFixed(1)} W',
              style: GoogleFonts.orbitron(
                fontSize: 13, fontWeight: FontWeight.bold,
                color: const Color(0xFF1565C0))),
            Text('power', style: GoogleFonts.poppins(
                fontSize: 10, color: Colors.grey)),
          ]),
        ]),
      );
}