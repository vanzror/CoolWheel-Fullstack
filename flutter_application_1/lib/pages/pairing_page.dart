import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class PairingPage extends StatelessWidget {
  const PairingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
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

            // Mulai scan device BLE
            FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
            // Tunggu hasil scan
            final scanResults = await FlutterBluePlus.scanResults.first;
            // Pilih device ESP (misal: nama mengandung 'ESP')
            final espDevice = scanResults
                .firstWhere(
                  (r) => r.device.name.toLowerCase().contains('esp'),
                  orElse: () => scanResults.first,
                )
                .device;
            await FlutterBluePlus.stopScan();
            await espDevice.connect();
            // Discover services
            List<BluetoothService> services =
                await espDevice.discoverServices();
            // Pilih service & characteristic (ganti UUID sesuai ESP Anda)
            final service = services.first;
            final characteristic = service.characteristics.first;
            // Kirim data pairing (contoh: string 'PAIR')
            await characteristic.write("PAIR".codeUnits);
            await espDevice.disconnect();
            // Pairing berhasil, lanjut ke home page
            Navigator.pushReplacementNamed(context, '/main');
          },
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
