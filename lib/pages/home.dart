import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _supabase = Supabase.instance.client;
  double? _currentTemp;
  double? _minTemp;
  double? _maxTemp;
  bool _isLoading = true;
  bool _isHeaterOn = false;
  int? _currentHeaterStatusId;
  Stream<List<Map<String, dynamic>>>? _tempSettingsStream;
  Timer? _tempUpdateTimer;
  List<FlSpot> _chartData = [];
  double _maxY = 0;
  List<Map<String, dynamic>> _heaterHistory = [];
  final _random = math.Random();

  @override
  void initState() {
    super.initState();
    _setupRealtimeSubscription();
    _loadInitialData();
    _startRandomTempUpdates();
    _loadHeaterHistory();
  }

  @override
  void dispose() {
    _tempUpdateTimer?.cancel();
    super.dispose();
  }

  void _setupRealtimeSubscription() {
    _tempSettingsStream = _supabase
        .from('temperature_settings')
        .stream(primaryKey: ['pengaturan_id'])
        .order('updated_at', ascending: false)
        .limit(1);
  }

  void _startRandomTempUpdates() {
    // Update suhu setiap 5 detik
    _tempUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // Generate random temperature between 20 and 35 degrees
          _currentTemp = double.parse(
              (20 + (Random().nextDouble() * 15)).toStringAsFixed(1));

          // Simpan data ke database
          _saveTempToDatabase();
        });
      }
    });
  }

  Future<void> _saveTempToDatabase() async {
    try {
      // Cek apakah user sudah terautentikasi
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('User not authenticated');
        return;
      }

      await _supabase.from('sensor_data').insert({
        'suhu_air': _currentTemp?.toString(),
        'tanggal_waktu': DateTime.now().toIso8601String(),
        'user_id': user.id, // Tambahkan user_id ke data
      });
    } catch (e) {
      debugPrint('Error saving temperature data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan data suhu: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Load latest temperature settings
      final settings = await _supabase
          .from('temperature_settings')
          .select()
          .order('updated_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Load latest sensor data
      final sensorData = await _supabase
          .from('sensor_data')
          .select()
          .order('tanggal_waktu', ascending: false)
          .limit(1)
          .maybeSingle();

      // Load heater status
      final heaterStatus = await _supabase
          .from('heater_status')
          .select('status_id, status')
          .order('status_id', ascending: false)
          .limit(1)
          .maybeSingle();

      if (mounted) {
        setState(() {
          if (settings != null) {
            _minTemp =
                double.tryParse(settings['min_temperature']?.toString() ?? '0');
            _maxTemp =
                double.tryParse(settings['max_temperature']?.toString() ?? '0');
          }

          if (sensorData != null) {
            _currentTemp =
                double.tryParse(sensorData['suhu_air']?.toString() ?? '0');
          } else {
            // Generate initial random temperature if no data exists
            _currentTemp = double.parse(
                (20 + (Random().nextDouble() * 15)).toStringAsFixed(1));
          }

          if (heaterStatus != null) {
            // Convert status string to boolean
            _isHeaterOn =
                heaterStatus['status']?.toString().toUpperCase() == 'ON';
            _currentHeaterStatusId =
                int.tryParse(heaterStatus['status_id']?.toString() ?? '0');
          } else {
            // Set default status if no data exists
            _isHeaterOn = false;
            _currentHeaterStatusId = null;
          }

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('Error loading initial data: $e');
    }
  }

  List<Map<String, dynamic>> _generateRandomHistory() {
    final List<Map<String, dynamic>> history = [];
    final endDate = DateTime.now();
    final startDate = endDate.subtract(const Duration(days: 7));
    final validUserIds = [1, 2, 3]; // Hanya user ID 1, 2, dan 3

    // Generate one record per day at 12:00
    for (var i = 0; i < 7; i++) {
      final currentDate = startDate.add(Duration(days: i));
      final recordDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        12, // Set to noon
        0,
      );

      history.add({
        'riwayat_id': _random.nextInt(1000000),
        'user_id': validUserIds[_random
            .nextInt(validUserIds.length)], // Pilih dari user ID yang valid
        'status_id': _random.nextInt(3) + 1,
        'tanggal': recordDate.toIso8601String(),
        'total_waktu_menyala': _random.nextInt(180) + 30, // 30-210 minutes
      });
    }

    // Sort by date ascending for chart
    history.sort((a, b) =>
        DateTime.parse(a['tanggal']).compareTo(DateTime.parse(b['tanggal'])));

    return history;
  }

  Future<void> _loadHeaterHistory() async {
    setState(() => _isLoading = true);

    try {
      // Generate random data instead of fetching from Supabase
      final randomHistory = _generateRandomHistory();

      // Process data for chart
      _chartData = [];
      _maxY = 0;
      for (var i = 0; i < randomHistory.length; i++) {
        final item = randomHistory[i];
        final minutes = item['total_waktu_menyala'] ?? 0;
        _chartData.add(FlSpot(i.toDouble(), minutes.toDouble()));
        if (minutes > _maxY) _maxY = minutes.toDouble();
      }

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
        _chartData = [];
        _maxY = 0;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getTemperatureStatus(double temp) {
    if (_minTemp == null || _maxTemp == null) return 'Tidak diketahui';
    if (temp < _minTemp!) return 'Terlalu Dingin';
    if (temp > _maxTemp!) return 'Terlalu Panas';
    return 'Normal';
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Terlalu Dingin':
        return Colors.blue;
      case 'Terlalu Panas':
        return Colors.red;
      case 'Normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _toggleHeaterStatus() async {
    try {
      final newStatus = !_isHeaterOn;

      if (_currentHeaterStatusId == null) {
        // If no status exists, create new one
        final response = await _supabase
            .from('heater_status')
            .insert({
              'status': newStatus ? 'ON' : 'OFF',
              'sensor_id': null,
            })
            .select()
            .single();

        _currentHeaterStatusId = response['status_id'];
      } else {
        // Update existing status
        await _supabase.from('heater_status').update({
          'status': newStatus ? 'ON' : 'OFF',
        }).eq('status_id', _currentHeaterStatusId!);
      }

      if (mounted) {
        setState(() {
          _isHeaterOn = newStatus;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Status pemanas berhasil diubah ke ${newStatus ? 'ON' : 'OFF'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error toggling heater status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status pemanas: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Statistik Penggunaan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '7 Hari Terakhir',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: true,
                  drawHorizontalLine: true,
                  horizontalInterval: 60, // Interval 60 menit
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                  getDrawingVerticalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withOpacity(0.2),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Jam',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 60,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          (value / 60).toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        );
                      },
                      reservedSize: 35,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    axisNameWidget: const Text(
                      'Tanggal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _heaterHistory.length) {
                          return const Text('');
                        }
                        final date = DateTime.parse(
                            _heaterHistory[value.toInt()]['tanggal']);
                        return Transform.rotate(
                          angle: -0.5, // Rotasi 30 derajat
                          child: Text(
                            DateFormat('d/M').format(date),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                      reservedSize: 32,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: Colors.blue,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.withOpacity(0.3),
                          Colors.blue.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minY: 0,
                maxY: _maxY + (_maxY * 0.1),
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.all(8),
                    tooltipBorder: const BorderSide(
                      color: Colors.blueAccent,
                      width: 1,
                    ),
                    getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                      return touchedBarSpots.map((barSpot) {
                        final date = DateTime.parse(
                            _heaterHistory[barSpot.x.toInt()]['tanggal']);
                        final minutes = barSpot.y.toInt();
                        final hours = (minutes / 60).floor();
                        final remainingMinutes = minutes % 60;
                        return LineTooltipItem(
                          '${DateFormat('dd/MM').format(date)}\n${hours}j ${remainingMinutes}m',
                          const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                  handleBuiltInTouches: true,
                  getTouchedSpotIndicator:
                      (LineChartBarData barData, List<int> spotIndexes) {
                    return spotIndexes.map((spotIndex) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.blue.withOpacity(0.3),
                          strokeWidth: 2,
                          dashArray: [5, 5],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 6,
                              color: Colors.white,
                              strokeWidth: 3,
                              strokeColor: Colors.blue,
                            );
                          },
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Image.asset('assets/icons/logo.png', height: 55),
                      const SizedBox(width: 8),
                      const Text(
                        'AQUATEMP',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            fontFamily: 'Magilio'),
                      ),
                    ],
                  ),
                  const CircleAvatar(
                    radius: 20,
                    backgroundImage: AssetImage('assets/images/milos.webp'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : StreamBuilder<List<Map<String, dynamic>>>(
                      stream: _tempSettingsStream,
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final settings = snapshot.data!.first;
                          _minTemp = double.tryParse(
                              settings['min_temperature']?.toString() ?? '0');
                          _maxTemp = double.tryParse(
                              settings['max_temperature']?.toString() ?? '0');
                        }

                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Row(
                                          children: [
                                            Icon(Icons.water_drop),
                                            SizedBox(width: 8),
                                            Text(
                                              'Suhu Air',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_currentTemp?.toStringAsFixed(1) ?? '-'}°C',
                                          style: const TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _currentTemp != null
                                              ? _getTemperatureStatus(
                                                  _currentTemp!)
                                              : 'Tidak diketahui',
                                          style: TextStyle(
                                            color: _currentTemp != null
                                                ? _getStatusColor(
                                                    _getTemperatureStatus(
                                                        _currentTemp!))
                                                : Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          height: 30,
                                          decoration: BoxDecoration(
                                            color: _currentTemp != null
                                                ? _getStatusColor(
                                                        _getTemperatureStatus(
                                                            _currentTemp!))
                                                    .withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  width: 140,
                                  height: 140,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(
                                        children: [
                                          Icon(Icons.memory),
                                          SizedBox(width: 4),
                                          Text('Pemanas'),
                                        ],
                                      ),
                                      const Spacer(),
                                      const Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: GestureDetector(
                                              onTap: _toggleHeaterStatus,
                                              child: Container(
                                                height: 30,
                                                decoration: BoxDecoration(
                                                  color: _isHeaterOn
                                                      ? Colors.green
                                                      : Colors.red,
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                ),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _isHeaterOn ? 'ON' : 'OFF',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.show_chart),
                                      SizedBox(width: 8),
                                      Text('Batas Suhu',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [
                                          Colors.blue,
                                          Colors.purple,
                                          Colors.red
                                        ],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: Text(
                                            '${_minTemp?.toStringAsFixed(1) ?? '-'}°C',
                                            style: const TextStyle(
                                                fontSize: 22,
                                                color: Colors.white),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12.0),
                                          child: Text(
                                            '${_maxTemp?.toStringAsFixed(1) ?? '-'}°C',
                                            style: const TextStyle(
                                                fontSize: 22,
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _heaterHistory.isNotEmpty
                                ? _buildStatisticsCard()
                                : const SizedBox(),
                          ],
                        );
                      }),
            ],
          ),
        ),
      ),
    );
  }
}
