import 'obd_command.dart';
import 'obd_response.dart';

class ObdParserService {
  static ObdResponse parseResponse(ObdCommand command, String rawResponse) {
    final cleanResponse = _cleanResponse(rawResponse);

    try {
      switch (command.responseType) {
        case ObdResponseType.status:
          return _parseStatus(command, rawResponse, cleanResponse);

        case ObdResponseType.voltage:
          return _parseVoltage(command, rawResponse, cleanResponse);

        case ObdResponseType.rpm:
          return _parseRpm(command, rawResponse, cleanResponse);

        case ObdResponseType.speed:
          return _parseSpeed(command, rawResponse, cleanResponse);

        case ObdResponseType.temperature:
          return _parseTemperature(command, rawResponse, cleanResponse);

        case ObdResponseType.percentage:
          return _parsePercentage(command, rawResponse, cleanResponse);

        case ObdResponseType.pressure:
          return _parsePressure(command, rawResponse, cleanResponse);

        case ObdResponseType.airflow:
          return _parseAirflow(command, rawResponse, cleanResponse);

        case ObdResponseType.fuelTrim:
          return _parseFuelTrim(command, rawResponse, cleanResponse);

        case ObdResponseType.angle:
          return _parseAngle(command, rawResponse, cleanResponse);

        case ObdResponseType.bitmap:
          return _parseBitmap(command, rawResponse, cleanResponse);

        case ObdResponseType.dtc:
          return _parseDtc(command, rawResponse, cleanResponse);

        case ObdResponseType.text:
          return _parseText(command, rawResponse, cleanResponse);
      }
    } catch (e) {
      return StatusResponse(
        command: command,
        rawResponse: rawResponse,
        success: false,
        message: 'Parse error: $e',
      );
    }
  }

  static String _cleanResponse(String response) {
    return response
        .toUpperCase()
        .replaceAll('\r', '')
        .replaceAll('\n', '')
        .replaceAll('>', '')
        .replaceAll('SEARCHING...', '')
        .trim();
  }

  static List<int> _extractBytes(String response, String command) {
    final responseCode = (int.parse(command.substring(0, 2), radix: 16) + 0x40)
        .toRadixString(16)
        .toUpperCase();

    final parts = response.split(responseCode);
    if (parts.length < 2) return [];

    final dataHex = parts[1].replaceAll(' ', '');
    final bytes = <int>[];
    for (int i = 0; i < dataHex.length; i += 2) {
      if (i + 2 <= dataHex.length) {
        bytes.add(int.parse(dataHex.substring(i, i + 2), radix: 16));
      }
    }
    return bytes;
  }

  static StatusResponse _parseStatus(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final success =
        clean.contains('OK') ||
        clean.isEmpty ||
        !clean.contains('ERROR') && !clean.contains('?');
    return StatusResponse(
      command: command,
      rawResponse: raw,
      success: success,
      message: clean,
    );
  }

  static VoltageResponse _parseVoltage(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final regex = RegExp(r'(\d+\.?\d*)V?');
    final match = regex.firstMatch(clean);
    if (match != null) {
      final voltage = double.parse(match.group(1)!);
      return VoltageResponse(
        command: command,
        rawResponse: raw,
        voltage: voltage,
      );
    }
    throw Exception('Invalid voltage response: $clean');
  }

