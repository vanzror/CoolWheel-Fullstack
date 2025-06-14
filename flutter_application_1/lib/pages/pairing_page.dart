import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:async';

import '../services/bluetooth_service.dart' as BtService;

class PairingPage extends StatefulWidget {
  const PairingPage({super.key});

  @override
  State<PairingPage> createState() => _PairingPageState();
}

class _PairingPageState extends State<PairingPage> {
  final BtService.BluetoothService bluetoothService =
      BtService.BluetoothService();
  List<BluetoothDevice> devicesList = [];
  BluetoothDevice? selectedDevice;
  bool isConnecting = false;
  bool isScanning = false;
  bool pairingSuccess = false;
  StreamSubscription<List<BluetoothDevice>>? scanSubscription;

  @override
  void initState() {
    super.initState();
    _startDiscovery();
  }

  @override
  void dispose() {
    scanSubscription?.cancel();
    bluetoothService.dispose();
    super.dispose();
  }

  void _startDiscovery() async {
    // Clear previous devices
    setState(() {
      devicesList.clear();
      isScanning = true;
    });

    // Request permissions
    bool permissionsGranted =
        await bluetoothService.requestBluetoothPermissions();
    if (!permissionsGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bluetooth permissions are required'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        isScanning = false;
      });
      return;
    }

    // Enable Bluetooth
    bool bluetoothEnabled = await bluetoothService.enableBluetooth();
    if (!bluetoothEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enable Bluetooth'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        isScanning = false;
      });
      return;
    }

    // Start scanning
    try {
      await bluetoothService.startScan(timeout: const Duration(seconds: 10));

      // Listen to scan results
      scanSubscription = bluetoothService.scanForDevices().listen((devices) {
        setState(() {
          // Filter hanya device dengan nama mengandung 'COOLWHEEL'
          devicesList = devices
              .where((d) =>
                  d.name != null && d.name!.toUpperCase().contains('COOLWHEEL'))
              .toList();
        });
      });

      // Stop scanning after timeout
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            isScanning = false;
          });
          bluetoothService.stopScan();
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error scanning: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          isScanning = false;
        });
      }
    }
  }

  Future<void> _pairWithESP() async {
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
      bool connected = await bluetoothService.connectToDevice(selectedDevice!);
      if (connected) {
        // Save device info to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('connected_device_id', selectedDevice!.address);
        await prefs.setString(
            'connected_device_name',
            selectedDevice!.name?.isNotEmpty == true
                ? selectedDevice!.name!
                : 'Unknown Device');

        // Kirim token ke ESP32 setelah benar-benar terkoneksi
        final token = prefs.getString('token') ?? '';
        final formattedToken = 'TOKEN:$token\n';
        print('[DEBUG] Token yang akan dikirim ke ESP32: $formattedToken');
        if (token.isNotEmpty) {
          final sent = await bluetoothService.sendData(formattedToken);
          if (sent && mounted) {
            setState(() {
              pairingSuccess = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Token berhasil dikirim ke ESP32'),
                  backgroundColor: Colors.green),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Gagal mengirim token ke ESP32'),
                  backgroundColor: Colors.red),
            );
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Berhasil terhubung ke ${selectedDevice!.name?.isNotEmpty == true ? selectedDevice!.name! : 'Unknown Device'}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal terhubung ke perangkat'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isConnecting = false;
        });
      }
    }
  }

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pairing Bluetooth'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Scanning indicator
          if (isScanning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Scanning for devices...'),
                ],
              ),
            ),

          // Refresh button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: isScanning ? null : _startDiscovery,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ),

          // Device list
          Expanded(
            child: devicesList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bluetooth_searching,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isScanning
                              ? 'Searching for devices...'
                              : 'No devices found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        if (!isScanning) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Make sure your ESP32 device is in pairing mode',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: devicesList.length,
                    itemBuilder: (context, index) {
                      final device = devicesList[index];
                      final deviceName = device.name?.isNotEmpty == true
                          ? device.name!
                          : (device.address.contains('ESP32')
                              ? 'ESP32 Device'
                              : 'Unknown Device');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth),
                          title: Text(deviceName),
                          subtitle: Text('Address: ${device.address}'),
                          trailing: selectedDevice == device
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.radio_button_unchecked),
                          onTap: () {
                            setState(() {
                              selectedDevice = device;
                            });
                          },
                        ),
                      );
                    },
                  ),
          ),

          // Connect/Continue button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isConnecting
                  ? null
                  : pairingSuccess
                      ? _goToHome
                      : (selectedDevice != null ? _pairWithESP : null),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: isConnecting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Connecting...'),
                      ],
                    )
                  : Text(
                      pairingSuccess ? 'Continue' : 'Pair',
                      style: const TextStyle(fontSize: 16),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
