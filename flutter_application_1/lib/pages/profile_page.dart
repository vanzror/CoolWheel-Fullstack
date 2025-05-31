import 'package:flutter/material.dart';
import 'personal_info_page.dart';
import '../user_data.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../components/loading.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserData userData = UserData();

  bool _isLoading = true;
  String _fullName = '';
  String _email = '';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      final response = await ApiService().getUserProfile(token);
      if (response.statusCode == 200) {
        final user = Map<String, dynamic>.from((response.body.isNotEmpty
            ? jsonDecode(response.body)
            : {}) as Map<String, dynamic>);
        setState(() {
          _fullName = user['username'] ?? '';
          _email = user['email'] ?? '';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editProfile() {
    final nameController = TextEditingController(text: _fullName);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Profile"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _fullName = nameController.text;
                _email = emailController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _signOut() async {
    LoadingPopup.show(context: context, message: "Signing out...");
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    LoadingPopup.hide(context);
    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF007BFF)),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("My Account",
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF007BFF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage('assets/profile.png'),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    _fullName.isNotEmpty
                                        ? _fullName
                                        : 'Dekomori Sanae',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(
                                    _email.isNotEmpty
                                        ? _email
                                        : 'dekomori@fuwa.jp',
                                    style:
                                        const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.white),
                            onPressed: _editProfile,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text("General Settings",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    buildSettingTile(Icons.person, "Personal Info"),
                    buildSettingTile(Icons.settings, "Preferences"),
                    const SizedBox(height: 20),
                    const Text("Help & Support",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    buildSettingTile(Icons.help_outline, "About"),
                    const SizedBox(height: 20),
                    const Text("Sign Out",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _signOut,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const ListTile(
                          leading: Icon(Icons.logout, color: Colors.black),
                          title: Text("Sign Out"),
                          trailing: Icon(Icons.chevron_right),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget buildSettingTile(IconData icon, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (title == "Personal Info") {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PersonalInfoPage()),
            );
          }
        },
      ),
    );
  }
}
