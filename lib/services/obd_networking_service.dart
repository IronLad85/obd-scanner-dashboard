import 'dart:async';
import 'connection_type.dart';
import 'obd_connection_interface.dart';
import 'tcp_connection_adapter.dart';
import 'ble_connection_adapter.dart';

class ObdNetworkingService {
  ObdConnectionInterface? _currentConnection;
  ConnectionType? _currentConnectionType;

  final StreamController<String> _dataController =
      StreamController<String>.broadcast();
  StreamSubscription? _connectionSubscription;

  Stream<String> get dataStream => _dataController.stream;
  bool get isConnected => _currentConnection?.isConnected ?? false;
  ConnectionType? get currentConnectionType => _currentConnectionType;

  Future<void> connect(ConnectionConfig config) async {
    await disconnect();

    switch (config.type) {
      case ConnectionType.tcp:
        if (config.address == null || config.port == null) {
          throw Exception('TCP connection requires address and port');
        }
        _currentConnection = TcpConnectionAdapter(
          address: config.address!,
          port: config.port!,
        );
        break;

      case ConnectionType.bluetooth:
        if (config.bleDevice == null) {
          throw Exception('Bluetooth connection requires BLE device');
        }
        _currentConnection = BleConnectionAdapter(device: config.bleDevice!);
        break;
    }

    await _currentConnection!.connect();
    _currentConnectionType = config.type;

    _connectionSubscription = _currentConnection!.responseStream.listen(
      (data) {
        if (!_dataController.isClosed) {
          try {
            _dataController.add(data);
          } catch (e) {
            // Ignore StreamSink errors if controller is closed
          }
        }
      },
      onError: (error) {
        if (!_dataController.isClosed) {
          try {
            _dataController.addError(error);
          } catch (e) {
            // Ignore StreamSink errors if controller is closed
          }
        }
      },
    );
  }

  Future<void> disconnect() async {
    await _connectionSubscription?.cancel();
    _connectionSubscription = null;

    if (_currentConnection != null) {
      await _currentConnection!.disconnect();

      if (_currentConnection is TcpConnectionAdapter) {
        (_currentConnection as TcpConnectionAdapter).dispose();
      } else if (_currentConnection is BleConnectionAdapter) {
        (_currentConnection as BleConnectionAdapter).dispose();
      }

      _currentConnection = null;
      _currentConnectionType = null;
    }
  }

  Future<void> sendCommand(String command) async {
    if (_currentConnection == null || !isConnected) {
      throw Exception('Not connected');
    }
    await _currentConnection!.sendCommand(command);
  }

  Future<void> switchConnection(ConnectionConfig config) async {
    await disconnect();
    await connect(config);
  }

  Future<int> configureObd(String configJson) async {
    if (!isConnected) {
      throw Exception('Not connected');
    }

    final commands = _parseConfigJson(configJson);
    final startTime = DateTime.now();

    for (final command in commands) {
      await sendCommand(command);
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final elapsed = DateTime.now().difference(startTime);
    return elapsed.inMilliseconds;
  }

  List<String> _parseConfigJson(String json) {
    return [];
  }

  void dispose() {
    disconnect();
    _dataController.close();
  }
}
