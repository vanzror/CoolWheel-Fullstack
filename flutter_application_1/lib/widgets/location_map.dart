import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class LocationMap extends StatefulWidget {
  const LocationMap({super.key});

  @override
  State<LocationMap> createState() => _LocationMapState();
}

class _LocationMapState extends State<LocationMap> {
  GoogleMapController? _mapController;
  final ApiService _apiService = ApiService();

  // GPS coordinates state
  double? _latitude;
  double? _longitude;
  Timer? _timer;

  // Map markers
  Set<Marker> _markers = {};

  // Default coordinates (Jakarta as fallback)
  static const LatLng _defaultLocation = LatLng(-6.2088, 106.8456);

  @override
  void initState() {
    super.initState();
    _fetchGPSCoordinates();
    // Set up periodic fetching every 10 seconds
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _fetchGPSCoordinates();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> _fetchGPSCoordinates() async {
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await _apiService.getLastGPSCoordinates(token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final double? lat =
            data['latitude']?.toDouble() ?? data['lat']?.toDouble();
        final double? lng =
            data['longitude']?.toDouble() ?? data['lng']?.toDouble();

        if (lat != null && lng != null) {
          setState(() {
            _latitude = lat;
            _longitude = lng;
          });

          // Update marker and move camera to new position
          await _updateMarker();

          if (_mapController != null) {
            _mapController!.animateCamera(
              CameraUpdate.newLatLng(LatLng(lat, lng)),
            );
          }
        }
      }
    } catch (e) {
      // Silently handle errors
    }
  }

  Future<void> _updateMarker() async {
    if (_latitude != null && _longitude != null) {
      final bikeIcon = await _createBikeIcon();
      setState(() {
        _markers = {
          Marker(
            markerId: const MarkerId('bike_location'),
            position: LatLng(_latitude!, _longitude!),
            infoWindow: const InfoWindow(
              title: 'Bike Location',
              snippet: 'Current position of your bike',
            ),
            icon: bikeIcon,
          ),
        };
      });
    }
  }

  Future<BitmapDescriptor> _createBikeIcon() async {
    // Create a simple custom pin marker with bike icon
    return BitmapDescriptor.bytes(await _getBytesFromCanvas());
  }

  Future<Uint8List> _getBytesFromCanvas() async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    const double width = 48.0;
    const double height = 60.0;

    // Draw pin shape (teardrop)
    final Path pinPath = Path();
    const double pinRadius = 20.0;
    const double pinCenterX = width / 2;
    const double pinCenterY = pinRadius + 5;

    // Create teardrop/pin shape
    pinPath.addOval(Rect.fromCircle(
      center: Offset(pinCenterX, pinCenterY),
      radius: pinRadius,
    ));

    // Add the pointed bottom of the pin
    pinPath.moveTo(pinCenterX - 8, pinCenterY + 15);
    pinPath.lineTo(pinCenterX, height - 5);
    pinPath.lineTo(pinCenterX + 8, pinCenterY + 15);
    pinPath.close(); // Draw pin background
    final Paint pinPaint = Paint()
      ..color = const Color(0xFF4A90E2) // Changed from red to blue
      ..style = PaintingStyle.fill;

    canvas.drawPath(pinPath, pinPaint);

    // Draw white border for pin
    final Paint pinBorderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawPath(pinPath, pinBorderPaint);

    // Draw white bike icon using simple shapes
    final Paint bikePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw bike frame (simplified bicycle)
    const double bikeScale = 0.5;
    const double offsetX = pinCenterX;
    const double offsetY = pinCenterY;

    // Bike wheels
    canvas.drawCircle(
      Offset(offsetX - 7 * bikeScale, offsetY + 3),
      3.5 * bikeScale,
      bikePaint,
    );
    canvas.drawCircle(
      Offset(offsetX + 7 * bikeScale, offsetY + 3),
      3.5 * bikeScale,
      bikePaint,
    );

    // Bike frame
    canvas.drawLine(
      Offset(offsetX - 3 * bikeScale, offsetY + 3),
      Offset(offsetX + 3 * bikeScale, offsetY + 3),
      bikePaint,
    );
    canvas.drawLine(
      Offset(offsetX, offsetY + 3),
      Offset(offsetX, offsetY - 5 * bikeScale),
      bikePaint,
    );
    canvas.drawLine(
      Offset(offsetX, offsetY - 5 * bikeScale),
      Offset(offsetX - 5 * bikeScale, offsetY),
      bikePaint,
    );
    canvas.drawLine(
      Offset(offsetX, offsetY - 5 * bikeScale),
      Offset(offsetX + 5 * bikeScale, offsetY),
      bikePaint,
    );

    final ui.Picture picture = pictureRecorder.endRecording();
    final ui.Image image = await picture.toImage(width.toInt(), height.toInt());
    final ByteData? byteData =
        await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200, // Increased height for better interaction
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _latitude != null && _longitude != null
                    ? LatLng(_latitude!, _longitude!)
                    : _defaultLocation,
                zoom: 15,
              ),
              markers: _markers,
              // Enable map interactions
              myLocationButtonEnabled: false,
              zoomControlsEnabled: true, // Enable zoom controls
              mapToolbarEnabled: false,
              zoomGesturesEnabled: true, // Enable zoom gestures
              scrollGesturesEnabled: true, // Enable pan gestures
              tiltGesturesEnabled: true, // Enable tilt gestures
              rotateGesturesEnabled: true, // Enable rotation gestures
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                if (_latitude != null && _longitude != null) {
                  controller.animateCamera(
                    CameraUpdate.newLatLng(LatLng(_latitude!, _longitude!)),
                  );
                }
              },
            ),
          ),
          // Refresh button positioned at top right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _fetchGPSCoordinates,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(
                      Icons.refresh,
                      size: 20,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
