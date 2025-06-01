import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'dart:convert';

class CalendarDialog extends StatefulWidget {
  final DateTime initialDate;
  final Function(DateTime) onDateSelected;

  const CalendarDialog({
    super.key,
    required this.initialDate,
    required this.onDateSelected,
  });

  @override
  State<CalendarDialog> createState() => _CalendarDialogState();
}

class _CalendarDialogState extends State<CalendarDialog> {
  late int year;
  late int month;
  late Future<Set<int>> cyclingDaysFuture;
  late List<DateTime> availableDates = [];

  @override
  void initState() {
    super.initState();
    year = widget.initialDate.year;
    month = widget.initialDate.month;
    cyclingDaysFuture = fetchCyclingDays();
  }

  Future<Set<int>> fetchCyclingDays() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) return {};
    final api = ApiService();
    final response = await api.getAvailableDateHistory(token);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List dates = data['available_dates'] ?? [];
      availableDates =
          dates.map<DateTime>((dateStr) => DateTime.parse(dateStr)).toList();
      final Set<int> days = {};
      for (final date in availableDates) {
        if (date.year == year && date.month == month) {
          days.add(date.day);
        }
      }
      return days;
    }
    availableDates = [];
    return {};
  }

  void _changeMonth(int delta) {
    setState(() {
      final newDate = DateTime(year, month + delta, 1);
      year = newDate.year;
      month = newDate.month;
      cyclingDaysFuture = fetchCyclingDays(); // Always fetch again
    });
  }

  @override
  Widget build(BuildContext context) {
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final firstDayOfMonth = DateTime(year, month, 1);
    final nextMonth =
        (month == 12) ? DateTime(year + 1, 1, 1) : DateTime(year, month + 1, 1);
    final totalDays = nextMonth.difference(firstDayOfMonth).inDays;
    final startOffset = (firstDayOfMonth.weekday + 6) % 7;
    const totalCells = 35;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  '${_monthName(month)} $year',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: dayLabels
                  .map((label) => Expanded(
                        child: Center(
                          child: Text(
                            label,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
            FutureBuilder<Set<int>>(
              future: cyclingDaysFuture,
              builder: (context, snapshot) {
                return GridView.builder(
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
                      return const SizedBox();
                    }
                    final today = DateTime.now();
                    final isToday = today.year == year &&
                        today.month == month &&
                        today.day == dayNumber;
                    // Only mark as cycling if availableDates contains this exact date
                    final isCyclingDay = availableDates.any((d) =>
                        d.year == year &&
                        d.month == month &&
                        d.day == dayNumber);
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
                      onTap: isCyclingDay
                          ? () {
                              final selectedDate =
                                  DateTime(year, month, dayNumber);
                              Navigator.of(context).pop(selectedDate);
                            }
                          : null,
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
                );
              },
            ),
            const SizedBox(height: 8),
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
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
