import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://coolwheel-production.up.railway.app/api';
  static const String baseUrlUsers = '$baseUrl/users';
  static const String baseUrlGPS = '$baseUrl/gps';
  static const String baseUrlRides = '$baseUrl/rides';
  static const String baseUrlCalories = '$baseUrl/calories';
  static const String baseUrlHeartRate = '$baseUrl/heartrate';
  static const String baseUrlRealTime = '$baseUrl/realtime';
  static const String baseUrlHistory = '$baseUrl/history';

  Future<http.Response> login(String email, String password) {
    return http.post(
      Uri.parse('$baseUrlUsers/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  Future<http.Response> register(String email, String password) {
    return http.post(
      Uri.parse('$baseUrlUsers/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  Future<http.Response> getUserProfile(String token) {
    return http.get(
      Uri.parse('$baseUrlUsers/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> updateUser(
    String username,
    int weight,
    int height,
    String sosNumber,
    String namaSos,
    int age,
    String phoneNumber,
    String token, 
  ) {
    return http.put(
      Uri.parse('$baseUrlUsers/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', 
      },
      body: jsonEncode({
        'username': username,
        'weight': weight,
        'height': height,
        'sos_number': sosNumber,
        'nama_sos': namaSos,
        'age': age,
        'phone_number': phoneNumber,
      }),
    );
  }

  Future<http.Response> startRide(
    String token,
  ) {
    return http.post(
      Uri.parse('$baseUrlRides/start'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> endRide(
    String token,
  ) {
    return http.post(
      Uri.parse('$baseUrlRides/end'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> getLiveDuration(
    String token,
  ) {
    return http.get(
      Uri.parse('$baseUrlRides/duration/live'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> getRealtimeData(
    String token,
  ) {
    return http.get(
      Uri.parse(baseUrlRealTime),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> getAllHistory(
    String token,
  ) {
    return http.get(
      Uri.parse(baseUrlHistory),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> getAvailableDateHistory(
    String token,
  ) {
    return http.get(
      Uri.parse('$baseUrlHistory/dates'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> getHistoryByDate(
    String date,
    String token,
  ) {
    final RegExp dateFormat = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!dateFormat.hasMatch(date)) {
      throw const FormatException('Format tanggal harus yyyy-mm-dd');
    }
    return http.get(
      Uri.parse('$baseUrlHistory/$date'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );
  }
}
