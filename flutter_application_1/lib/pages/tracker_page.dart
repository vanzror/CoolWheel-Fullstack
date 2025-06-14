import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart' as loc;
import 'package:shared_preferences/shared_preferences.dart';
//import 'package:permission_handler/permission_handler.dart';

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
  loc.LocationData? _currentLocation;

  Timer? _timer;
  Timer? _gpsTimer;
  int _elapsedSeconds = 0;

  // Ride state: 'stopped', 'running', 'paused'
  String _rideState = 'stopped';

  // Stat values
  double _distanceKm = 0.0;
  int _calories = 0;
  int _bpm = 0;
  double _pace = 0.0;
  String? _realtimeError;

  // GPS tracking variables
  final List<LatLng> _routePoints = [];
  final Set<Polyline> _polylines = {};
  final Set<Marker> _markers = {};
  int? _currentRideId;

  // Tambahkan variabel untuk animasi blink timer
  bool _showTimer = true;
  Timer? _blinkTimer;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _startBlinkTimer();
    // Set initial stat values
    _distanceKm = 0.0;
    _calories = 0;
    _bpm = 0;
    _pace = 0.0;
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
        print('Failed to start ride: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal mulai tracking: ${response.body}'),
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
        print('Failed to end ride: ${response.body}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal stop tracking: ${response.body}'),
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
          _pace = (data['pace'] ?? 0.0).toDouble();
          _realtimeError = null;
        });
      }
    } catch (e) {
      print('Error fetching realtime data: $e');
      setState(() {
        _distanceKm = 0.0;
        _calories = 0;
        _bpm = 0;
        _pace = 0.0;
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
    if (_rideState != 'stopped') return;
    // Reset timer dan stat jika user klik start lagi
    setState(() {
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _calories = 0;
      _bpm = 0;
      _pace = 0.0;
      _realtimeError = null;
      _routePoints.clear();
      _polylines.clear();
      _markers.clear();
    });
    _stopBlinkTimer();
    await startRide();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _elapsedSeconds++;
      });
      await getRealtimeData();
    });
    // Start GPS tracking
    _gpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _getLiveGpsTracking();
    });
    setState(() {
      _rideState = 'running';
    });
  }

  void _pauseTimer() async {
    if (_rideState != 'running') return;
    _timer?.cancel();
    _gpsTimer?.cancel();

    final token = await _getToken();
    if (token != null) {
      try {
        final response = await _apiService.pauseRide(token);
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tracking dijeda'),
                backgroundColor: Colors.orange,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print('Error pausing ride: $e');
      }
    }

    setState(() {
      _rideState = 'paused';
    });
    _startBlinkTimer();
  }

  void _resumeTimer() async {
    if (_rideState != 'paused') return;

    final token = await _getToken();
    if (token != null) {
      try {
        final response = await _apiService.resumeRide(token);
        if (response.statusCode == 200) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tracking dilanjutkan'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } catch (e) {
        print('Error resuming ride: $e');
      }
    }

    _stopBlinkTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      setState(() {
        _elapsedSeconds++;
      });
      await getRealtimeData();
    });

    _gpsTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      await _getLiveGpsTracking();
    });

    setState(() {
      _rideState = 'running';
    });
  }

  Future<void> _stopTimer() async {
    if (_rideState == 'stopped') return;
    _timer?.cancel();
    _gpsTimer?.cancel();
    await endRide();

    // Show summary dialog after successful end ride
    await _showRideSummaryDialog();

    setState(() {
      _rideState = 'stopped';
      _elapsedSeconds = 0;
      _distanceKm = 0.0;
      _calories = 0;
      _bpm = 0;
      _pace = 0.0;
      _realtimeError = null;
      _routePoints.clear();
      _polylines.clear();
      _markers.clear();
      _currentRideId = null;
    });
    _startBlinkTimer();
  }

  String _formatElapsedTime() {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Future<void> _getLiveGpsTracking() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      final response = await _apiService.getLiveGpsTracking(token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rideId = data['ride_id'];
        final gpsPoints = data['gps_points'] as List<dynamic>?;
        if (gpsPoints != null && gpsPoints.isNotEmpty) {
          setState(() {
            _currentRideId = rideId;
            print('Tracking ride ID: $_currentRideId');
            _routePoints.clear(); // Convert GPS points to LatLng objects
            List<LatLng> tempPoints = [];
            for (var point in gpsPoints) {
              final lat = point['latitude']?.toDouble();
              final lng = point['longitude']?.toDouble();
              if (lat != null && lng != null) {
                tempPoints.add(LatLng(lat, lng));
              }
            } // Reverse the order if API sends newest first (uncomment if needed)
            tempPoints = tempPoints.reversed.toList();

            _routePoints.addAll(tempPoints);

            // Setel _currentLocation dari GPS backend
            if (_routePoints.isNotEmpty) {
              _currentLocation = loc.LocationData.fromMap({
                'latitude': _routePoints.last.latitude,
                'longitude': _routePoints.last.longitude,
              });
            }

            // Debug: Print GPS points order
            print('GPS Points count: \\${_routePoints.length}');
            if (_routePoints.isNotEmpty) {
              print(
                  'First GPS point (should be START): \\${_routePoints.first}');
              print(
                  'Last GPS point (should be CURRENT): \\${_routePoints.last}');
            } // Update polylines to show the route
            _updateRoutePolylines();

            // Add markers for start and current position
            _updateRouteMarkers();

            // Auto-focus map to current position (latest GPS point)
            _focusMapToCurrentPosition();
          });
        }
      }
    } catch (e) {
      print('Error fetching live GPS tracking: $e');
    }
  }

  Future<void> _showRideSummaryDialog() async {
    final token = await _getToken();
    if (token == null) return;

    try {
      // Show loading dialog first
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final response = await _apiService.getSummaryRideAfterEnd(token);

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['summary'];

        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _buildSummaryDialog(summary),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal mengambil summary ride'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if error occurs
      if (mounted) Navigator.of(context).pop();
      print('Error fetching ride summary: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Terjadi error saat mengambil summary'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildSummaryDialog(Map<String, dynamic> summary) {
    final performance = summary['performance'] ?? {};
    final heartratStats = summary['heartrate_stats'] ?? {};

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E2641), Color(0xFF2A3B5C)],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Ride Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Performance Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        Icons.directions_bike,
                        '${performance['total_distance'] ?? '0.00'} km',
                        'Distance',
                      ),
                      _buildSummaryItem(
                        Icons.timer,
                        performance['duration_formatted'] ?? '00:00:00',
                        'Duration',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        Icons.local_fire_department,
                        '${performance['total_calories'] ?? '0'} kkal',
                        'Calories',
                      ),
                      _buildSummaryItem(
                        Icons.speed,
                        '${performance['average_speed'] ?? '0'} km/h',
                        'Avg Speed',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Heart Rate Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Heart Rate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        Icons.favorite,
                        '${heartratStats['max_heartrate'] ?? '0'} bpm',
                        'Max HR',
                      ),
                      _buildSummaryItem(
                        Icons.favorite_outline,
                        '${heartratStats['avg_heartrate'] ?? '0'} bpm',
                        'Avg HR',
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'Intensity: ${heartratStats['intensity_level'] ?? 'Unknown'}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  void _focusMapToCurrentPosition() {
    if (_mapController != null && _routePoints.isNotEmpty) {
      // Get the current position (last point in the route)
      final currentPosition = _routePoints.last;

      // Animate camera to current position with smooth transition
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentPosition,
            zoom: 18.0, // Zoom level yang cukup detail untuk tracking
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }
  }

  void _updateRoutePolylines() {
    if (_routePoints.length < 2) return;

    _polylines.clear();
    _polylines.add(
      Polyline(
        polylineId: const PolylineId('route'),
        points: _routePoints,
        color: Colors.blue,
        width: 4,
        patterns: const [],
      ),
    );
  }

  void _updateRouteMarkers() {
    _markers.clear();

    if (_routePoints.isNotEmpty) {
      // Start marker - GPS point terlama (pertama dalam array) = hijau
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _routePoints.first,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: const InfoWindow(title: 'Start'),
        ),
      );

      // Current position marker - GPS point terbaru (terakhir dalam array) = merah
      if (_routePoints.length > 1) {
        _markers.add(
          Marker(
            markerId: const MarkerId('current'),
            position: _routePoints.last,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: const InfoWindow(title: 'Current Position'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _gpsTimer?.cancel();
    _blinkTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Widget _buildControlButtons() {
    switch (_rideState) {
      case 'stopped':
        // Show only play button
        return ElevatedButton(
          onPressed: _startTimer,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E2641),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            fixedSize: const Size(72, 72),
            padding: EdgeInsets.zero,
          ),
          child: const Center(
            child: Icon(
              Icons.play_arrow,
              size: 36,
              color: Colors.white,
            ),
          ),
        );

      case 'running':
        // Show pause and stop buttons
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _pauseTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                fixedSize: const Size(72, 72),
                padding: EdgeInsets.zero,
              ),
              child: const Center(
                child: Icon(
                  Icons.pause,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _stopTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                fixedSize: const Size(72, 72),
                padding: EdgeInsets.zero,
              ),
              child: const Center(
                child: Icon(
                  Icons.stop,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

      case 'paused':
        // Show resume and stop buttons
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _resumeTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                fixedSize: const Size(72, 72),
                padding: EdgeInsets.zero,
              ),
              child: const Center(
                child: Icon(
                  Icons.play_arrow,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 20),
            ElevatedButton(
              onPressed: _stopTimer,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                fixedSize: const Size(72, 72),
                padding: EdgeInsets.zero,
              ),
              child: const Center(
                child: Icon(
                  Icons.stop,
                  size: 36,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
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
                  polylines: _polylines,
                  markers: _markers,
                  onMapCreated: (controller) {
                    _mapController ??= controller;
                  },
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
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
                            const SizedBox(
                                width: 48), // To balance the back button width
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
                                const SizedBox(height: 16),
                                _TrackerStat(
                                  icon: Icons.access_time,
                                  value: () {
                                    final minutes = _pace.floor();
                                    final seconds =
                                        ((_pace - minutes) * 60).round();
                                    return '$minutes:${seconds.toString().padLeft(2, '0')}';
                                  }(),
                                  unit: 'min/km',
                                )
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
                            child: _buildControlButtons(),
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
