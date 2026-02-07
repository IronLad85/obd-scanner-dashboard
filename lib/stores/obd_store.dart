import 'package:mobx/mobx.dart';
import '../services/obd_service.dart';
import '../services/obd_command.dart';
import '../services/obd_response.dart';
import '../services/connection_type.dart';

part 'obd_store.g.dart';

class ObdStore = _ObdStore with _$ObdStore;

abstract class _ObdStore with Store {
  final ObdService _obdService = ObdService();

  @observable
  bool isConnected = false;

  @observable
  bool isInitialized = false;

  @observable
  bool isMonitoring = false;

  @observable
  ConnectionType selectedConnectionType = ConnectionType.tcp;

  @observable
  String address = 'localhost';

  @observable
  String port = '35000';

  // Live parameter observables - only trigger rebuilds when values change
  @observable
  double? rpm;

  @observable
  double? speedKmh;

  @observable
  double? coolantTempC;

  @observable
  double? throttlePercent;

  @observable
  double? batteryVoltage;

  @observable
  double? engineLoadPercent;

  @observable
  ObservableList<ObdResponse> responses = ObservableList<ObdResponse>();

  _ObdStore() {
    _obdService.parsedResponseStream.listen(_handleResponse);
  }

  void _handleResponse(ObdResponse response) {
    // Add to history
    runInAction(() {
      responses.insert(0, response);
      if (responses.length > 30) {
        responses.removeLast();
      }
    });

    // Update specific observables only if value changed
    if (response is RpmResponse) {
      final newRpm = response.rpm.toDouble();
      if (rpm != newRpm) {
        runInAction(() => rpm = newRpm);
      }
    } else if (response is SpeedResponse) {
      final newSpeed = response.speedKmh.toDouble();
      if (speedKmh != newSpeed) {
        runInAction(() => speedKmh = newSpeed);
      }
    } else if (response is TemperatureResponse &&
        response.command == ObdCommand.engineCoolantTemp) {
      final newTemp = response.temperatureCelsius.toDouble();
      if (coolantTempC != newTemp) {
        runInAction(() => coolantTempC = newTemp);
      }
    } else if (response is PercentageResponse &&
        response.command == ObdCommand.throttlePosition) {
      final newThrottle = response.percentage;
      if (throttlePercent != newThrottle) {
        runInAction(() => throttlePercent = newThrottle);
      }
    } else if (response is VoltageResponse) {
      final newVoltage = response.voltage;
      if (batteryVoltage != newVoltage) {
        runInAction(() => batteryVoltage = newVoltage);
      }
    } else if (response is PercentageResponse &&
        response.command == ObdCommand.calculatedEngineLoad) {
      final newLoad = response.percentage;
      if (engineLoadPercent != newLoad) {
        runInAction(() => engineLoadPercent = newLoad);
      }
    }
  }

  @action
  void setConnectionType(ConnectionType type) {
    selectedConnectionType = type;
  }

  @action
  void setAddress(String value) {
    address = value;
  }

  @action
  void setPort(String value) {
    port = value;
  }

  @action
  Future<void> connect() async {
    try {
      ConnectionConfig config;

      if (selectedConnectionType == ConnectionType.tcp) {
        config = ConnectionConfig.tcp(address: address, port: int.parse(port));
      } else {
        config = ConnectionConfig.bluetooth(deviceId: 'DEVICE_ADDRESS');
      }

      await _obdService.connect(config);
      isConnected = true;
    } catch (e) {
      throw Exception('Connection failed: $e');
    }
  }

  @action
  Future<void> disconnect() async {
    await _obdService.disconnect();
    isConnected = false;
    isInitialized = false;
    isMonitoring = false;
  }

  @action
  Future<void> initializeAndStartMonitoring() async {
    // Send reset command
    await _obdService.sendCommand(ObdCommand.reset);
    await Future.delayed(const Duration(milliseconds: 500));

    isInitialized = true;

    // Start continuous monitoring (each command uses its ideal polling interval)
    _obdService.startContinuousMonitoring([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.throttlePosition,
      ObdCommand.batteryVoltage,
      ObdCommand.calculatedEngineLoad,
    ], commandDelay: const Duration(milliseconds: 5));

    isMonitoring = true;
  }

  @action
  void stopMonitoring() {
    _obdService.stopContinuousMonitoring();
    isMonitoring = false;
  }

  @action
  Future<void> singleBatchQuery() async {
    await _obdService.quickPoll([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.throttlePosition,
      ObdCommand.batteryVoltage,
      ObdCommand.calculatedEngineLoad,
    ]);
  }

  @action
  Future<void> sendCommand(String commandCode) async {
    final command = ObdCommand.fromCode(commandCode);
    if (command == null) {
      throw Exception('Invalid command code');
    }
    await _obdService.sendCommand(command);
  }

  @action
  void clearResponses() {
    responses.clear();
  }

  void dispose() {
    _obdService.dispose();
  }
}
