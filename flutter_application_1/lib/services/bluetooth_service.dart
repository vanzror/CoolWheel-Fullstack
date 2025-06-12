import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;

  Future<bool> requestBluetoothPermissions() async {
    // Request Bluetooth permissions using permission_handler
    var bluetoothStatus = await Permission.bluetooth.status;
    if (!bluetoothStatus.isGranted) {
      bluetoothStatus = await Permission.bluetooth.request();
      if (!bluetoothStatus.isGranted) {
        return false;
      }
    }

    // For Android 12+, also request BluetoothScan and BluetoothConnect permissions
    var scanStatus = await Permission.bluetoothScan.status;
    if (!scanStatus.isGranted) {
      scanStatus = await Permission.bluetoothScan.request();
      if (!scanStatus.isGranted) {
        return false;
      }
    }

    var connectStatus = await Permission.bluetoothConnect.status;
    if (!connectStatus.isGranted) {
      connectStatus = await Permission.bluetoothConnect.request();
      if (!connectStatus.isGranted) {
        return false;
      }
    }

    return true;
  }

  Future<bool> enableBluetooth() async {
    bool? isEnabled = await _bluetooth.isEnabled;
    if (isEnabled == null || !isEnabled) {
      isEnabled = await _bluetooth.requestEnable();
    }
    return isEnabled ?? false;
  }
}
