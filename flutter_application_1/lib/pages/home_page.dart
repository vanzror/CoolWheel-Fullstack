import 'package:flutter/material.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:iconify_flutter/icons/icon_park_twotone.dart';
import '../widgets/calendar_section.dart';
import '../widgets/location_map.dart';
import '../user_data.dart';

class HomePage extends StatefulWidget {
  final GlobalKey<CalendarSectionState>? calendarKey;

  const HomePage({super.key, this.calendarKey});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String selectedMonth = months[DateTime.now().month - 1];
  late int selectedYear = DateTime.now().year;

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
  String getGreeting() {
    final hour = DateTime.now().hour;
    final userName =
        UserData().fullName.isNotEmpty ? UserData().fullName : 'User';
    if (hour < 12) {
      return 'Selamat pagi, $userName!';
    } else if (hour < 17) {
      return 'Selamat siang, $userName!';
    } else if (hour < 20) {
      return 'Selamat sore, $userName!';
    } else {
      return 'Selamat malam, $userName!';
    }
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthsShort = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    final dayName = days[now.weekday - 1];
    final day = now.day;
    final month = monthsShort[now.month - 1];
    final year = now.year;

    return '$dayName, $day $month $year';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: Stack(
        children: [
          // Main content with padding top to avoid header overlap
          Padding(
            padding: const EdgeInsets.only(top: 136), // Reduced from 120 to 110
            child: RefreshIndicator(
              onRefresh: () async {
                widget.calendarKey?.currentState?.refreshCalendar();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CalendarSection(
                        key: widget.calendarKey,
                        selectedMonth: selectedMonth,
                        year: selectedYear,
                        onMonthChanged: (newMonth) async {
                          setState(() {
                            selectedMonth = newMonth;
                          });
                        },
                        onYearChanged: (newYear) {
                          setState(() {
                            selectedYear = newYear;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      const Text("Bike Location",
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const LocationMap(),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Add alarm functionality
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF242E49),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Iconify(
                                IconParkTwotone.alarm,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Play Buzzer',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Fixed header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(
                  24, 52, 32, 20), // Reduced bottom padding from 24 to 20
              decoration: const BoxDecoration(
                color: Color(0xFF242E49),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Iconify(
                        MaterialSymbols.calendar_today,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6), // Reduced from 8 to 6
                  Text(
                    getGreeting(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
