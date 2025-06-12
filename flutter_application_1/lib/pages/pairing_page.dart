import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'dart:async';

import '../services/bluetooth_service.dart';

class PairingPage extends StatefulWidget {
  const PairingPage({super.key});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  final BluetoothService bluetoothService = BluetoothService();
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? selectedDevice;
  bool isConnecting = false;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  void _startDiscovery() {
    devicesList.clear();
    FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      final device = r.device;
      if (!devicesList.any((d) => d.address == device.address)) {
        setState(() {
          devicesList.add(device);
        });
      }
    });
  }

  Future<void> _pairWithESP() async {
    bool granted = await bluetoothService.requestBluetoothPermissions();
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Akses Bluetooth ditolak'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    bool isEnabled = await bluetoothService.enableBluetooth();
    if (!isEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth belum aktif. Aktifkan Bluetooth terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih perangkat Bluetooth terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isConnecting = true;
    });

    try {
      bool bonded = false;
      if (selectedDevice!.isBonded) {
        bonded = true;
      } else {
        bonded = (await FlutterBluetoothSerial.instance.bondDeviceAtAddress(selectedDevice!.address)) ?? false;
      }

      if (!bonded) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal melakukan pairing dengan perangkat'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isConnecting = false;
        });
        return;
      }

      // Connect to device
      final connection = await BluetoothConnection.toAddress(selectedDevice!.address);
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';
      if (token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Token tidak ditemukan'),
            backgroundColor: Colors.red,
          ),
        );
        connection.dispose();
        setState(() {
          isConnecting = false;
        });
        return;
      }

      // Send token to device
      connection.output.add(Uint8List.fromList(token.codeUnits));
      await connection.output.allSent;

      await connection.finish();
      connection.dispose();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pairing berhasil!'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pushReplacementNamed(context, '/main');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saat pairing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pairing Bluetooth'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: devicesList.length,
              itemBuilder: (context, index) {
                final device = devicesList[index];
                return ListTile(
                  title: Text(device.name ?? 'Unknown device'),
                  subtitle: Text(device.address),
                  trailing: selectedDevice == device
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() {
                      selectedDevice = device;
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isConnecting ? null : _pairWithESP,
              child: isConnecting
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                  : const Text('Pair'),
            ),
          ),
        ],
      ),
    );
  }
}