  static RpmResponse _parseRpm(ObdCommand command, String raw, String clean) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.length >= 2) {
      final rpm = ((bytes[0] * 256) + bytes[1]) ~/ 4;
      return RpmResponse(command: command, rawResponse: raw, rpm: rpm);
    }
    throw Exception('Invalid RPM response: $clean');
  }

  static SpeedResponse _parseSpeed(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.isNotEmpty) {
      return SpeedResponse(
        command: command,
        rawResponse: raw,
        speedKmh: bytes[0],
      );
    }
    throw Exception('Invalid speed response: $clean');
  }

  static TemperatureResponse _parseTemperature(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.isNotEmpty) {
      return TemperatureResponse(
        command: command,
        rawResponse: raw,
        temperatureCelsius: bytes[0] - 40,
      );
    }
    throw Exception('Invalid temperature response: $clean');
  }

  static PercentageResponse _parsePercentage(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.isNotEmpty) {
      final percentage = (bytes[0] * 100.0) / 255.0;
      return PercentageResponse(
        command: command,
        rawResponse: raw,
        percentage: percentage,
      );
    }
    throw Exception('Invalid percentage response: $clean');
  }

  static PressureResponse _parsePressure(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.isNotEmpty) {
      int pressure;
      if (command == ObdCommand.fuelPressure) {
        pressure = bytes[0] * 3;
      } else {
        pressure = bytes[0];
      }
      return PressureResponse(
        command: command,
        rawResponse: raw,
        pressureKpa: pressure,
      );
    }
    throw Exception('Invalid pressure response: $clean');
  }

  static AirflowResponse _parseAirflow(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.length >= 2) {
      final gps = ((bytes[0] * 256) + bytes[1]) / 100.0;
      return AirflowResponse(
        command: command,
        rawResponse: raw,
        gramsPerSecond: gps,
      );
    }
    throw Exception('Invalid airflow response: $clean');
  }

  static FuelTrimResponse _parseFuelTrim(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.isNotEmpty) {
      final percentage = (bytes[0] - 128.0) * 100.0 / 128.0;
      return FuelTrimResponse(
        command: command,
        rawResponse: raw,
        percentage: percentage,
      );
    }
    throw Exception('Invalid fuel trim response: $clean');
  }

  static AngleResponse _parseAngle(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    if (bytes.isNotEmpty) {
      final degrees = (bytes[0] / 2.0) - 64.0;
      return AngleResponse(
        command: command,
        rawResponse: raw,
        degrees: degrees,
      );
    }
    throw Exception('Invalid angle response: $clean');
  }

  static BitmapResponse _parseBitmap(
    ObdCommand command,
    String raw,
    String clean,
  ) {
    final bytes = _extractBytes(clean, command.code);
    final supportedPids = <int>[];

    for (int i = 0; i < bytes.length; i++) {
      for (int bit = 0; bit < 8; bit++) {
        if ((bytes[i] & (1 << (7 - bit))) != 0) {
          supportedPids.add((i * 8) + bit + 1);
        }
      }
    }

    return BitmapResponse(
      command: command,
      rawResponse: raw,
      supportedPids: supportedPids,
    );
  }

  static DtcResponse _parseDtc(ObdCommand command, String raw, String clean) {
    final codes = <String>[];
    final dataHex = clean.replaceAll(' ', '');

    if (dataHex.length >= 4) {
      final numCodes = int.parse(dataHex.substring(2, 4), radix: 16);

      if (numCodes > 0 && dataHex.length >= 4 + (numCodes * 4)) {
        for (int i = 0; i < numCodes; i++) {
          final offset = 4 + (i * 4);
          if (offset + 4 <= dataHex.length) {
            final dtcHex = dataHex.substring(offset, offset + 4);
            final dtcCode = _decodeDtc(dtcHex);
            if (dtcCode != 'P0000') {
              codes.add(dtcCode);
            }
          }
        }
      }
    }

    return DtcResponse(command: command, rawResponse: raw, codes: codes);
  }

  static String _decodeDtc(String hex) {
    final value = int.parse(hex, radix: 16);
    final firstChar = ['P', 'C', 'B', 'U'][(value >> 14) & 0x03];
    final secondChar = ((value >> 12) & 0x03).toString();
    final thirdChar = ((value >> 8) & 0x0F).toRadixString(16).toUpperCase();
    final fourthChar = ((value >> 4) & 0x0F).toRadixString(16).toUpperCase();
    final fifthChar = (value & 0x0F).toRadixString(16).toUpperCase();

    return '$firstChar$secondChar$thirdChar$fourthChar$fifthChar';
  }

  static TextResponse _parseText(ObdCommand command, String raw, String clean) {
    final hex = clean.replaceAll(' ', '');
    final text = StringBuffer();

    for (int i = 0; i < hex.length; i += 2) {
      if (i + 2 <= hex.length) {
        final charCode = int.parse(hex.substring(i, i + 2), radix: 16);
        if (charCode >= 32 && charCode <= 126) {
          text.writeCharCode(charCode);
        }
      }
    }

    return TextResponse(
      command: command,
      rawResponse: raw,
      text: text.toString(),
    );
  }
}
