import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';

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

    // Aktifkan Bluetooth jika belum aktif
    final isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
    if (!isEnabled!) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    // Scan device, pilih yang namanya mengandung 'ESP'
    List<BluetoothDevice> bondedDevices =
        await FlutterBluetoothSerial.instance.getBondedDevices();
    BluetoothDevice? espDevice;
    for (var device in bondedDevices) {
      if (device.name != null &&
          device.name!.toLowerCase().contains('COOLWHEEL')) {
        espDevice = device;
        break;
      }
    }
    if (espDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Device ESP tidak ditemukan. Pastikan sudah dipairing di pengaturan Bluetooth.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Coba koneksi ke ESP
    try {
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
        return;
      }
      BluetoothConnection connection =
          await BluetoothConnection.toAddress(espDevice.address);
      // Kirim token ke ESP
      connection.output.add(Uint8List.fromList(token.codeUnits));
      await connection.output.allSent;
      await connection.close();
      // Pairing berhasil, lanjut ke home page
      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal pairing/koneksi ke ESP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
