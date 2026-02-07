import 'dart:async';
import 'obd_networking_service.dart';
import 'obd_command.dart';
import 'obd_response.dart';
import 'obd_parser_service.dart';
import 'connection_type.dart';

class ObdService {
  final ObdNetworkingService _networkingService = ObdNetworkingService();
  final StreamController<ObdResponse> _parsedResponseController =
      StreamController<ObdResponse>.broadcast();

  final Map<String, Completer<ObdResponse>> _pendingCommands = {};
  final Map<String, DateTime> _commandTimestamps = {};
  final Map<String, DateTime> _lastPollTime = {};
  Timer? _continuousMonitoringTimer;
  Timer? _timeoutCleanupTimer;
  List<ObdCommand> _monitoringCommands = [];
  bool _isMonitoring = false;
  StreamSubscription<String>? _dataStreamSubscription;

  Stream<ObdResponse> get parsedResponseStream =>
      _parsedResponseController.stream;
  Stream<String> get rawResponseStream => _networkingService.dataStream;

  bool get isConnected => _networkingService.isConnected;
  ConnectionType? get currentConnectionType =>
      _networkingService.currentConnectionType;

  ObdService() {
    _dataStreamSubscription = _networkingService.dataStream.listen(
      _handleRawResponse,
    );
  }

  void _handleRawResponse(String rawResponse) {
    // Optimize: Extract command code from response and do O(1) lookup
    // Response format: "41 0C 1A F8" where 0C is the PID (010C command)
    final upperResponse = rawResponse.toUpperCase();

    // Try to match response code pattern (41 XX for mode 01 responses)
    final match = RegExp(r'41\s*([0-9A-F]{2})').firstMatch(upperResponse);
    if (match != null) {
      final pid = match.group(1);
      final commandCode = '01$pid';

      final completer = _pendingCommands[commandCode];
      if (completer != null && !completer.isCompleted) {
        final command = ObdCommand.fromCode(commandCode);
        if (command != null) {
          final parsedResponse = ObdParserService.parseResponse(
            command,
            rawResponse,
          );
          if (!_parsedResponseController.isClosed) {
            try {
              _parsedResponseController.add(parsedResponse);
            } catch (e) {
              // Ignore StreamSink errors if controller is closed
            }
          }
          completer.complete(parsedResponse);
        }
        _pendingCommands.remove(commandCode);
        _commandTimestamps.remove(commandCode);
        return;
      }
    }

    // Fallback: Check all pending commands (for non-standard responses)
    for (final entry in _pendingCommands.entries) {
      final commandCode = entry.key;
      final completer = entry.value;

      if (upperResponse.contains(commandCode.toUpperCase())) {
        final command = ObdCommand.fromCode(commandCode);
        if (command != null) {
          final parsedResponse = ObdParserService.parseResponse(
            command,
            rawResponse,
          );
          if (!_parsedResponseController.isClosed) {
            try {
              _parsedResponseController.add(parsedResponse);
            } catch (e) {
              // Ignore StreamSink errors if controller is closed
            }
          }

          if (!completer.isCompleted) {
            completer.complete(parsedResponse);
          }
        }

        _pendingCommands.remove(commandCode);
        _commandTimestamps.remove(commandCode);
        break;
      }
    }
  }

  Future<void> connect(ConnectionConfig config) async {
    await _networkingService.connect(config);
  }

  Future<void> disconnect() async {
    stopContinuousMonitoring();
    await _networkingService.disconnect();
    _pendingCommands.clear();
  }

  Future<ObdResponse> sendCommand(
    ObdCommand command, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (!isConnected) {
      throw Exception('Not connected to OBD device');
    }

    final completer = Completer<ObdResponse>();
    _pendingCommands[command.code] = completer;

    try {
      await _networkingService.sendCommand(command.code);

      final response = await completer.future.timeout(
        timeout,
        onTimeout: () {
          _pendingCommands.remove(command.code);
          return StatusResponse(
            command: command,
            rawResponse: '',
            success: false,
            message: 'Timeout',
          );
        },
      );

      return response;
    } catch (e) {
      _pendingCommands.remove(command.code);
      return StatusResponse(
        command: command,
        rawResponse: '',
        success: false,
        message: 'Error: $e',
      );
    }
  }

