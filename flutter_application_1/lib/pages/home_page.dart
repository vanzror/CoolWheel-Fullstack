import 'package:flutter/material.dart';
import '../widgets/calendar_section.dart';
import '../widgets/location_map.dart';
import 'tracker_page.dart'; // Import halaman tracker

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedMonth = 'April';
  int _selectedIndex = 0;

  final List<String> months = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December'
  ];

  void _onItemTapped(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TrackerPage()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Selamat pagi, User!';
    } else if (hour < 17) {
      return 'Selamat siang, User!';
    } else if (hour < 20) {
      return 'Selamat sore, User!';
    } else {
      return 'Selamat malam, User!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Greeting section
              Text(
                getGreeting(),
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2641),
                ),
              ),

              const SizedBox(height: 24),
              Row(
                children: [
                  const Text("My Activities",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  DropdownButton<String>(
                    value: selectedMonth,
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedMonth = newValue!;
                      });
                    },
                    items: months.map<DropdownMenuItem<String>>((String month) {
                      return DropdownMenuItem<String>(
                        value: month,
                        child: Text(month),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CalendarSection(selectedMonth: selectedMonth, year: 2025),
              const SizedBox(height: 24),
              const Text("Bike Location",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              const LocationMap(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
