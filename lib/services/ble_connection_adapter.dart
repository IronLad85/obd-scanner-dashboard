import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
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
      // Request permissions before connecting
      final hasPermission = await requestBluetoothPermissions();
      if (!hasPermission) {
        throw Exception('Bluetooth permissions not granted');
      }

      // Check if already connected
      final currentState = await device.connectionState.first;
      print('📱 Current connection state: $currentState');

      // If already connected, disconnect first to start fresh
      if (currentState == BluetoothConnectionState.connected) {
        print('⚠️ Device already connected, disconnecting first...');
        try {
          await device.disconnect();
          await Future.delayed(const Duration(milliseconds: 1000));
        } catch (e) {
          print('⚠️ Error during pre-disconnect: $e');
        }
      }

      // Connect to device with increased timeout
      print('🔄 Attempting to connect...');
      await device.connect(
        license: License.free,
        timeout: const Duration(seconds: 30),
        autoConnect: false,
      );

      // Wait for connection to stabilize
      await Future.delayed(const Duration(milliseconds: 1000));

      // Verify we're actually connected
      final connectedState = await device.connectionState.first;
      if (connectedState != BluetoothConnectionState.connected) {
        throw Exception(
          'Connection state verification failed: $connectedState',
        );
      }

      print('✅ Connection established, discovering services...');

      // Discover services
      final services = await device.discoverServices();
      print('📡 Found ${services.length} services');

      // Find OBD service
      BluetoothService? obdService;
      for (final service in services) {
        final serviceUuid = service.uuid.toString().toLowerCase();
        print('  Service: $serviceUuid');
        if (serviceUuid == _obdServiceUuid) {
          obdService = service;
          break;
        }
      }

      if (obdService == null) {
        print(
          '❌ Available services: ${services.map((s) => s.uuid.toString()).join(", ")}',
        );
        throw Exception(
          'OBD-II service ($_obdServiceUuid) not found on device',
        );
      }

      print('✅ OBD service found, looking for characteristics...');

      // Find write and notify characteristics
      for (final characteristic in obdService.characteristics) {
        final uuid = characteristic.uuid.toString().toLowerCase();
        print(
          '  Characteristic: $uuid (properties: ${characteristic.properties})',
        );

        if (uuid == _writeCharacteristicUuid) {
          _writeCharacteristic = characteristic;
        } else if (uuid == _notifyCharacteristicUuid) {
          _notifyCharacteristic = characteristic;
        }
      }

      if (_writeCharacteristic == null || _notifyCharacteristic == null) {
        print(
          '❌ Write char: $_writeCharacteristic, Notify char: $_notifyCharacteristic',
        );
        throw Exception('Required BLE characteristics not found');
      }

      print('✅ Characteristics found, subscribing to notifications...');

      // Subscribe to notifications
      await _notifyCharacteristic!.setNotifyValue(true);
      _notificationSubscription = _notifyCharacteristic!.onValueReceived.listen(
        _handleNotification,
        onError: (error) {
          print('❌ BLE notification error: $error');
        },
      );

      _isConnected = true;
      print('✅ BLE connected successfully and ready for communication');
    } catch (e) {
      _isConnected = false;
      print('❌ BLE connection failed: $e');

      // Try to cleanup on failure
      try {
        await device.disconnect();
      } catch (_) {}

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
    print('🔌 Disconnecting from BLE device...');
    _isConnected = false;

    await _notificationSubscription?.cancel();
    _notificationSubscription = null;

    try {
      if (_notifyCharacteristic != null) {
        await _notifyCharacteristic!.setNotifyValue(false);
      }
    } catch (e) {
      print('⚠️ Error disabling notifications: $e');
    }

    try {
      await device.disconnect();
      print('✅ BLE device disconnected');
    } catch (e) {
      print('⚠️ Error disconnecting BLE device: $e');
    }

    _writeCharacteristic = null;
    _notifyCharacteristic = null;
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

  /// Request necessary Bluetooth permissions based on platform and Android version
  static Future<bool> requestBluetoothPermissions() async {
    if (!Platform.isAndroid) {
      return true; // iOS handles permissions differently
    }

    try {
      // For Android 12+ (API 31+), we need BLUETOOTH_SCAN and BLUETOOTH_CONNECT
      if (await _isAndroid12OrHigher()) {
        final scanStatus = await Permission.bluetoothScan.request();
        final connectStatus = await Permission.bluetoothConnect.request();

        if (scanStatus.isDenied || connectStatus.isDenied) {
          print('❌ Bluetooth permissions denied');
          return false;
        }

        if (scanStatus.isPermanentlyDenied ||
            connectStatus.isPermanentlyDenied) {
          print(
            '❌ Bluetooth permissions permanently denied. Please enable in settings.',
          );
          await openAppSettings();
          return false;
        }

        return scanStatus.isGranted && connectStatus.isGranted;
      } else {
        // For Android 11 and below, we need location permissions
        final locationStatus = await Permission.locationWhenInUse.request();

        if (locationStatus.isDenied) {
          print('❌ Location permission denied');
          return false;
        }

        if (locationStatus.isPermanentlyDenied) {
          print(
            '❌ Location permission permanently denied. Please enable in settings.',
          );
          await openAppSettings();
          return false;
        }

        return locationStatus.isGranted;
      }
    } catch (e) {
      print('❌ Error requesting Bluetooth permissions: $e');
      return false;
    }
  }

  /// Check if device is running Android 12 (API 31) or higher
  static Future<bool> _isAndroid12OrHigher() async {
    if (!Platform.isAndroid) return false;

    // Check Android version through permission availability
    // BLUETOOTH_SCAN is only available on Android 12+
    return await Permission.bluetoothScan.status != PermissionStatus.restricted;
  }

  /// Scan for nearby BLE devices
  static Future<List<BluetoothDevice>> scanForDevices({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final devices = <BluetoothDevice>[];
    final Set<String> deviceIds = {};

    // Request Bluetooth permissions first
    final hasPermission = await requestBluetoothPermissions();
    if (!hasPermission) {
      throw Exception('Bluetooth permissions not granted');
    }

    // Check if Bluetooth is on
    try {
      if (await FlutterBluePlus.isSupported == false) {
        throw Exception('Bluetooth not supported on this device');
      }

      print('🔍 Starting BLE scan for ${timeout.inSeconds} seconds...');

      // Start scanning
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation:
            false, // Not needed for Android 12+ with neverForLocation
      );

      // Listen to scan results
      final subscription = FlutterBluePlus.scanResults.listen((results) {
        for (final result in results) {
          final deviceId = result.device.remoteId.toString();
          if (!deviceIds.contains(deviceId)) {
            deviceIds.add(deviceId);
            devices.add(result.device);
            final name = result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown';
            print('📱 Found device: $name ($deviceId) - RSSI: ${result.rssi}');
          }
        }
      });

      // Wait for scan to complete
      await Future.delayed(timeout);
      await subscription.cancel();
      await FlutterBluePlus.stopScan();

      print('✅ Scan complete. Found ${devices.length} devices');
      return devices;
    } catch (e) {
      print('❌ BLE scan error: $e');
      try {
        await FlutterBluePlus.stopScan();
      } catch (_) {}
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

  /// Check if a specific device is already connected
  static Future<bool> isDeviceConnected(BluetoothDevice device) async {
    try {
      final state = await device.connectionState.first.timeout(
        const Duration(seconds: 2),
      );
      return state == BluetoothConnectionState.connected;
    } catch (e) {
      print('⚠️ Error checking device connection state: $e');
      return false;
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
