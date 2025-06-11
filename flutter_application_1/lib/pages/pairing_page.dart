import 'package:flutter/material.dart';

class PairingPage extends StatelessWidget {
  const PairingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            // Minta akses Bluetooth (contoh untuk Android/iOS, gunakan permission_handler & flutter_blue)
            // Pastikan sudah menambah dependency permission_handler dan flutter_blue di pubspec.yaml
            // import 'package:permission_handler/permission_handler.dart';
            // import 'package:flutter_blue/flutter_blue.dart';

            // Request permission
            // final status = await Permission.bluetooth.request();
            // if (status.isGranted) {
            //   // Lakukan proses pairing di sini
            //   // Jika pairing berhasil:
            //   Navigator.pushReplacementNamed(context, '/main');
            //   return;
            // } else {
            //   ScaffoldMessenger.of(context).showSnackBar(
            //     const SnackBar(
            //       content: Text('Akses Bluetooth ditolak'),
            //       backgroundColor: Colors.red,
            //     ),
            //   );
            //   return;
            // }

            // Untuk demo tanpa dependency:
            final result = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Aktifkan Bluetooth'),
                content: const Text(
                    'Silakan nyalakan Bluetooth di perangkat Anda untuk melanjutkan proses pairing.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sudah Aktif'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                ],
              ),
            );
            if (result == true) {
              // Simulasi pairing berhasil, lanjut ke home page
              Navigator.pushReplacementNamed(context, '/main');
            }
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
