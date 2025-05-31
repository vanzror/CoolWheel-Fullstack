import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../user_data.dart';
import 'dart:convert';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    await Future.delayed(const Duration(seconds: 2)); // Splash delay
    if (token != null && token.isNotEmpty) {
      // Fetch user profile
      try {
        final response = await ApiService().getUserProfile(token);
        if (response.statusCode == 200) {
          final user = jsonDecode(response.body);
          final userData = UserData();
          userData.fullName = user['username'] ?? '';
          userData.email = user['email'] ?? '';
          userData.phone = user['phoneNumber'] ?? '';
          userData.dob = user['dob'] ?? '';
          userData.weight = user['weight']?.toString() ?? '';
          userData.height = user['height']?.toString() ?? '';
          userData.emergencyContactName = user['namaSos'] ?? '';
          userData.emergencyContactPhone = user['sosNumber'] ?? '';
          userData.age = user['age']?.toString() ?? '';
        }
      } catch (e) {
        // ignore error, tetap lanjut ke main
      }
      Navigator.pushReplacementNamed(context, '/main');
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_road, // Placeholder icon similar to the logo
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'CoolWheel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 28,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
