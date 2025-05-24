import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

class TrackerPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const TrackerPage({super.key, this.onBackToHome});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  late GoogleMapController _mapController;
  LocationData? _currentLocation;
  final Location _location = Location();

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    final hasPermission = await _location.requestPermission();
    if (hasPermission == PermissionStatus.granted) {
      final loc = await _location.getLocation();
      setState(() {
        _currentLocation = loc;
      });
    } else {
      // Handle permission denial
      print("Location permission denied.");
    }
  }

  void _startTimer() {
    if (_isRunning) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedSeconds++;
      });
    });
    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() {
    if (!_isRunning) return;
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _currentLocation == null
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentLocation!.latitude!,
                      _currentLocation!.longitude!,
                    ),
                    zoom: 16,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios),
                              onPressed: () {
                                if (widget.onBackToHome != null) {
                                  widget.onBackToHome!();
                                } else {
                                  Navigator.pop(context);
                                }
                              },
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'Start Tracking',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 48), // To balance the back button width
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatElapsedTime(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TrackerStat(icon: Icons.directions_bike, value: '1.25', unit: 'km'),
                                SizedBox(height: 16),
                                _TrackerStat(icon: Icons.local_fire_department, value: '27', unit: 'kkal'),
                                SizedBox(height: 16),
                                _TrackerStat(icon: Icons.favorite, value: '78', unit: 'bpm'),
                              ],
                            ),
                            const SizedBox(width: 32),
                            Expanded(
                              child: Container(),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: ElevatedButton(
                              onPressed: _isRunning ? _stopTimer : _startTimer,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1E2641),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                fixedSize: const Size(72, 72),
                                padding: EdgeInsets.zero,
                              ),
                              child: Center(
                                child: Icon(
                                  _isRunning ? Icons.pause : Icons.play_arrow,
                                  size: 36,
                                  color: Colors.white,
                                ),
                              ),
                            ),
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

class _TrackerStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;

  const _TrackerStat({
    required this.icon,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.black),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        Text(
          unit,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }
}
