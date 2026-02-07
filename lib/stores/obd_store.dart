import 'dart:async';
import 'package:mobx/mobx.dart';
import '../services/obd_service.dart';
import '../services/obd_command.dart';
import '../services/obd_response.dart';
import '../services/connection_type.dart';
import '../services/driving_advisor_service.dart';
import '../services/voice_advisor_service.dart';

part 'obd_store.g.dart';

class ObdStore = _ObdStore with _$ObdStore;

abstract class _ObdStore with Store {
  final ObdService _obdService = ObdService();
  final DrivingAdvisorService _advisorService = DrivingAdvisorService();
  final VoiceAdvisorService _voiceService = VoiceAdvisorService();

  Timer? _voiceCheckTimer;

  @observable
  bool isConnected = false;

  @observable
  bool voiceAnnouncementsEnabled = true;

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
  double? oilTempC;

  @observable
  double? throttlePercent;

  @observable
  double? batteryVoltage;

  @observable
  double? engineLoadPercent;

  @observable
  double? mafGramsPerSecond;

  @observable
  double? intakeAirTempC;

  @observable
  double? fuelRateLph;

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
    } else if (response is TemperatureResponse &&
        response.command == ObdCommand.engineOilTemp) {
      final newTemp = response.temperatureCelsius.toDouble();
      if (oilTempC != newTemp) {
        runInAction(() => oilTempC = newTemp);
      }
    } else if (response is TemperatureResponse &&
        response.command == ObdCommand.intakeAirTemp) {
      final newTemp = response.temperatureCelsius.toDouble();
      if (intakeAirTempC != newTemp) {
        runInAction(() => intakeAirTempC = newTemp);
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
    } else if (response is AirflowResponse) {
      final newMaf = response.gramsPerSecond;
      if (mafGramsPerSecond != newMaf) {
        runInAction(() => mafGramsPerSecond = newMaf);
      }
    } else if (response is FuelRateResponse) {
      final newFuelRate = response.litersPerHour;
      if (fuelRateLph != newFuelRate) {
        runInAction(() => fuelRateLph = newFuelRate);
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
      print('❌ Connection failed: $e');
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

    // Start voice announcement checker
    _startVoiceAnnouncementTimer();

    // Start continuous monitoring (each command uses its ideal polling interval)
    _obdService.startContinuousMonitoring([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.engineOilTemp,
      ObdCommand.intakeAirTemp,
      ObdCommand.engineFuelRate,
      ObdCommand.throttlePosition,
      ObdCommand.batteryVoltage,
      ObdCommand.calculatedEngineLoad,
      ObdCommand.mafAirFlow,
    ], commandDelay: const Duration(milliseconds: 5));

    isMonitoring = true;
  }

  @action
  void stopMonitoring() {
    _obdService.stopContinuousMonitoring();
    isMonitoring = false;
    _stopVoiceAnnouncementTimer();
  }

  @action
  Future<void> singleBatchQuery() async {
    await _obdService.quickPoll([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.engineOilTemp,
      ObdCommand.intakeAirTemp,
      ObdCommand.engineFuelRate,
      ObdCommand.throttlePosition,
      ObdCommand.batteryVoltage,
      ObdCommand.mafAirFlow,
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

  /// Get current driving advisories based on all OBD2 parameters
  List<DrivingAdvisory> getDrivingAdvisories() {
    return _advisorService.analyzeAllParameters(
      rpm: rpm,
      speedKmh: speedKmh,
      coolantTempC: coolantTempC,
      oilTempC: oilTempC,
      intakeAirTempC: intakeAirTempC,
      throttlePercent: throttlePercent,
      engineLoadPercent: engineLoadPercent,
      mafGramsPerSecond: mafGramsPerSecond,
      fuelRateLph: fuelRateLph,
      batteryVoltage: batteryVoltage,
    );
  }

  /// Get the most critical advisory
  DrivingAdvisory? getTopAdvisory() {
    final advisories = getDrivingAdvisories();
    return _advisorService.getTopPriorityAdvisory(advisories);
  }

  /// Get advisories grouped by category
  Map<String, List<DrivingAdvisory>> getAdvisoriesByCategory() {
    final advisories = getDrivingAdvisories();
    return _advisorService.getAdvisoriesByCategory(advisories);
  }

  /// Calculate overall driving efficiency score (0-100)
  int getDrivingScore() {
    return _advisorService.calculateDrivingScore(
      rpm: rpm,
      throttlePercent: throttlePercent,
      engineLoadPercent: engineLoadPercent,
      coolantTempC: coolantTempC,
      oilTempC: oilTempC,
      fuelRateLph: fuelRateLph,
    );
  }

  /// Enable voice announcements
  @action
  void enableVoiceAnnouncements() {
    voiceAnnouncementsEnabled = true;
    _voiceService.enable();
  }

  /// Disable voice announcements
  @action
  void disableVoiceAnnouncements() {
    voiceAnnouncementsEnabled = false;
    _voiceService.disable();
  }

  /// Toggle voice announcements
  @action
  void toggleVoiceAnnouncements() {
    if (voiceAnnouncementsEnabled) {
      disableVoiceAnnouncements();
    } else {
      enableVoiceAnnouncements();
    }
  }

  /// Test voice announcement
  Future<void> testVoice() async {
    await _voiceService.testVoice();
  }

  /// Start periodic voice announcement checking
  void _startVoiceAnnouncementTimer() {
    _voiceCheckTimer?.cancel();

    // Check for advisories every 5 seconds and announce if needed
    _voiceCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (voiceAnnouncementsEnabled && isMonitoring) {
        final advisories = getDrivingAdvisories();
        _voiceService.announceTopAdvisory(advisories);
      }
    });
  }

  /// Stop voice announcement timer
  void _stopVoiceAnnouncementTimer() {
    _voiceCheckTimer?.cancel();
    _voiceCheckTimer = null;
  }

  void dispose() {
    _stopVoiceAnnouncementTimer();
    _voiceService.dispose();
    _obdService.dispose();
  }
}
