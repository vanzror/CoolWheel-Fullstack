import 'package:flutter/material.dart';
import '../pages/my_activities_page.dart'; // pastikan file ini ada

class CalendarSection extends StatefulWidget {
  final String selectedMonth;
  final int year;

  const CalendarSection({
    super.key,
    required this.selectedMonth,
    required this.year,
  });

  @override
  State<CalendarSection> createState() => _CalendarSectionState();
}

class _CalendarSectionState extends State<CalendarSection> {
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

            final isCyclingDay = dayNumber == 15 || dayNumber == 16; // contoh kegiatan
            Color bgColor = Colors.white;

            if (isToday) {
              bgColor = Colors.black;
            } else if (isCyclingDay) {
              bgColor = Colors.blue;
            }

            return GestureDetector(
              onTap: () {
                final selectedDate = DateTime(widget.year, monthIndex, dayNumber);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MyActivitiesPage(selectedDate: selectedDate),
                  ),
                );
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$dayNumber',
                  style: TextStyle(
                    color: (isToday || isCyclingDay) ? Colors.white : Colors.black,
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
  }

  int _getMonthIndex(String month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months.indexOf(month) + 1;
  }
}
