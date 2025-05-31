import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class TrackerPage extends StatefulWidget {
  final VoidCallback? onBackToHome;

  const TrackerPage({super.key, this.onBackToHome});

  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage>
    with AutomaticKeepAliveClientMixin {
  GoogleMapController? _mapController;
  LocationData? _currentLocation;
  final Location _location = Location();

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;

  // Stat values
  double _distanceKm = 0.0;
  int _calories = 0;
  int _bpm = 0;
  String? _realtimeError;

  // Tambahkan variabel untuk animasi blink timer
  bool _showTimer = true;
  Timer? _blinkTimer;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _getLocation();
    // Set initial stat values
    _distanceKm = 0.0;
    _calories = 0;
    _bpm = 0;
  }

  Future<void> _getLocation() async {
    final hasPermission = await _location.requestPermission();
    if (hasPermission == PermissionStatus.granted) {
      final loc = await _location.getLocation();
      if (_currentLocation == null ||
          _currentLocation!.latitude != loc.latitude ||
          _currentLocation!.longitude != loc.longitude) {
        setState(() {
          _currentLocation = loc;
        });
      }
    } else {
      // Handle permission denial
      print("Location permission denied.");
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> startRide() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await _apiService.startRide(token);
      if (response.statusCode == 201) {
        print('Ride started');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tracking dimulai!'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('Failed to start ride: \\${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mulai tracking: \\${response.body}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error starting ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi error saat mulai tracking'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> endRide() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await _apiService.endRide(token);
      if (response.statusCode == 200) {
        print('Ride ended');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Tracking dihentikan!'),
              backgroundColor: Colors.blue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        print('Failed to end ride: \\${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal stop tracking: \\${response.body}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      print('Error ending ride: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi error saat stop tracking'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> getRealtimeData() async {
    final token = await _getToken();
    if (token == null) return;
    try {
      final response = await _apiService.getRealtimeData(token);
      final data = response.statusCode == 200
          ? jsonDecode(response.body)
          : jsonDecode(response.body);
      if (data['error'] != null) {
        final errorMsg =
            data['error'] is String ? data['error'] : data['error'].toString();
        print(errorMsg);
        setState(() {
          _distanceKm = 0.0;
          _calories = 0;
          _bpm = 0;
          _realtimeError = errorMsg;
        });
      } else {
        setState(() {
          _distanceKm = (data['distance'] ?? 0.0).toDouble();
          _calories = (data['calories'] ?? 0).toInt();
          _bpm = (data['last_heartrate'] ?? 0).toInt();
          _realtimeError = null;
        });
      }
    } catch (e) {
      print('Error fetching realtime data: $e');
      setState(() {
        _distanceKm = 0.0;
        _calories = 0;
        _bpm = 0;
        _realtimeError = 'Gagal mengambil data realtime';
      });
    }
  }

  void _startBlinkTimer() {
    _blinkTimer?.cancel();
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _showTimer = !_showTimer;
      });
    });
  }

  void _stopBlinkTimer() {
    _blinkTimer?.cancel();
    setState(() {
      _showTimer = true;
    });
  }

  void _startTimer() async {
    if (_isRunning) return;
    // Reset timer dan stat jika user klik start lagi
    setState(() {
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _calories = 0;
      _bpm = 0;
      _realtimeError = null;
    });
    _stopBlinkTimer();
    await startRide();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _elapsedSeconds++;
      });
      await getRealtimeData();
    });
    setState(() {
      _isRunning = true;
    });
  }

  void _stopTimer() async {
    if (!_isRunning) return;
    _timer?.cancel();
    await endRide();
    setState(() {
      _isRunning = false;
    });
    _startBlinkTimer();
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // penting untuk keep alive
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
                    if (_mapController == null) {
                      _mapController = controller;
                    }
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
                        AnimatedOpacity(
                          opacity: _showTimer ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 200),
                          child: Text(
                            _formatElapsedTime(),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_realtimeError != null) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              _realtimeError!,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TrackerStat(
                                    icon: Icons.directions_bike,
                                    value: _distanceKm.toStringAsFixed(2),
                                    unit: 'km'),
                                const SizedBox(height: 16),
                                _TrackerStat(
                                    icon: Icons.local_fire_department,
                                    value: _calories.toString(),
                                    unit: 'kkal'),
                                const SizedBox(height: 16),
                                _TrackerStat(
                                    icon: Icons.favorite,
                                    value: _bpm.toString(),
                                    unit: 'bpm'),
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
