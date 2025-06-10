import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:iconify_flutter/iconify_flutter.dart';
import 'package:iconify_flutter/icons/material_symbols.dart';
import 'package:intl/intl.dart';

class GpsRouteDetailPage extends StatefulWidget {
  final List<Map<String, dynamic>> gpsData;
  final Map<String, dynamic> activityData;

  const GpsRouteDetailPage({
    super.key,
    required this.gpsData,
    required this.activityData,
  });

  @override
  State<GpsRouteDetailPage> createState() => _GpsRouteDetailPageState();
}

class _GpsRouteDetailPageState extends State<GpsRouteDetailPage> {
  GoogleMapController? _mapController;
  List<LatLng> routePoints = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  bool _satelliteView = false;

  @override
  void initState() {
    super.initState();
    _processGpsData();
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _processGpsData() {
    // Extract coordinates from GPS data
    for (var point in widget.gpsData) {
      final lat = double.tryParse(point['latitude']?.toString() ?? '');
      final lng = double.tryParse(point['longitude']?.toString() ?? '');

      if (lat != null && lng != null) {
        routePoints.add(LatLng(lat, lng));
      }
    }

    if (routePoints.isNotEmpty) {
      // Start marker
      markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: routePoints.first,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
          infoWindow: InfoWindow(
            title: 'Start Point',
            snippet:
                'Lat: ${routePoints.first.latitude.toStringAsFixed(6)}, Lng: ${routePoints.first.longitude.toStringAsFixed(6)}',
          ),
        ),
      );

      // End marker (only if different from start)
      if (routePoints.length > 1) {
        markers.add(
          Marker(
            markerId: const MarkerId('end'),
            position: routePoints.last,
            icon:
                BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            infoWindow: InfoWindow(
              title: 'End Point',
              snippet:
                  'Lat: ${routePoints.last.latitude.toStringAsFixed(6)}, Lng: ${routePoints.last.longitude.toStringAsFixed(6)}',
            ),
          ),
        );
      }

      // Create polyline for the route
      if (routePoints.length > 1) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            points: routePoints,
            color: const Color(0xFF00A3FF),
            width: 5,
            patterns: const [],
          ),
        );
      }
    }
  }

  LatLng _getMapCenter() {
    if (routePoints.isEmpty) return const LatLng(0, 0);

    double minLat = routePoints.first.latitude;
    double maxLat = routePoints.first.latitude;
    double minLng = routePoints.first.longitude;
    double maxLng = routePoints.first.longitude;

    for (var point in routePoints) {
      minLat = minLat < point.latitude ? minLat : point.latitude;
      maxLat = maxLat > point.latitude ? maxLat : point.latitude;
      minLng = minLng < point.longitude ? minLng : point.longitude;
      maxLng = maxLng > point.longitude ? maxLng : point.longitude;
    }

    return LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  void _fitBounds() async {
    if (_mapController != null && routePoints.length > 1) {
      LatLngBounds bounds = LatLngBounds(
        southwest: LatLng(
          routePoints.map((p) => p.latitude).reduce((a, b) => a < b ? a : b),
          routePoints.map((p) => p.longitude).reduce((a, b) => a < b ? a : b),
        ),
        northeast: LatLng(
          routePoints.map((p) => p.latitude).reduce((a, b) => a > b ? a : b),
          routePoints.map((p) => p.longitude).reduce((a, b) => a > b ? a : b),
        ),
      );

      await _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = widget.activityData['started_at'] ?? '';
    final rideId = widget.activityData['ride_id'] ?? 0;
    final distance = widget.activityData['total_distance'] ?? '';
    final duration = widget.activityData['duration_minutes'] ?? '';

    // Format date+time
    String dateTimeStr = 'No date';
    if (startedAt.toString().isNotEmpty) {
      try {
        final dt =
            DateTime.tryParse(startedAt.toString().replaceFirst('T', ' '));
        if (dt != null) {
          final localDt = dt.toLocal();
          dateTimeStr = DateFormat('EEEE, d MMMM yyyy • HH:mm').format(localDt);
        }
      } catch (e) {
        dateTimeStr = startedAt.toString();
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Route Details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _satelliteView ? Icons.map : Icons.satellite,
              color: Colors.black87,
            ),
            onPressed: () {
              setState(() {
                _satelliteView = !_satelliteView;
              });
            },
            tooltip: _satelliteView ? 'Map View' : 'Satellite View',
          ),
          IconButton(
            icon: const Icon(Icons.fit_screen, color: Colors.black87),
            onPressed: _fitBounds,
            tooltip: 'Fit to Route',
          ),
        ],
      ),
      body: Column(
        children: [
          // Activity Info Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity( 0.1),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF242E49),
                        shape: BoxShape.circle,
                      ),
                      child: const Iconify(
                        MaterialSymbols.directions_bike,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ride #$rideId',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            dateTimeStr,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _QuickStat(
                      icon: MaterialSymbols.route,
                      label: 'Distance',
                      value: '${distance}km',
                    ),
                    const SizedBox(width: 16),
                    _QuickStat(
                      icon: MaterialSymbols.av_timer,
                      label: 'Duration',
                      value: '${duration}min',
                    ),
                    const SizedBox(width: 16),
                    _QuickStat(
                      icon: MaterialSymbols.location_on,
                      label: 'Points',
                      value: '${routePoints.length}',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Map Section
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: routePoints.isEmpty
                    ? Container(
                        color: Colors.grey[100],
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.location_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No GPS data available',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GoogleMap(
                        onMapCreated: (GoogleMapController controller) {
                          _mapController = controller;
                          // Auto-fit the route after a short delay
                          Future.delayed(const Duration(milliseconds: 500), () {
                            _fitBounds();
                          });
                        },
                        initialCameraPosition: CameraPosition(
                          target: _getMapCenter(),
                          zoom: 15.0,
                        ),
                        markers: markers,
                        polylines: polylines,
                        mapType:
                            _satelliteView ? MapType.satellite : MapType.normal,
                        myLocationEnabled: false,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        compassEnabled: true,
                        tiltGesturesEnabled: true,
                        scrollGesturesEnabled: true,
                        zoomGesturesEnabled: true,
                        rotateGesturesEnabled: true,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _QuickStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Iconify(
            icon,
            color: Colors.blue,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
