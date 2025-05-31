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
  late Future<List<Map<String, dynamic>>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = fetchHistory();
  }

  Future<List<Map<String, dynamic>>> fetchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final api = ApiService();
    final dateStr = DateFormat('yyyy-MM-dd').format(widget.selectedDate);
    final response = await api.getHistoryByDate(dateStr, token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List history = data['history_by_date'] ?? [];
      return List<Map<String, dynamic>>.from(history);
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMMM yyyy').format(widget.selectedDate);
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
              final main = history[0];
              final others = history.length > 1 ? history.sublist(1) : [];
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back Button
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new),
                      onPressed: () {
                        Navigator.of(context)
                            .pushNamedAndRemoveUntil('/main', (route) => false);
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
                                  initialDate: widget.selectedDate,
                                  onDateSelected: (picked) {
                                    Navigator.of(context).pop(picked);
                                  },
                                ),
                              );
                              if (picked != null &&
                                  picked != widget.selectedDate) {
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        MyActivitiesPage(selectedDate: picked),
                                  ),
                                );
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
                          'Last Activity: ${main['started_at'] != null && main['started_at'].toString().isNotEmpty ? DateFormat('d MMM yyyy, HH:mm').format(DateTime.tryParse(main['started_at'].toString().replaceFirst('T', ' ')) ?? DateTime.now()) : '-'}',
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
                            value: main['highest_heartrate'].toString(),
                            unit: 'BPM',
                            icon: Icons.monitor_heart),
                        _StatCard(
                            title: 'Distance',
                            value: main['total_distance'].toString(),
                            unit: 'km',
                            icon: Icons.directions_bike),
                        _StatCard(
                            title: 'Duration',
                            value: main['duration_minutes'].toString(),
                            unit: 'min',
                            icon: Icons.av_timer),
                        _StatCard(
                            title: 'Calories',
                            value: main['total_calories'].toString(),
                            unit: 'kcal',
                            icon: Icons.local_fire_department),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Activity List
                    ...others.map((item) => _ActivityTile(item: item)).toList(),
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
      // yyyy-MM-ddTHH:mm:ss or yyyy-MM-dd HH:mm:ss
      final dt = DateTime.tryParse(startedAt.replaceFirst('T', ' '));
      if (dt != null) {
        dateTimeStr = DateFormat('d MMM yyyy, HH:mm').format(dt);
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
