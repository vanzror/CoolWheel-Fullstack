import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MyActivitiesPage extends StatelessWidget {
  final DateTime selectedDate;

  const MyActivitiesPage({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context) {
    final dateFormatted = DateFormat('d MMMM yyyy').format(selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back Button
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => Navigator.pop(context),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          dateFormatted,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Statistic Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  _StatCard(title: 'Heart', value: '80', unit: 'BPM', icon: Icons.monitor_heart),
                  _StatCard(title: 'Distance', value: '10.5', unit: 'km', icon: Icons.directions_bike),
                  _StatCard(title: 'Duration', value: '10 h 50', unit: 'min', icon: Icons.av_timer),
                  _StatCard(title: 'Calories', value: '999', unit: 'kcal', icon: Icons.local_fire_department),
                ],
              ),

              const SizedBox(height: 24),

              // Activity List
              const _ActivityTile(),
              const SizedBox(height: 12),
              const _ActivityTile(),
            ],
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
  const _ActivityTile();

  @override
  Widget build(BuildContext context) {
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
              children: const [
                Text(
                  'Biking to Keputih',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.local_fire_department, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('241 kkal', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 12),
                    Icon(Icons.calendar_month, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text('3d ago', style: TextStyle(color: Colors.grey)),
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
