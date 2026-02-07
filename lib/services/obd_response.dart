import 'obd_command.dart';

abstract class ObdResponse {
  final ObdCommand command;
  final String rawResponse;
  final DateTime timestamp;

  ObdResponse({
    required this.command,
    required this.rawResponse,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

class StatusResponse extends ObdResponse {
  final bool success;
  final String? message;

  StatusResponse({
    required super.command,
    required super.rawResponse,
    required this.success,
    this.message,
    super.timestamp,
  });

  @override
  String toString() => 'StatusResponse(success: $success, message: $message)';
}

class VoltageResponse extends ObdResponse {
  final double voltage;

  VoltageResponse({
    required super.command,
    required super.rawResponse,
    required this.voltage,
    super.timestamp,
  });

  @override
  String toString() => 'VoltageResponse(${voltage.toStringAsFixed(2)}V)';
}

class RpmResponse extends ObdResponse {
  final int rpm;

  RpmResponse({
    required super.command,
    required super.rawResponse,
    required this.rpm,
    super.timestamp,
  });

  @override
  String toString() => 'RpmResponse($rpm RPM)';
}

class SpeedResponse extends ObdResponse {
  final int speedKmh;

  SpeedResponse({
    required super.command,
    required super.rawResponse,
    required this.speedKmh,
    super.timestamp,
  });

  int get speedMph => (speedKmh * 0.621371).round();

  @override
  String toString() => 'SpeedResponse($speedKmh km/h)';
}

class TemperatureResponse extends ObdResponse {
  final int temperatureCelsius;

  TemperatureResponse({
    required super.command,
    required super.rawResponse,
    required this.temperatureCelsius,
    super.timestamp,
  });

  int get temperatureFahrenheit => (temperatureCelsius * 9 / 5 + 32).round();

  @override
  String toString() => 'TemperatureResponse($temperatureCelsius°C)';
}

class PercentageResponse extends ObdResponse {
  final double percentage;

  PercentageResponse({
    required super.command,
    required super.rawResponse,
    required this.percentage,
    super.timestamp,
  });

  @override
  String toString() => 'PercentageResponse(${percentage.toStringAsFixed(1)}%)';
}

class PressureResponse extends ObdResponse {
  final int pressureKpa;

  PressureResponse({
    required super.command,
    required super.rawResponse,
    required this.pressureKpa,
    super.timestamp,
  });

  double get pressurePsi => pressureKpa * 0.145038;

  @override
  String toString() => 'PressureResponse($pressureKpa kPa)';
}

class AirflowResponse extends ObdResponse {
  final double gramsPerSecond;

  AirflowResponse({
    required super.command,
    required super.rawResponse,
    required this.gramsPerSecond,
    super.timestamp,
  });

  @override
  String toString() =>
      'AirflowResponse(${gramsPerSecond.toStringAsFixed(2)} g/s)';
}

class FuelTrimResponse extends ObdResponse {
  final double percentage;

  FuelTrimResponse({
    required super.command,
    required super.rawResponse,
    required this.percentage,
    super.timestamp,
  });

  @override
  String toString() => 'FuelTrimResponse(${percentage.toStringAsFixed(1)}%)';
}

class AngleResponse extends ObdResponse {
  final double degrees;

  AngleResponse({
    required super.command,
    required super.rawResponse,
    required this.degrees,
    super.timestamp,
  });

  @override
  String toString() => 'AngleResponse(${degrees.toStringAsFixed(1)}°)';
}

class BitmapResponse extends ObdResponse {
  final List<int> supportedPids;

  BitmapResponse({
    required super.command,
    required super.rawResponse,
    required this.supportedPids,
    super.timestamp,
  });

  @override
  String toString() => 'BitmapResponse(${supportedPids.length} PIDs)';
}

class DtcResponse extends ObdResponse {
  final List<String> codes;

  DtcResponse({
    required super.command,
    required super.rawResponse,
    required this.codes,
    super.timestamp,
  });

  @override
  String toString() =>
      'DtcResponse(${codes.length} codes: ${codes.join(", ")})';
}

class TextResponse extends ObdResponse {
  final String text;

  TextResponse({
    required super.command,
    required super.rawResponse,
    required this.text,
    super.timestamp,
  });

  @override
  String toString() => 'TextResponse($text)';
}
