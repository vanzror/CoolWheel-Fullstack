import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  static const String baseUrl = 'https://coolwheel-production.up.railway.app/api';
  static const String baseUrlUsers = '$baseUrl/users';
  static const String baseUrlGPS = '$baseUrl/gps';
  static const String baseUrlRides = '$baseUrl/rides';
  static const String baseUrlCalories = '$baseUrl/calories';
  static const String baseUrlHeartRate = '$baseUrl/heartrate';

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

  Future<http.Response> updateUser(
    String username,
    int weight,
    int height,
    String sos_number,
    String nama_sos,
    int age,
    String phone_number,
    String token, // Add token as a parameter
  ) {
    return http.put(
      Uri.parse('$baseUrlUsers/me'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Add Authorization header
      },
      body: jsonEncode({
        'username': username,
        'weight': weight,
        'height': height,
        'sos_number': sos_number,
        'nama_sos': nama_sos,
        'age': age,
        'phone_number': phone_number,
      }),
    );
  }
}
