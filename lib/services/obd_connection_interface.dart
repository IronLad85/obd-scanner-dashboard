abstract class ObdConnectionInterface {
  Future<void> connect();
  Future<void> disconnect();
  Future<void> sendCommand(String command);
  Stream<String> get responseStream;
  bool get isConnected;
}
