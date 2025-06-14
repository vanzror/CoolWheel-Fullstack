import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService {
  static final BluetoothService _instance = BluetoothService._internal();
  factory BluetoothService() => _instance;
  BluetoothService._internal();

  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;
  final List<BluetoothDevice> _discoveredDevices = [];
  StreamController<List<BluetoothDevice>>? _devicesController;

  bool get isConnected => _connection != null && _connection!.isConnected;
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  Future<bool> requestBluetoothPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    return statuses.values.every((status) => status.isGranted);
  }

  Future<bool> enableBluetooth() async {
    try {
      bool? isAvailable = await FlutterBluetoothSerial.instance.isAvailable;
      if (isAvailable != true) {
        print("Bluetooth not available on this device");
        return false;
      }

      bool? isEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (isEnabled != true) {
        await FlutterBluetoothSerial.instance.requestEnable();
      }

      return true;
    } catch (e) {
      print("Error enabling Bluetooth: $e");
      return false;
    }
  }

  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      return await FlutterBluetoothSerial.instance.getBondedDevices();
    } catch (e) {
      print("Error getting bonded devices: $e");
      return [];
    }
  }

  Stream<List<BluetoothDevice>> scanForDevices() async* {
    _discoveredDevices.clear();
    _devicesController = StreamController<List<BluetoothDevice>>();

    try {
      List<BluetoothDevice> bondedDevices = await getBondedDevices();
      _discoveredDevices.addAll(bondedDevices);

      FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        final existingIndex = _discoveredDevices
            .indexWhere((device) => device.address == result.device.address);
        if (existingIndex >= 0) {
          _discoveredDevices[existingIndex] = result.device;
        } else {
          if (result.device.name?.isNotEmpty == true ||
              result.device.address.startsWith('ESP32') ||
              result.device.address.contains(':')) {
            _discoveredDevices.add(result.device);
          }
        }
        _devicesController?.add(List.from(_discoveredDevices));
      });

      await for (int i
          in Stream.periodic(const Duration(milliseconds: 500), (x) => x)) {
        yield List.from(_discoveredDevices);

        if (i > 60) {
          break;
        }
      }
    } catch (e) {
      print("Error during discovery: $e");
      yield _discoveredDevices;
    }
  }

  Future<void> startScan(
      {Duration timeout = const Duration(seconds: 10)}) async {
    try {
      await FlutterBluetoothSerial.instance.startDiscovery();
    } catch (e) {
      print("Error starting scan: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluetoothSerial.instance.cancelDiscovery();
      _devicesController?.close();
    } catch (e) {
      print("Error stopping scan: $e");
    }
  }

  Future<bool> connectToDevice(BluetoothDevice device) async {
    try {
      await disconnect();

      _connection = await BluetoothConnection.toAddress(device.address);
      _connectedDevice = device;

      _dataSubscription = _connection!.input!.listen((data) {
        String receivedData = String.fromCharCodes(data);
        print("Bluetooth: Received data from ${device.name}: $receivedData");
      });

      print('Connected to ${device.name}');
      return true;
    } catch (e) {
      print('Cannot connect to device: $e');
      return false;
    }
  }

  Future<bool> sendData(String data) async {
    if (_connection == null || !_connection!.isConnected) {
      print("No device connected");
      return false;
    }

    try {
      _connection!.output.add(Uint8List.fromList(utf8.encode(data)));
      await _connection!.output.allSent;
      print("Bluetooth: Sending data to ${_connectedDevice?.name}: $data");
      return true;
    } catch (e) {
      print("Error sending data: $e");
      return false;
    }
  }

  Future<void> disconnect() async {
    try {
      _dataSubscription?.cancel();
      await _connection?.close();
    } catch (e) {
      print("Error disconnecting: $e");
    }
    _connection = null;
    _connectedDevice = null;
  }

  void dispose() {
    stopScan();
    disconnect();
  }
}
