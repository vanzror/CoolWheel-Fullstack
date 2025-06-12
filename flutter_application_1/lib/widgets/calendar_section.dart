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
    print('API response: ${response.body}');
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
        // Ultra compact header - no padding, no background, no border
        Row(
          children: [
            const Text("My Activities",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const Spacer(),
            // Compact navigation controls
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous month
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        bottomLeft: Radius.circular(8),
                      ),
                      onTap: () {
                        int monthIdx = months.indexOf(widget.selectedMonth);
                        int year = widget.year;
                        if (monthIdx == 0) {
                          monthIdx = 11;
                          year -= 1;
                        } else {
                          monthIdx -= 1;
                        }
                        if (widget.onMonthChanged != null) {
                          widget.onMonthChanged!(months[monthIdx]);
                        }
                        if (widget.onYearChanged != null &&
                            year != widget.year) {
                          widget.onYearChanged!(year);
                        }
              },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.chevron_left, size: 20),
                      ),
                    ),
                  ),
                  // Month/Year selector
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () async {
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
                          if (widget.onYearChanged != null &&
                              newYear != widget.year) {
                            widget.onYearChanged!(newYear);
                          }
                        }
              },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${widget.selectedMonth.substring(0, 3)} ${widget.year}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.expand_more, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Next month
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(8),
                        bottomRight: Radius.circular(8),
                      ),
                      onTap: () {
                        int monthIdx = months.indexOf(widget.selectedMonth);
                        int year = widget.year;
                        if (monthIdx == 11) {
                          monthIdx = 0;
                          year += 1;
                        } else {
                          monthIdx += 1;
                        }
                        if (widget.onMonthChanged != null) {
                          widget.onMonthChanged!(months[monthIdx]);
                        }
                        if (widget.onYearChanged != null &&
                            year != widget.year) {
                          widget.onYearChanged!(year);
                        }
              },
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(Icons.chevron_right, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            // Simple refresh button
            InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: () {
                refreshCalendar();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Calendar content centered
        Center(
          child: Column(
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
              const SizedBox(height: 4),
              // Grid tanggal with swipe gesture
              FutureBuilder<Set<int>>(
                future: cyclingDaysFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Failed to load calendar data.'));
                  }

                  final cyclingDays = snapshot.data ?? {};
                  return GestureDetector(
                    onHorizontalDragEnd: (DragEndDetails details) {
                      // Swipe right (previous month)
                      if (details.primaryVelocity! > 0) {
                        _navigateToPreviousMonth();
                      }
                      // Swipe left (next month)
                      else if (details.primaryVelocity! < 0) {
                        _navigateToNextMonth();
                      }
                    },
                    child: GridView.builder(
              shrinkWrap: true,
              itemCount: totalCells,
              physics: const NeverScrollableScrollPhysics(),
                      padding: EdgeInsets.zero,
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
                          bgColor = const Color(0xFF0F67FE);
                        }

                        BoxDecoration boxDecoration;
                        if (isToday && isCyclingDay) {
                          boxDecoration = BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: const Color(0xFF0F67FE), width: 3),
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
                                  final selectedDate = DateTime(
                                      widget.year, monthIndex, dayNumber);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MyActivitiesPage(
                                          selectedDate: selectedDate),
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
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend centered
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text("Today", style: TextStyle(fontSize: 12)),
              const SizedBox(width: 16),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F67FE),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              const Text("Cycling", style: TextStyle(fontSize: 12)),
            ],
          ),
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

  void _navigateToPreviousMonth() {
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

    int monthIdx = months.indexOf(widget.selectedMonth);
    int year = widget.year;

    if (monthIdx == 0) {
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
  }

  void _navigateToNextMonth() {
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

    int monthIdx = months.indexOf(widget.selectedMonth);
    int year = widget.year;

    if (monthIdx == 11) {
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
    const minYear = 2000;
    final maxYear = currentYear + 10;

    final years =
        List.generate(maxYear - minYear + 1, (index) => minYear + index);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 320,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F67FE).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: Color(0xFF0F67FE),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Select Date',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.black54,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Month Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Month',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMonth,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF0F67FE)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedMonth = newValue;
                          });
                        }
                      },
                      items:
                          months.map<DropdownMenuItem<String>>((String month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Year Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Year',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: selectedYear,
                      icon: const Icon(Icons.keyboard_arrow_down,
                          color: Color(0xFF0F67FE)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      onChanged: (int? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedYear = newValue;
                          });
                        }
                      },
                      items: years.map<DropdownMenuItem<int>>((int year) {
                        return DropdownMenuItem<int>(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Selected Preview
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F67FE).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0F67FE).withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Color(0xFF0F67FE),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$selectedMonth $selectedYear',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F67FE),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'month': selectedMonth,
                    'year': selectedYear,
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F67FE),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Apply Selection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
