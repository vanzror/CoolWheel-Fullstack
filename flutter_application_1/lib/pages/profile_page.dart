import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'Dekomori Sanae';
  String email = 'dekomori@fuwa.jp';

  void _editProfile() {
    final nameController = TextEditingController(text: name);
    final emailController = TextEditingController(text: email);

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
                name = nameController.text;
                email = emailController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("My Account",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
                          Text(name,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(email,
                              style: const TextStyle(color: Colors.white)),
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
              buildSettingTile(Icons.logout, "Sign Out"),
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
        onTap: () {},
      ),
    );
  }
}
