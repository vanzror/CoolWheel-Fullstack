import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/calendar_dialog.dart';

class MyActivitiesPage extends StatefulWidget {
  final DateTime selectedDate;

  const MyActivitiesPage({super.key, required this.selectedDate});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> {
  late DateTime selectedDate;
  late Future<List<Map<String, dynamic>>> historyFuture;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    historyFuture = fetchHistoryForDate(selectedDate);
  }

  Future<List<Map<String, dynamic>>> fetchHistoryForDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final api = ApiService();
    final selectedDateLocal = date;
    final dateStr = DateFormat('yyyy-MM-dd').format(selectedDateLocal);
    final prevDateStr = DateFormat('yyyy-MM-dd')
        .format(selectedDateLocal.subtract(const Duration(days: 1)));
    final responses = await Future.wait([
      api.getHistoryByDate(dateStr, token),
      api.getHistoryByDate(prevDateStr, token),
    ]);
    List history = [];
    for (final response in responses) {
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List h = data['history_by_date'] ?? [];
        history.addAll(h);
      }
    }
    final filtered = history.where((item) {
      final startedAt = item['started_at']?.toString();
      if (startedAt == null || startedAt.isEmpty) return false;
      final dt = DateTime.tryParse(startedAt.replaceFirst('T', ' '));
      if (dt == null) return false;
      final localDt = dt.toLocal();
      return localDt.year == selectedDateLocal.year &&
          localDt.month == selectedDateLocal.month &&
          localDt.day == selectedDateLocal.day;
    }).toList();
    return List<Map<String, dynamic>>.from(filtered);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMMM yyyy').format(selectedDate);
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: historyFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading data'));
              }
              final history = snapshot.data ?? [];
              if (history.isEmpty) {
                return const Center(child: Text('No activity found'));
              }
              // Akumulasi/average statistik
              num totalHeart = 0;
              num totalDistance = 0;
              num totalDuration = 0;
              num totalCalories = 0;
              int count = history.length;
              for (final item in history) {
                totalHeart +=
                    num.tryParse(item['highest_heartrate'].toString()) ?? 0;
                totalDistance +=
                    num.tryParse(item['total_distance'].toString()) ?? 0;
                totalDuration +=
                    num.tryParse(item['duration_minutes'].toString()) ?? 0;
                totalCalories +=
                    num.tryParse(item['total_calories'].toString()) ?? 0;
              }
              final avgHeart = history.isNotEmpty
                  ? (totalHeart / history.length).round()
                  : 0;
              final sumDistance = totalDistance.toStringAsFixed(2);
              final sumDuration = totalDuration.round();
              final sumCalories = totalCalories.round();
              // Cari last activity (paling akhir berdasarkan started_at)
              final sortedHistory = [...history];
              sortedHistory.sort((a, b) {
                DateTime aDt;
                DateTime bDt;
                try {
                  aDt = DateTime.tryParse(a['started_at']
                                  ?.toString()
                                  .replaceFirst('T', ' ') ??
                              '')
                          ?.toLocal() ??
                      DateTime(1970, 1, 1);
                } catch (_) {
                  aDt = DateTime(1970, 1, 1);
                }
                try {
                  bDt = DateTime.tryParse(b['started_at']
                                  ?.toString()
                                  .replaceFirst('T', ' ') ??
                              '')
                          ?.toLocal() ??
                      DateTime(1970, 1, 1);
                } catch (_) {
                  bDt = DateTime(1970, 1, 1);
                }
                return bDt.compareTo(aDt);
              });
              final lastActivity =
                  sortedHistory.isNotEmpty ? sortedHistory.first : null;
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      // onPressed: () {
                      //   Navigator.of(context)
                      //       .pushNamedAndRemoveUntil('/main', (route) => false);
                      // },
                      onPressed: () {
                        // Navigator.of(context).pushNamedAndRemoveUntil('/main', (route) => false);
                        Navigator.of(context).pop(); // Coba pakai pop dulu
                      },
                    ),

                    const SizedBox(height: 8),

                    // Title and Date
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Activity History',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await showDialog<DateTime>(
                                context: context,
                                builder: (context) => CalendarDialog(
                                  initialDate: selectedDate,
                                  onDateSelected: (picked) {
                                    Navigator.of(context).pop(picked);
                                  },
                                ),
                              );
                              if (picked != null && picked != selectedDate) {
                                setState(() {
                                  selectedDate = picked;
                                  historyFuture =
                                      fetchHistoryForDate(selectedDate);
                                });
                              }
                            },
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  dateFormatted,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Last Activity label
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'Last Activity: '
                          '${lastActivity != null && lastActivity['started_at'] != null && lastActivity['started_at'].toString().isNotEmpty ? (() {
                              final raw = lastActivity['started_at']
                                  .toString()
                                  .replaceFirst('T', ' ');
                              final dt = DateTime.tryParse(raw);
                              if (dt != null) {
                                final localDt = dt.toLocal();
                                return DateFormat('d MMM yyyy, HH:mm:ss')
                                    .format(localDt);
                              }
                              return '-';
                            })() : '-'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Statistic Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatCard(
                            title: 'Heart',
                            value: avgHeart.toString(),
                            unit: 'BPM',
                            icon: Icons.monitor_heart),
                        _StatCard(
                            title: 'Distance',
                            value: sumDistance,
                            unit: 'km',
                            icon: Icons.directions_bike),
                        _StatCard(
                            title: 'Duration',
                            value: sumDuration.toString(),
                            unit: 'min',
                            icon: Icons.av_timer),
                        _StatCard(
                            title: 'Calories',
                            value: sumCalories.toString(),
                            unit: 'kcal',
                            icon: Icons.local_fire_department),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Activity List
                    ...history
                        .map((item) => _ActivityTile(item: item))
                        .toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _StatCard({
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.grey[700]),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final startedAt = item['started_at'] ?? '';
    final calories = item['total_calories'] ?? '';
    final distance = item['total_distance'] ?? '';
    final duration = item['duration_minutes'] ?? '';
    final heartrate = item['highest_heartrate'] ?? '';
    // Format date+time
    String dateTimeStr = startedAt;
    if (startedAt.length >= 16) {
      final dt = DateTime.tryParse(startedAt.replaceFirst('T', ' '));
      if (dt != null) {
        final localDt = dt.toLocal();
        dateTimeStr = DateFormat('d MMM yyyy, HH:mm:ss').format(localDt);
      }
    }
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFF1E2C5C),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.directions_bike, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cycling',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(dateTimeStr, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('$calories kkal',
                        style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 12),
                    Icon(Icons.directions_bike, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('$distance km', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 12),
                    Icon(Icons.av_timer, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('$duration min', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 12),
                    Icon(Icons.monitor_heart, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('$heartrate BPM',
                        style: TextStyle(color: Colors.grey)),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
