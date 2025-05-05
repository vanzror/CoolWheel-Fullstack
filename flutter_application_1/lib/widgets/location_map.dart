import 'package:flutter/material.dart';

class LocationMap extends StatelessWidget {
  const LocationMap({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: AssetImage('assets/map_placeholder.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
