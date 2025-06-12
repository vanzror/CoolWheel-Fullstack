import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';

class PairingPage extends StatelessWidget {
  const PairingPage({super.key});

  Future<void> _pairWithESP(BuildContext context) async {
    // Minta permission Bluetooth
    final status = await Permission.bluetooth.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Bluetooth ditolak'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pastikan Bluetooth aktif
    final isOn = await FlutterBluePlus.isOn;
    if (!isOn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Bluetooth belum aktif. Aktifkan Bluetooth terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Mulai scan device BLE
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    final scanResults = await FlutterBluePlus.scanResults.first;
    // Pilih device ESP (misal: nama mengandung 'COOLWHEEL')
    final espDevice = scanResults
        .firstWhere(
          (r) => r.device.name.toLowerCase().contains('coolwheel'),
          orElse: () => scanResults.first,
        )
        .device;
    await FlutterBluePlus.stopScan();
    await espDevice.connect();
    // Discover services
    List<BluetoothService> services = await espDevice.discoverServices();
    // Pilih service & characteristic (ganti UUID sesuai ESP Anda)
    final service = services.first;
    final characteristic = service.characteristics.first;
    // Ambil token dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    if (token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Token tidak ditemukan'),
          backgroundColor: Colors.red,
        ),
      );
      await espDevice.disconnect();
      return;
    }
    // Kirim token ke ESP
    await characteristic.write(Uint8List.fromList(token.codeUnits));
    await espDevice.disconnect();
    // Pairing berhasil, lanjut ke home page
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton(
          onPressed: () => _pairWithESP(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007BFF),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: const Text('Pair'),
        ),
      ),
    );
  }
}
