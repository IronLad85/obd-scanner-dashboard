import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'obd_connection_interface.dart';

export 'package:flutter_blue_plus/flutter_blue_plus.dart' show BluetoothDevice;

/// BLE connection adapter for Bluetooth 4.0 OBD-II devices
/// Compatible with devices like MODAXE Advanced Chipset OBD II Scanner V2.2
class BleConnectionAdapter implements ObdConnectionInterface {
  final BluetoothDevice device;

  final StreamController<String> _responseController =
      StreamController<String>.broadcast();
  bool _isConnected = false;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _notifyCharacteristic;
  StreamSubscription<List<int>>? _notificationSubscription;

  // Common OBD-II BLE Service UUID (ELM327-compatible)
  static const String _obdServiceUuid = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String _writeCharacteristicUuid =
      '0000fff1-0000-1000-8000-00805f9b34fb';
  static const String _notifyCharacteristicUuid =
      '0000fff2-0000-1000-8000-00805f9b34fb';

  StringBuffer _buffer = StringBuffer();

  BleConnectionAdapter({required this.device});

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Future<void> connect() async {
    try {
      // Connect to device
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Wait a bit for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 500));

      // Discover services
      final services = await device.discoverServices();

      // Find OBD service
      BluetoothService? obdService;
      for (final service in services) {
        if (service.uuid.toString().toLowerCase() == _obdServiceUuid) {
          obdService = service;
          break;
        }
      }

      if (obdService == null) {
        throw Exception('OBD-II service not found on device');
      }

      // Find write and notify characteristics
      for (final characteristic in obdService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();

        if (uuid == _writeCharacteristicUuid) {
          _writeCharacteristic = characteristic;
        } else if (uuid == _notifyCharacteristicUuid) {
          _notifyCharacteristic = characteristic;
        }
      }

      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        throw Exception('Required BLE characteristics not found');
      }

      // Subscribe to notifications
      await _notifyCharacteristic!.setNotifyValue(true);
      _notificationSubscription = _notifyCharacteristic!.onValueReceived.listen(
        _handleNotification,
        onError: (error) {
          print('❌ BLE notification error: $error');
        },
      );

      _isConnected = true;
      print('✅ BLE connected successfully');
    } catch (e) {
      _isConnected = false;
      print('❌ BLE connection failed: $e');
      rethrow;
    }
  }

  void _handleNotification(List<int> value) {
    try {
      final data = utf8.decode(value, allowMalformed: true);
      _buffer.write(data);

      // Check if we have complete response(s)
      final bufferContent = _buffer.toString();

      // Look for response terminators (> or \r)
      if (bufferContent.contains('>') || bufferContent.contains('\r')) {
        // Split by common delimiters
        final responses = bufferContent.split(RegExp(r'[>\r\n]+'));

        for (final response in responses) {
          final trimmed = response.trim();
          if (trimmed.isNotEmpty && !_responseController.isClosed) {
            try {
              _responseController.add(trimmed);
            } catch (e) {
              // Ignore StreamSink errors if controller is closed
            }
          }
        }

        // Clear buffer after processing
        _buffer.clear();
      }
    } catch (e) {
      print('❌ Error handling BLE notification: $e');
    }
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    try {
      if (_notifyCharacteristic != null) {
        await _notifyCharacteristic!.setNotifyValue(false);
      }
    } catch (e) {
      print('Error disabling notifications: $e');
    }

    try {
      await device.disconnect();
    } catch (e) {
      print('Error disconnecting BLE device: $e');
    }
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!_isConnected || _writeCharacteristic == null) {
      throw Exception('Not connected to BLE device');
    }

    try {
      // Add carriage return if not present
      final commandToSend = command.endsWith('\r') ? command : '$command\r';
      final data = utf8.encode(commandToSend);

      await _writeCharacteristic!.write(data, withoutResponse: false);

      // Small delay between commands for stability
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      print('❌ Error sending BLE command: $e');
      rethrow;
    }
  }

  /// Scan for nearby BLE devices
  static Future<List<BluetoothDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final devices = <BluetoothDevice>[];
    final Set<String> deviceIds = {};

    // Check if Bluetooth is on
    try {
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported on this device');
      }

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final deviceId = result.device.remoteId.toString();
          if (!deviceIds.contains(deviceId)) {
            deviceIds.add(deviceId);
            devices.add(result.device);
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);
      await subscription.cancel();
      await FlutterBluePlus.stopScan();

      return devices;
    } catch (e) {
      print('❌ BLE scan error: $e');
      await FlutterBluePlus.stopScan();
      rethrow;
    }
  }

  /// Get list of connected BLE devices
  static Future<List<BluetoothDevice>> getConnectedDevices() async {
    try {
      return await FlutterBluePlus.connectedDevices;
    } catch (e) {
      print('❌ Error getting connected devices: $e');
      return [];
    }
  }

  /// Check if Bluetooth is enabled
  static Future<bool> isBluetoothOn() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState == BluetoothAdapterState.on;
    } catch (e) {
      print('❌ Error checking Bluetooth state: $e');
      return false;
    }
  }

  /// Turn on Bluetooth (Android only)
  static Future<void> turnOnBluetooth() async {
    try {
      await FlutterBluePlus.turnOn();
    } catch (e) {
      print('❌ Error turning on Bluetooth: $e');
      rethrow;
    }
  }

  void dispose() {
    _notificationSubscription?.cancel();
    _responseController.close();
  }
}
