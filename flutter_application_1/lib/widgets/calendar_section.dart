import 'package:flutter/material.dart';
import '../pages/my_activities_page.dart'; // pastikan file ini ada
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CalendarSection extends StatefulWidget {
  final String selectedMonth;
  final int year;
  final ValueChanged<String>? onMonthChanged;
  final ValueChanged<int>? onYearChanged;

  const CalendarSection({
    super.key,
    required this.selectedMonth,
    required this.year,
    this.onMonthChanged,
    this.onYearChanged,
  });

  @override
  CalendarSectionState createState() => CalendarSectionState();
}

class CalendarSectionState extends State<CalendarSection> {
  Future<Set<int>> cyclingDaysFuture = Future.value({});
  late List<DateTime> availableDates = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshCalendar();
    });
  }

  void refreshCalendar() {
    setState(() {
      cyclingDaysFuture = fetchCyclingDays();
    });
  }

  void forceRefresh() {
    refreshCalendar();
  }

  @override
  void didUpdateWidget(covariant CalendarSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedMonth != widget.selectedMonth ||
        oldWidget.year != widget.year) {
      refreshCalendar();
    }
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
      availableDates =
          dates.map<DateTime>((dateStr) => DateTime.parse(dateStr)).toList();
      final Set<int> days = {};
      for (final date in availableDates) {
        if (date.year == widget.year &&
            date.month == _getMonthIndex(widget.selectedMonth)) {
          days.add(date.day);
        }
      }
      print('Cycling days for month: $days');
      return days;
    }
    availableDates = [];
    return {};
  }

  final List<String> months = [
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
    final totalCells = ((startOffset + totalDays) / 7).ceil() * 7;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("My Activities",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            // Panah kiri
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
              onPressed: () {
                int monthIdx = months.indexOf(widget.selectedMonth);
                int year = widget.year;
                if (monthIdx == 0) {
                  // Januari -> Desember tahun sebelumnya
                  monthIdx = 11;
                  year -= 1;
                } else {
                  monthIdx -= 1;
                }
                if (widget.onMonthChanged != null) {
                  widget.onMonthChanged!(months[monthIdx]);
                }
                if (widget.onYearChanged != null && year != widget.year) {
                  widget.onYearChanged!(year);
                }
              },
            ),
            // Tombol bulan-tahun
            TextButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text('${widget.selectedMonth} ${widget.year}'),
              onPressed: () async {
                final result = await showDialog<Map<String, dynamic>>(
                  context: context,
                  builder: (context) => _MonthYearPickerDialog(
                    initialMonth: widget.selectedMonth,
                    initialYear: widget.year,
                  ),
                );
                if (result != null) {
                  final newMonth = result['month'] as String;
                  final newYear = result['year'] as int;
                  if (widget.onMonthChanged != null) {
                    widget.onMonthChanged!(newMonth);
                  }
                  if (widget.onYearChanged != null && newYear != widget.year) {
                    widget.onYearChanged!(newYear);
                  }
                }
              },
            ),
            // Panah kanan
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
              onPressed: () {
                int monthIdx = months.indexOf(widget.selectedMonth);
                int year = widget.year;
                if (monthIdx == 11) {
                  // Desember -> Januari tahun berikutnya
                  monthIdx = 0;
                  year += 1;
                } else {
                  monthIdx += 1;
                }
                if (widget.onMonthChanged != null) {
                  widget.onMonthChanged!(months[monthIdx]);
                }
                if (widget.onYearChanged != null && year != widget.year) {
                  widget.onYearChanged!(year);
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh calendar',
              onPressed: () {
                refreshCalendar();
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

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
        FutureBuilder<Set<int>>(
          future: cyclingDaysFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(child: Text('Failed to load calendar data.'));
            }

            final cyclingDays = snapshot.data ?? {};

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

// Tambahkan di bawah kelas CalendarSectionState:
class _MonthYearPickerDialog extends StatefulWidget {
  final String initialMonth;
  final int initialYear;
  const _MonthYearPickerDialog({
    required this.initialMonth,
    required this.initialYear,
  });
  @override
  State<_MonthYearPickerDialog> createState() => _MonthYearPickerDialogState();
}

class _MonthYearPickerDialogState extends State<_MonthYearPickerDialog> {
  late String selectedMonth;
  late int selectedYear;
  final List<String> months = [
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
  @override
  void initState() {
    super.initState();
    selectedMonth = widget.initialMonth;
    selectedYear = widget.initialYear;
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final minYear = 2000;
    final maxYear = currentYear + 5;
    return AlertDialog(
      title: const Text('Choose Month & Year'),
      content: Row(
        children: [
          // Month picker
          Expanded(
            child: DropdownButton<String>(
              value: selectedMonth,
              isExpanded: true,
              onChanged: (val) {
                if (val != null) setState(() => selectedMonth = val);
              },
              items: months
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
            ),
          ),
          const SizedBox(width: 12),
          // Year picker
          Expanded(
            child: DropdownButton<int>(
              value: selectedYear,
              isExpanded: true,
              onChanged: (val) {
                if (val != null) setState(() => selectedYear = val);
              },
              items: List.generate(maxYear - minYear + 1, (i) => minYear + i)
                  .map((y) =>
                      DropdownMenuItem(value: y, child: Text(y.toString())))
                  .toList(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context)
                .pop({'month': selectedMonth, 'year': selectedYear});
          },
          child: const Text('OK'),
        ),
      ],
    );
  }
}
