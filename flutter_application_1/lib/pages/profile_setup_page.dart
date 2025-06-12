import 'package:flutter/material.dart';
import 'package:flutter_application_1/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../user_data.dart';
import '../components/loading.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  File? _profileImage;

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _emergencyContactNameController =
      TextEditingController();
  final TextEditingController _emergencyContactPhoneController =
      TextEditingController();

  Future<void> _pickImage() async {
    // Image picker functionality removed due to missing package
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate =
        DateTime.now().subtract(const Duration(days: 365 * 20));
    DateTime firstDate = DateTime(1900);
    DateTime lastDate = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  void _continue() async {
    if (_formKey.currentState!.validate()) {
      LoadingPopup.show(context: context, message: "Saving profile...");
      // Save data to UserData singleton
      final userData = UserData();
      userData.fullName = _fullNameController.text;
      userData.phone = _phoneController.text;
      userData.dob = _dobController.text;
      userData.age = _ageController.text;
      userData.weight = _weightController.text;
      userData.height = _heightController.text;
      userData.emergencyContactName = _emergencyContactNameController.text;
      userData.emergencyContactPhone = _emergencyContactPhoneController.text;
      final prefs = await SharedPreferences.getInstance();
      final getToken = prefs.getString('token');

      final apiService = ApiService();
      final response = await apiService.updateUser(
          userData.fullName,
          int.parse(userData.weight),
          int.parse(userData.height),
          userData.emergencyContactPhone,
          userData.emergencyContactName,
          int.parse(userData.age),
          userData.phone,
          getToken.toString());

      LoadingPopup.hide(context);
      debugPrint(
        'Response from API: [38;5;2m${response.statusCode} ${response.body} $getToken[0m',
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data user updated successfully')),
        );
        Navigator.pushReplacementNamed(context, '/pairing');
        // Navigate to pairing page
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update user data')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    _emergencyContactNameController.dispose();
    _emergencyContactPhoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2641),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2641),
        elevation: 0,
        title: const Text('Profile Setup'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pushReplacementNamed(context, '/sign_up'),
        ),
      ),
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFFF0F3F7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundImage: _profileImage != null
                            ? FileImage(_profileImage!)
                            : const AssetImage('assets/profile.png')
                                as ImageProvider,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.all(6),
                            child: const Icon(
                              Icons.edit,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildTextField(_fullNameController, 'Nama Lengkap',
                    Icons.person, TextInputType.text),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Nomor Telepon',
                    Icons.phone_android, TextInputType.phone),
                const SizedBox(height: 16),
                // TextFormField(
                //   controller: _dobController,
                //   decoration: const InputDecoration(
                //     labelText: 'Tanggal Lahir',
                //     prefixIcon: Icon(Icons.calendar_today),
                //     filled: true,
                //     fillColor: Colors.white,
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.all(Radius.circular(12)),
                //     ),
                //   ),
                //   readOnly: true,
                //   onTap: () => _selectDate(context),
                //   validator: (value) => value == null || value.isEmpty ? 'Please select tanggal lahir' : null,
                // ),
                _buildTextField(
                    _ageController, 'Usia', Icons.cake, TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(_weightController, 'Berat Badan',
                    Icons.monitor_weight, TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(_heightController, 'Tinggi Badan', Icons.height,
                    TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(_emergencyContactNameController,
                    'Nama Kontak Darurat', Icons.person, TextInputType.text),
                const SizedBox(height: 16),
                _buildTextField(_emergencyContactPhoneController,
                    'Nomor Telepon Darurat', Icons.phone, TextInputType.phone),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.arrow_forward,
                      size: 16, color: Colors.white),
                  label: const Text('Continue',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      IconData icon, TextInputType keyboardType) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      keyboardType: keyboardType,
      validator: (value) =>
          value == null || value.isEmpty ? 'Please enter $label' : null,
    );
  }
}
