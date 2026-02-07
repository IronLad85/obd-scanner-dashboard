enum ObdCommand {
  reset('ATZ', ObdResponseType.status, 'Reset ELM327'),
  echoOff('ATE0', ObdResponseType.status, 'Echo Off'),
  linefeedOff('ATL0', ObdResponseType.status, 'Linefeed Off'),
  spacesOff('ATS0', ObdResponseType.status, 'Spaces Off'),
  headersOn('ATH1', ObdResponseType.status, 'Headers On'),
  autoProtocol('ATSP0', ObdResponseType.status, 'Auto Protocol'),
  batteryVoltage('ATRV', ObdResponseType.voltage, 'Battery Voltage'),

  supportedPids('0100', ObdResponseType.bitmap, 'Supported PIDs 01-20'),
  vinMake('0902', ObdResponseType.text, 'Vehicle Identification Number'),

  engineRpm('010C', ObdResponseType.rpm, 'Engine RPM'),
  vehicleSpeed('010D', ObdResponseType.speed, 'Vehicle Speed'),
  engineCoolantTemp(
    '0105',
    ObdResponseType.temperature,
    'Engine Coolant Temperature',
  ),
  intakeAirTemp('010F', ObdResponseType.temperature, 'Intake Air Temperature'),

  throttlePosition('0111', ObdResponseType.percentage, 'Throttle Position'),
  mafAirFlow('0110', ObdResponseType.airflow, 'MAF Air Flow Rate'),
  intakeManifoldPressure(
    '010B',
    ObdResponseType.pressure,
    'Intake Manifold Pressure',
  ),

  fuelSystemStatus('0103', ObdResponseType.status, 'Fuel System Status'),
  calculatedEngineLoad(
    '0104',
    ObdResponseType.percentage,
    'Calculated Engine Load',
  ),
  shortTermFuelTrim(
    '0106',
    ObdResponseType.fuelTrim,
    'Short Term Fuel Trim Bank 1',
  ),
  longTermFuelTrim(
    '0107',
    ObdResponseType.fuelTrim,
    'Long Term Fuel Trim Bank 1',
  ),

  timingAdvance('010E', ObdResponseType.angle, 'Timing Advance'),
  fuelPressure('010A', ObdResponseType.pressure, 'Fuel Pressure'),

  troubleCodes('03', ObdResponseType.dtc, 'Get Trouble Codes'),
  clearTroubleCodes('04', ObdResponseType.status, 'Clear Trouble Codes'),
  pendingTroubleCodes('07', ObdResponseType.dtc, 'Get Pending Trouble Codes');

  final String code;
  final ObdResponseType responseType;
  final String description;

  const ObdCommand(this.code, this.responseType, this.description);

  static ObdCommand? fromCode(String code) {
    try {
      return ObdCommand.values.firstWhere(
        (cmd) => cmd.code.toUpperCase() == code.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get the ideal polling interval for this command based on ELM327 best practices
  Duration get idealPollingInterval {
    switch (this) {
      // High priority (10-15 Hz): 70-100 ms
      case ObdCommand.engineRpm:
        return const Duration(milliseconds: 80);

      // High priority (5-10 Hz): 100-200 ms
      case ObdCommand.vehicleSpeed:
      case ObdCommand.throttlePosition:
        return const Duration(milliseconds: 150);

      // Medium priority (3-5 Hz): 200-300 ms
      case ObdCommand.calculatedEngineLoad:
        return const Duration(milliseconds: 250);

      // Medium priority (1-2 Hz): 500-1000 ms
      case ObdCommand.engineCoolantTemp:
      case ObdCommand.intakeAirTemp:
        return const Duration(milliseconds: 700);

      // Low priority (0.5-1 Hz): 1-2 seconds
      case ObdCommand.batteryVoltage:
        return const Duration(milliseconds: 1500);

      // Low priority (0.2-0.5 Hz): 2-5 seconds
      case ObdCommand.fuelPressure:
        return const Duration(milliseconds: 3000);

      // Default for other commands: 500ms
      default:
        return const Duration(milliseconds: 500);
    }
  }
}

enum ObdResponseType {
  status,
  voltage,
  rpm,
  speed,
  temperature,
  percentage,
  pressure,
  airflow,
  fuelTrim,
  angle,
  bitmap,
  dtc,
  text,
}
