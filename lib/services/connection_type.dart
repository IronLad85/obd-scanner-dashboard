import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum ConnectionType { tcp, bluetooth }

class ConnectionConfig {
  final ConnectionType type;
  final String? address;
  final int? port;
  final String? deviceId;
  final BluetoothDevice? bleDevice;

  ConnectionConfig({
    required this.type,
    this.address,
    this.port,
    this.deviceId,
    this.bleDevice,
  });

  ConnectionConfig.tcp({required String address, required int port})
    : this(type: ConnectionType.tcp, address: address, port: port);

  ConnectionConfig.bluetooth({String? deviceId, BluetoothDevice? bleDevice})
    : this(
        type: ConnectionType.bluetooth,
        deviceId: deviceId,
        bleDevice: bleDevice,
      );
}
