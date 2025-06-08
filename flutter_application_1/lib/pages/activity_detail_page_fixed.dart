import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/tabler.dart';

class ActivityDetailPage extends StatefulWidget {
  final Map<String, dynamic> activityData;

  const ActivityDetailPage({super.key, required this.activityData});

  @override
  State<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends State<ActivityDetailPage> {
  late Future<List<Map<String, dynamic>>> heartRateDataFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    heartRateDataFuture = fetchHeartRateData();
  }

  Future<List<Map<String, dynamic>>> fetchHeartRateData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final rideId = widget.activityData['ride_id'].toString();

      final api = ApiService();
      final response = await api.getHeartRateDataByRideID(rideId, token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The API returns the heart rate data directly as an array
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          final List heartRateData = data['heartrate_data'] ?? [];
          return List<Map<String, dynamic>>.from(heartRateData);
        }
      } else {
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching heart rate data: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = widget.activityData['started_at'] ?? '';
    final rideId = widget.activityData['ride_id'] ?? 0;
    final calories = widget.activityData['total_calories'] ?? '';
    final distance = widget.activityData['total_distance'] ?? '';
    final duration = widget.activityData['duration_minutes'] ?? '';
    final heartrate = widget.activityData['highest_heartrate'] ?? '';

    // Format date+time
    String dateTimeStr = 'No date';
    if (startedAt.toString().isNotEmpty) {
      try {
        final dt =
            DateTime.tryParse(startedAt.toString().replaceFirst('T', ' '));
        if (dt != null) {
          final localDt = dt.toLocal();
          dateTimeStr = DateFormat('EEEE, d MMMM yyyy • HH:mm').format(localDt);
        }
      } catch (e) {
        dateTimeStr = startedAt.toString();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFF5F7FA),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Activity Details',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 50, bottom: 16),
              expandedTitleScale: 1.5,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Color(0xFF242E49),
                                shape: BoxShape.circle,
                              ),
                              child: const Iconify(
                                MaterialSymbols.directions_bike,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Cycling Activity',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateTimeStr,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Ride ID: $rideId',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Statistics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DetailStatCard(
                        title: 'Distance',
                        value: distance.toString().isEmpty
                            ? '0'
                            : distance.toString(),
                        unit: 'km',
                        icon: MaterialSymbols.directions_bike,
                      ),
                      _DetailStatCard(
                        title: 'Duration',
                        value: duration.toString().isEmpty
                            ? '0'
                            : duration.toString(),
                        unit: 'min',
                        icon: MaterialSymbols.av_timer,
                      ),
                      _DetailStatCard(
                        title: 'Calories',
                        value: calories.toString().isEmpty
                            ? '0'
                            : calories.toString(),
                        unit: 'kcal',
                        icon: MaterialSymbols.local_fire_department,
                      ),
                      _DetailStatCard(
                        title: 'Max Heart Rate',
                        value: heartrate.toString().isEmpty
                            ? '0'
                            : heartrate.toString(),
                        unit: 'BPM',
                        icon: Tabler.activity_heartbeat,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Heart Rate Chart Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 1,
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Iconify(
                              Tabler.activity_heartbeat,
                              color: Colors.red,
                              size: 24,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Heart Rate Chart',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 250,
                          child: FutureBuilder<List<Map<String, dynamic>>>(
                            future: heartRateDataFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError ||
                                  !snapshot.hasData ||
                                  snapshot.data!.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.heart_broken,
                                        size: 48,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No heart rate data available',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return _buildHeartRateChart(snapshot.data!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeartRateChart(List<Map<String, dynamic>> heartRateData) {
    if (heartRateData.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    // Convert data to FlSpot for the chart
    List<FlSpot> spots = [];
    for (int i = 0; i < heartRateData.length; i++) {
      final heartRate =
          double.tryParse(heartRateData[i]['bpm'].toString()) ?? 0;
      spots.add(FlSpot(i.toDouble(), heartRate));
    }

    if (spots.isEmpty) {
      return const Center(child: Text('No valid heart rate data'));
    }

    // Find min and max for better chart scaling
    double minY = spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b);
    double maxY = spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b);

    // Add some padding to min/max values
    minY = (minY - 10).clamp(0, double.infinity);
    maxY = maxY + 10;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          verticalInterval: spots.length > 10 ? spots.length / 5 : 1,
          horizontalInterval: (maxY - minY) / 5,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
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
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: spots.length > 10 ? spots.length / 5 : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 &&
                    value.toInt() < heartRateData.length) {
                  final timestamp = heartRateData[value.toInt()]['recorded_at'];
                  if (timestamp != null) {
                    try {
                      final dt = DateTime.parse(timestamp.toString());
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          DateFormat('HH:mm').format(dt.toLocal()),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      );
                    } catch (e) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                        ),
                      );
                    }
                  }
                }
                return const SideTitleWidget(
                  axisSide: AxisSide.bottom,
                  child: Text(''),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: (maxY - minY) / 5,
              reservedSize: 42,
              getTitlesWidget: (value, meta) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: minY,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: spots.length <= 20, // Only show dots if not too many points
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.red,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.red.withValues(alpha: 0.1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final dataIndex = barSpot.x.toInt();
                String timeStr = 'Point ${dataIndex + 1}';

                if (dataIndex >= 0 && dataIndex < heartRateData.length) {
                  final timestamp = heartRateData[dataIndex]['recorded_at'];
                  if (timestamp != null) {
                    try {
                      final dt = DateTime.parse(timestamp.toString());
                      timeStr = DateFormat('HH:mm:ss').format(dt.toLocal());
                    } catch (e) {
                      // Keep default time string
                    }
                  }
                }

                return LineTooltipItem(
                  '$timeStr\n${barSpot.y.toInt()} BPM',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }
}

class _DetailStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String icon;

  const _DetailStatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Top row: title (left) and icon (right)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1E1E1E),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Iconify(icon, color: Colors.grey[700], size: 28),
            ],
          ),
          const Spacer(),
          // Bottom left: value and unit
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF1E1E1E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
