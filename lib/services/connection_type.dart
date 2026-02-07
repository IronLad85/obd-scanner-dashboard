enum ConnectionType { tcp, bluetooth }

class ConnectionConfig {
  final ConnectionType type;
  final String? address;
  final int? port;
  final String? deviceId;

  ConnectionConfig({
    required this.type,
    this.address,
    this.port,
    this.deviceId,
  });

  ConnectionConfig.tcp({required String address, required int port})
    : this(type: ConnectionType.tcp, address: address, port: port);

  ConnectionConfig.bluetooth({required String deviceId})
    : this(type: ConnectionType.bluetooth, deviceId: deviceId);
}