  Future<StatusResponse> initialize() async {
    final commands = [
      ObdCommand.reset,
      ObdCommand.echoOff,
      ObdCommand.linefeedOff,
      ObdCommand.spacesOff,
      ObdCommand.headersOn,
      ObdCommand.autoProtocol,
    ];

    for (final command in commands) {
      final response = await sendCommand(command);
      if (response is StatusResponse && !response.success) {
        return response;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return StatusResponse(
      command: ObdCommand.reset,
      rawResponse: 'OK',
      success: true,
      message: 'Initialization complete',
    );
  }

  Future<List<int>> getSupportedPids() async {
    final response = await sendCommand(ObdCommand.supportedPids);
    if (response is BitmapResponse) {
      return response.supportedPids;
    }
    return [];
  }

  Future<VoltageResponse?> getBatteryVoltage() async {
    final response = await sendCommand(ObdCommand.batteryVoltage);
    return response is VoltageResponse ? response : null;
  }

  Future<RpmResponse?> getEngineRpm() async {
    final response = await sendCommand(ObdCommand.engineRpm);
    return response is RpmResponse ? response : null;
  }

  Future<SpeedResponse?> getVehicleSpeed() async {
    final response = await sendCommand(ObdCommand.vehicleSpeed);
    return response is SpeedResponse ? response : null;
  }

  Future<TemperatureResponse?> getEngineCoolantTemp() async {
    final response = await sendCommand(ObdCommand.engineCoolantTemp);
    return response is TemperatureResponse ? response : null;
  }

  Future<TemperatureResponse?> getIntakeAirTemp() async {
    final response = await sendCommand(ObdCommand.intakeAirTemp);
    return response is TemperatureResponse ? response : null;
  }

  Future<PercentageResponse?> getThrottlePosition() async {
    final response = await sendCommand(ObdCommand.throttlePosition);
    return response is PercentageResponse ? response : null;
  }

  Future<PercentageResponse?> getEngineLoad() async {
    final response = await sendCommand(ObdCommand.calculatedEngineLoad);
    return response is PercentageResponse ? response : null;
  }

  Future<PressureResponse?> getIntakeManifoldPressure() async {
    final response = await sendCommand(ObdCommand.intakeManifoldPressure);
    return response is PressureResponse ? response : null;
  }

  Future<AirflowResponse?> getMafAirFlow() async {
    final response = await sendCommand(ObdCommand.mafAirFlow);
    return response is AirflowResponse ? response : null;
  }

  Future<AngleResponse?> getTimingAdvance() async {
    final response = await sendCommand(ObdCommand.timingAdvance);
    return response is AngleResponse ? response : null;
  }

  Future<DtcResponse?> getTroubleCodes() async {
    final response = await sendCommand(ObdCommand.troubleCodes);
    return response is DtcResponse ? response : null;
  }

  Future<StatusResponse> clearTroubleCodes() async {
    final response = await sendCommand(ObdCommand.clearTroubleCodes);
    return response is StatusResponse
        ? response
        : StatusResponse(
            command: ObdCommand.clearTroubleCodes,
            rawResponse: '',
            success: false,
            message: 'Failed to clear codes',
          );
  }

  Future<Map<ObdCommand, ObdResponse>> getMultipleParameters(
    List<ObdCommand> commands,
  ) async {
    final results = <ObdCommand, ObdResponse>{};

    for (final command in commands) {
      final response = await sendCommand(command);
      results[command] = response;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  Future<Map<ObdCommand, ObdResponse>> sendBatch(
    List<ObdCommand> commands, {
    Duration timeout = const Duration(seconds: 10),
    Duration delayBetweenCommands = const Duration(milliseconds: 50),
  }) async {
    if (!isConnected) {
      throw Exception('Not connected to OBD device');
    }

    final results = <ObdCommand, ObdResponse>{};
    final completers = <ObdCommand, Completer<ObdResponse>>{};

    for (final command in commands) {
      final completer = Completer<ObdResponse>();
      completers[command] = completer;
      _pendingCommands[command.code] = completer;
    }

    try {
      for (final command in commands) {
        await _networkingService.sendCommand(command.code);
        await Future.delayed(delayBetweenCommands);
      }

      final allFutures = completers.entries.map((entry) {
        return entry.value.future
            .timeout(
              timeout,
              onTimeout: () {
                _pendingCommands.remove(entry.key.code);
                return StatusResponse(
                  command: entry.key,
                  rawResponse: '',
                  success: false,
                  message: 'Timeout',
                );
              },
            )
            .then((response) {
              results[entry.key] = response;
            });
      });

      await Future.wait(allFutures);
    } catch (e) {
      for (final command in commands) {
        _pendingCommands.remove(command.code);
      }
    }

    return results;
  }

  void startContinuousMonitoring(
    List<ObdCommand> commands, {
    Duration commandDelay = const Duration(milliseconds: 5),
  }) {
    if (_isMonitoring) {
      stopContinuousMonitoring();
    }

    _monitoringCommands = commands;
    _isMonitoring = true;
    _lastPollTime.clear();

    // Cleanup timer to timeout stale requests every second
    _timeoutCleanupTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final timedOut = <String>[];

      _commandTimestamps.forEach((code, timestamp) {
        // Timeout after 2 seconds
        if (now.difference(timestamp).inSeconds >= 2) {
          timedOut.add(code);
        }
      });

      // Complete timed-out requests and remove them
      for (final code in timedOut) {
        final completer = _pendingCommands.remove(code);
        _commandTimestamps.remove(code);
        if (completer != null && !completer.isCompleted) {
          final command = ObdCommand.fromCode(code);
          if (command != null) {
            completer.complete(
              StatusResponse(
                command: command,
                rawResponse: '',
                success: false,
                message: 'Timeout - no response',
              ),
            );
          }
        }
      }

      // Also remove any completed completers
      _pendingCommands.removeWhere((code, completer) => completer.isCompleted);
    });

    // Use fast base rate (50ms) to check which commands need polling
    _continuousMonitoringTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) async {
        if (!_isMonitoring || !isConnected) {
          stopContinuousMonitoring();
          return;
        }

        final now = DateTime.now();

        // Check each command to see if its ideal interval has elapsed
        for (final command in _monitoringCommands) {
          if (!_isMonitoring) break;

          // Skip if this command type already has a pending request
          if (_pendingCommands.containsKey(command.code)) {
            continue;
          }

          // Get last poll time for this command
          final lastPoll = _lastPollTime[command.code];
          final idealInterval = command.idealPollingInterval;

          // Only poll if interval has elapsed (or never polled before)
          if (lastPoll == null || now.difference(lastPoll) >= idealInterval) {
            try {
              // Register completer and timestamp for this command
              final completer = Completer<ObdResponse>();
              _pendingCommands[command.code] = completer;
              _commandTimestamps[command.code] = now;
              _lastPollTime[command.code] = now;

              // Send command
              await _networkingService.sendCommand(command.code);

              // Minimal delay to prevent buffer overflow
              if (commandDelay.inMicroseconds > 0) {
                await Future.delayed(commandDelay);
              }
            } catch (e) {
              if (!_parsedResponseController.isClosed) {
                try {
                  _parsedResponseController.addError(e);
                } catch (_) {
                  // Ignore StreamSink errors if controller is closed
                }
              }
              // Clean up on error
              _pendingCommands.remove(command.code);
              _commandTimestamps.remove(command.code);
            }
          }
        }
        // Responses arrive asynchronously and are handled by _handleRawResponse
      },
    );
  }

  void stopContinuousMonitoring() {
    _isMonitoring = false;
    _continuousMonitoringTimer?.cancel();
    _continuousMonitoringTimer = null;
    _timeoutCleanupTimer?.cancel();
    _timeoutCleanupTimer = null;
    _monitoringCommands.clear();
    _commandTimestamps.clear();
    _lastPollTime.clear();
  }

  bool get isMonitoring => _isMonitoring;
  List<ObdCommand> get monitoringCommands =>
      List.unmodifiable(_monitoringCommands);

  Future<Map<ObdCommand, ObdResponse>> quickPoll(
    List<ObdCommand> commands,
  ) async {
    return sendBatch(
      commands,
      delayBetweenCommands: const Duration(milliseconds: 30),
      timeout: const Duration(seconds: 5),
    );
  }

  void dispose() {
    stopContinuousMonitoring();
    _dataStreamSubscription?.cancel();
    _networkingService.dispose();
    _parsedResponseController.close();
    _pendingCommands.clear();
    _commandTimestamps.clear();
    _lastPollTime.clear();
  }
}
