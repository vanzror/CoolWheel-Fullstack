import 'package:flutter/material.dart';
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
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            widget.calendarKey?.currentState?.refreshCalendar();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  getGreeting(),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E2641),
                  ),
                ),
                const SizedBox(height: 24),
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
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                const LocationMap(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


