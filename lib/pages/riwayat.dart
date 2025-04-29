import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF2F5FC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: RiwayatContent()),
          ],
        ),
      ),
    );
  }
}

class RiwayatContent extends StatefulWidget {
  const RiwayatContent({super.key});

  @override
  State<RiwayatContent> createState() => _RiwayatContentState();
}

class _RiwayatContentState extends State<RiwayatContent> {
  final _supabase = Supabase.instance.client;
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime _endDate = DateTime.now();
  bool _isLoading = false;
  List<Map<String, dynamic>> _heaterHistory = [];
  final _random = math.Random();

  List<Map<String, dynamic>> _generateRandomHistory(
      DateTime start, DateTime end) {
    final List<Map<String, dynamic>> history = [];
    final days = end.difference(start).inDays + 1;

    for (var i = 0; i < days; i++) {
      final currentDate = start.add(Duration(days: i));
      // Generate 1-3 records per day
      final recordsPerDay = _random.nextInt(3) + 1;

      for (var j = 0; j < recordsPerDay; j++) {
        final hour = _random.nextInt(24);
        final minute = _random.nextInt(60);
        final recordDate = DateTime(
          currentDate.year,
          currentDate.month,
          currentDate.day,
          hour,
          minute,
        );

        history.add({
          'riwayat_id': _random.nextInt(1000000),
          'user_id': _random.nextInt(1000),
          'status_id': _random.nextInt(3) + 1,
          'tanggal': recordDate.toIso8601String(),
          'total_waktu_menyala': _random.nextInt(180) + 30, // 30-210 minutes
        });
      }
    }

    // Sort by date descending
    history.sort((a, b) =>
        DateTime.parse(b['tanggal']).compareTo(DateTime.parse(a['tanggal'])));

    return history;
  }

  @override
  void initState() {
    super.initState();
    _loadHeaterHistory();
  }

  Future<void> _loadHeaterHistory() async {
    setState(() => _isLoading = true);

    try {
      final startDate =
          DateTime(_startDate.year, _startDate.month, _startDate.day, 0, 0, 0);
      final endDate =
          DateTime(_endDate.year, _endDate.month, _endDate.day, 23, 59, 59);

      final startStr = startDate.toIso8601String();
      final endStr = endDate.toIso8601String();

      debugPrint('Loading history for date range: $startStr to $endStr');

      // Generate random data instead of fetching from Supabase
      final randomHistory = _generateRandomHistory(startDate, endDate);

      setState(() {
        _heaterHistory = randomHistory;
        debugPrint('Generated ${_heaterHistory.length} random records');
      });
    } catch (e) {
      debugPrint('Error loading heater history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat riwayat pemanas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _heaterHistory = [];
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDateButton(bool isStartDate) {
    final date = isStartDate ? _startDate : _endDate;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: InkWell(
          onTap: () => _selectDate(isStartDate),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('dd/MM/yyyy').format(date),
                style: const TextStyle(fontSize: 16),
              ),
              const Icon(Icons.calendar_today, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = DateTime(picked.year, picked.month, picked.day);
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate;
          }
        } else {
          _endDate = DateTime(picked.year, picked.month, picked.day);
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate;
          }
        }
      });
      _loadHeaterHistory();
    }
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}j ${remainingMinutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Pemanas',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Rentang Tanggal:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildDateButton(true),
              const SizedBox(width: 12),
              const Icon(Icons.remove, color: Colors.grey),
              const SizedBox(width: 12),
              _buildDateButton(false),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _heaterHistory.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.history,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tidak ada data untuk tanggal ini',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Rentang: ${DateFormat('dd/MM/yyyy').format(_startDate)} - ${DateFormat('dd/MM/yyyy').format(_endDate)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _heaterHistory.length,
                        itemBuilder: (context, index) {
                          final item = _heaterHistory[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.access_time,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'User ID: ${item['user_id'].toString()}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Status ID: ${item['status_id']}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tanggal: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(item['tanggal']))}',
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Total waktu: ${_formatDuration(item['total_waktu_menyala'] ?? 0)}',
                                        style: const TextStyle(
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
