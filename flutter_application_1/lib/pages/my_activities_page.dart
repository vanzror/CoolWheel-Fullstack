// ignore_for_file: unused_local_variable

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/calendar_dialog.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/tabler.dart';
import 'activity_detail_page.dart';

class MyActivitiesPage extends StatefulWidget {
  final DateTime selectedDate;

  const MyActivitiesPage({super.key, required this.selectedDate});

  @override
  State<MyActivitiesPage> createState() => _MyActivitiesPageState();
}

class _MyActivitiesPageState extends State<MyActivitiesPage> {
  late DateTime selectedDate;
  late Future<List<Map<String, dynamic>>> historyFuture;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    selectedDate = widget.selectedDate;
    historyFuture = fetchHistoryForDate(selectedDate);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    const double threshold = 50.0;
    final bool isScrolled =
        _scrollController.hasClients && _scrollController.offset > threshold;

    if (isScrolled != _isScrolled) {
      setState(() {
        _isScrolled = isScrolled;
      });
    }
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
      body: NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scrollInfo) {
          const double threshold = 30.0;
          final bool isScrolled = scrollInfo.metrics.pixels > threshold;

          if (isScrolled != _isScrolled) {
            setState(() {
              _isScrolled = isScrolled;
            });
          }
          return false;
        },
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
              return CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildSliverAppBar(dateFormatted),
                  const SliverFillRemaining(
                    child: Center(child: Text('No activity found')),
                  ),
                ],
              );
            }
            return _buildContentWithData(history, dateFormatted);
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(String dateFormatted) {
    return SliverAppBar(
      expandedHeight: 120.0,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shadowColor: Colors.grey.withOpacity(0.1),
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
        onPressed: () => Navigator.of(context).pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: const Color(0xFFF5F7FA),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Activity History',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF242E49),
                borderRadius: BorderRadius.circular(8),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
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
                      historyFuture = fetchHistoryForDate(selectedDate);
                    });
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        titlePadding: EdgeInsets.only(
          left: _isScrolled ? 50 : 20,
          right: 20,
          bottom: 16,
        ),
        expandedTitleScale: 1.2,
      ),
    );
  }

  Widget _buildContentWithData(
      List<Map<String, dynamic>> history, String dateFormatted) {
    // Akumulasi/average statistik
    num totalHeart = 0;
    num totalDistance = 0;
    num totalDuration = 0;
    num totalCalories = 0;
    int count = history.length;
    for (final item in history) {
      totalHeart += num.tryParse(item['highest_heartrate'].toString()) ?? 0;
      totalDistance += num.tryParse(item['total_distance'].toString()) ?? 0;
      totalDuration += num.tryParse(item['duration_minutes'].toString()) ?? 0;
      totalCalories += num.tryParse(item['total_calories'].toString()) ?? 0;
    }
    final highestHeart = history.isNotEmpty
        ? history
            .map((item) =>
                num.tryParse(item['highest_heartrate'].toString()) ?? 0)
            .reduce((a, b) => a > b ? a : b)
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
        aDt = DateTime.tryParse(
                    a['started_at']?.toString().replaceFirst('T', ' ') ?? '')
                ?.toLocal() ??
            DateTime(1970, 1, 1);
      } catch (_) {
        aDt = DateTime(1970, 1, 1);
      }
      try {
        bDt = DateTime.tryParse(
                    b['started_at']?.toString().replaceFirst('T', ' ') ?? '')
                ?.toLocal() ??
            DateTime(1970, 1, 1);
      } catch (_) {
        bDt = DateTime(1970, 1, 1);
      }
      return bDt.compareTo(aDt);
    });
    final lastActivity = sortedHistory.isNotEmpty ? sortedHistory.first : null;

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        _buildSliverAppBar(dateFormatted),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Last Activity label
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
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
                        value: highestHeart.toStringAsFixed(0),
                        unit: 'BPM',
                        iconifyIcon: Tabler.activity_heartbeat,
                        color: Colors.red),
                    _StatCard(
                        title: 'Distance',
                        value: sumDistance,
                        unit: 'km',
                        iconifyIcon: MaterialSymbols.directions_bike,
                        color: Colors.blue),
                    _StatCard(
                        title: 'Duration',
                        value: sumDuration.toString(),
                        unit: 'min',
                        iconifyIcon: MaterialSymbols.av_timer,
                        color: Colors.green),
                    _StatCard(
                        title: 'Calories',
                        value: sumCalories.toString(),
                        unit: 'kcal',
                        iconifyIcon: MaterialSymbols.local_fire_department,
                        color: Colors.orange),
                  ],
                ),
                const SizedBox(height: 24),

                // Activity List Header
                if (history.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Activities',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                
                // Activity List
                ...history.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ActivityTile(item: item),
                    )),

                // Add some bottom padding for the last item
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final String iconifyIcon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.iconifyIcon,
    required this.color,
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
              Iconify(iconifyIcon, color: color, size: 28),
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

class _ActivityTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _ActivityTile({required this.item});
  @override
  Widget build(BuildContext context) {
    final startedAt = item['started_at'] ?? '';
    final rideId = item['ride_id'] ?? 0;
    final calories = item['total_calories'] ?? '';
    final distance = item['total_distance'] ?? '';
    final duration = item['duration_minutes'] ?? '';
    final heartrate = item['highest_heartrate'] ?? '';
    
    // Format date+time with better handling
    String dateTimeStr = 'No date';
    if (startedAt.toString().isNotEmpty) {
      try {
        final dt =
            DateTime.tryParse(startedAt.toString().replaceFirst('T', ' '));
        if (dt != null) {
          final localDt = dt.toLocal();
          dateTimeStr = DateFormat('d MMM yyyy, HH:mm').format(localDt);
        }
      } catch (e) {
        dateTimeStr = startedAt.toString();
      }
    }
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ActivityDetailPage(activityData: item),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                color: Color(0xFF242E49),
                shape: BoxShape.circle,
              ),
              child: const Iconify(MaterialSymbols.directions_bike,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cycling',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateTimeStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  // Use Wrap to prevent overflow of statistics
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: [
                      _StatChip(
                        icon: Tabler.flame,
                        value:
                            '${calories.toString().isEmpty ? '0' : calories} kcal',
                      ),
                      _StatChip(
                        icon: MaterialSymbols.directions_bike,
                        value:
                            '${distance.toString().isEmpty ? '0' : distance} km',
                      ),
                      _StatChip(
                        icon: MaterialSymbols.av_timer,
                        value:
                            '${duration.toString().isEmpty ? '0' : duration} min',
                      ),
                      _StatChip(
                        icon: MaterialSymbols.monitor_heart,
                        value:
                            '${heartrate.toString().isEmpty ? '0' : heartrate} BPM',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Add arrow icon to indicate it's clickable
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;

  const _StatChip({
    required this.icon,
    required this.value,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
          maxWidth: 120), // Prevent chips from being too wide
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Iconify(icon, size: 14, color: Colors.grey),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
