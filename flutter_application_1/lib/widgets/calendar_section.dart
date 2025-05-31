import 'package:flutter/material.dart';
import '../pages/my_activities_page.dart'; // pastikan file ini ada
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarSection extends StatefulWidget {
  final String selectedMonth;
  final int year;

  const CalendarSection({
    super.key,
    required this.selectedMonth,
    required this.year,
  });

  @override
  CalendarSectionState createState() => CalendarSectionState();
}

class CalendarSectionState extends State<CalendarSection> {
  Future<Set<int>> cyclingDaysFuture = Future.value({});

  void refreshCalendar() {
    setState(() {
      cyclingDaysFuture = fetchCyclingDays();
    });
  }

  @override
  void initState() {
    super.initState();
    cyclingDaysFuture = fetchCyclingDays().then((days) {
      return days;
    }).catchError((e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal fetch data history!')),
        );
      });
      return <int>{};
    });
  }

  Future<Set<int>> fetchCyclingDays() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return {};
    final api = ApiService();
    final response = await api.getAvailableDateHistory(token);
    print('API response: ' + response.body);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List dates = data['available_dates'] ?? [];
      final Set<int> days = {};
      for (final dateStr in dates) {
        try {
          final date = DateTime.parse(dateStr);
          print('Parsed date: ' + date.toIso8601String());
          if (date.year == widget.year &&
              date.month == _getMonthIndex(widget.selectedMonth)) {
            days.add(date.day);
          }
        } catch (e) {
          print('Parse error: $e');
        }
      }
      print('Cycling days for month: $days');
      return days;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final monthIndex = _getMonthIndex(widget.selectedMonth);
    final firstDayOfMonth = DateTime(widget.year, monthIndex, 1);
    final nextMonth = (monthIndex == 12)
        ? DateTime(widget.year + 1, 1, 1)
        : DateTime(widget.year, monthIndex + 1, 1);
    final totalDays = nextMonth.difference(firstDayOfMonth).inDays;
    final startOffset = (firstDayOfMonth.weekday + 6) % 7;
    const totalCells = 35;

    return FutureBuilder<Set<int>>(
      future: cyclingDaysFuture,
      builder: (context, snapshot) {
        final cyclingDays = snapshot.data ?? {};

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label hari
            Row(
              children: dayLabels
                  .map(
                    (label) => Expanded(
                      child: Center(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),

            // Grid tanggal
            GridView.builder(
              shrinkWrap: true,
              itemCount: totalCells,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - startOffset + 1;

                if (index < startOffset || dayNumber > totalDays) {
                  return const SizedBox(); // Sel kosong
                }

                final today = DateTime.now();
                final isToday = today.year == widget.year &&
                    today.month == monthIndex &&
                    today.day == dayNumber;

                final isCyclingDay = cyclingDays.contains(dayNumber);
                Color bgColor = Colors.white;

                if (isToday) {
                  bgColor = Colors.black;
                } else if (isCyclingDay) {
                  bgColor = Colors.blue;
                }

                BoxDecoration boxDecoration;
                if (isToday && isCyclingDay) {
                  boxDecoration = BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue, width: 3),
                  );
                } else {
                  boxDecoration = BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  );
                }
                return GestureDetector(
                  onTap: (isCyclingDay)
                      ? () {
                          final selectedDate =
                              DateTime(widget.year, monthIndex, dayNumber);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MyActivitiesPage(selectedDate: selectedDate),
                            ),
                          );
                        }
                      : null, // Tidak bisa diklik jika bukan hari cycling
                  child: Container(
                    alignment: Alignment.center,
                    decoration: boxDecoration,
                    child: Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: (isToday || isCyclingDay)
                            ? Colors.white
                            : Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),

            // Legenda
            const Row(
              children: [
                Icon(Icons.circle, size: 10, color: Colors.black),
                SizedBox(width: 4),
                Text("Today"),
                SizedBox(width: 16),
                Icon(Icons.circle, size: 10, color: Colors.blue),
                SizedBox(width: 4),
                Text("Cycling"),
              ],
            ),
          ],
        );
      },
    );
  }

  int _getMonthIndex(String month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months.indexOf(month) + 1;
  }
}
