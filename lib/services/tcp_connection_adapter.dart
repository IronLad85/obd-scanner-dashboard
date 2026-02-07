import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'obd_connection_interface.dart';

class TcpConnectionAdapter implements ObdConnectionInterface {
  final String address;
  final int port;

  Socket? _socket;
  final StreamController<String> _responseController =
      StreamController<String>.broadcast();
  bool _isConnected = false;

  TcpConnectionAdapter({required this.address, required this.port});

  @override
  bool get isConnected => _isConnected;

  @override
  Stream<String> get responseStream => _responseController.stream;

  @override
  Future<void> connect() async {
    try {
      _socket = await Socket.connect(address, port);
      _isConnected = true;

      _socket!.listen(
        (data) {
          final response = utf8.decode(data).trim();
          if (response.isNotEmpty && !_responseController.isClosed) {
            try {
              _responseController.add(response);
            } catch (e) {
              // Ignore StreamSink errors if controller is closed
            }
          }
        },
        onError: (error) {
          _isConnected = false;
          if (!_responseController.isClosed) {
            try {
              _responseController.addError(error);
            } catch (e) {
              // Ignore StreamSink errors if controller is closed
            }
          }
        },
        onDone: () {
          _isConnected = false;
        },
      );
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    await _socket?.close();
    _socket = null;
    _isConnected = false;
  }

  @override
  Future<void> sendCommand(String command) async {
    if (!_isConnected || _socket == null) {
      throw Exception('Not connected to TCP server');
    }
    _socket!.write('$command\r');
    await _socket!.flush();
  }

  void dispose() {
    _responseController.close();
    _socket?.close();
  }
}
