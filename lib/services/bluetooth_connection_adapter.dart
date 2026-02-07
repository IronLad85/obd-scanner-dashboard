import 'dart:async';
import 'package:obd2_plugin/obd2_plugin.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'obd_connection_interface.dart';

export 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    show BluetoothDevice;

class BluetoothConnectionAdapter implements ObdConnectionInterface {
  final String deviceId;

  final Obd2Plugin _obd2 = Obd2Plugin();
  final StreamController<String> _responseController =
      StreamController<String>.broadcast();
  bool _isConnected = false;

  BluetoothConnectionAdapter({required this.deviceId});

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Future<void> connect() async {
    try {
      final devices = await _obd2.getPairedDevices;
      final targetDevice = devices.firstWhere(
        (device) => device.address == deviceId,
        orElse: () => throw Exception('Device not found'),
      );

      final completer = Completer<void>();

      _obd2.getConnection(
        targetDevice,
        (connection) {
          _isConnected = true;
          _setupDataListener();
          completer.complete();
        },
        (error) {
          _isConnected = false;
          completer.completeError(error);
        },
      );

      await completer.future;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  void _setupDataListener() {
    _obd2.setOnDataReceived((command, response, requestCode) {
      if (response.isNotEmpty && !_responseController.isClosed) {
        try {
          _responseController.add(response);
        } catch (e) {
          // Ignore StreamSink errors if controller is closed
        }
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!_isConnected) {
      throw Exception('Not connected to Bluetooth device');
    }
    await _obd2.configObdWithJSON(
      '''[{"command": "$command", "description": "", "status": true}]''',
    );
  }

  Future<List<BluetoothDevice>> getPairedDevices() async {
    return await _obd2.getPairedDevices;
  }

  Future<List<BluetoothDevice>> getNearbyDevices() async {
    return await _obd2.getNearbyDevices;
  }

  Future<bool> enableBluetooth() async {
    return await _obd2.enableBluetooth;
  }

  void dispose() {
    _responseController.close();
  }
}
