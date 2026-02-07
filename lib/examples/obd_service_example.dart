import 'package:flutter/material.dart';
import '../services/obd_service.dart';
import '../services/obd_command.dart';
import '../services/obd_response.dart';
import '../services/connection_type.dart';

void exampleUsage() async {
  final obdService = ObdService();

  try {
    await obdService.connect(
      ConnectionConfig.tcp(address: 'localhost', port: 35000),
    );

    final initResult = await obdService.initialize();
    print('Initialized: ${initResult.success}');

    final rpm = await obdService.getEngineRpm();
    print('Engine RPM: ${rpm?.rpm}');

    final speed = await obdService.getVehicleSpeed();
    print('Speed: ${speed?.speedKmh} km/h');

    final temp = await obdService.getEngineCoolantTemp();
    print('Coolant Temp: ${temp?.temperatureCelsius}°C');

    final voltage = await obdService.getBatteryVoltage();
    print('Battery: ${voltage?.voltage}V');

    final dtcs = await obdService.getTroubleCodes();
    print('Trouble Codes: ${dtcs?.codes}');

    final multiResults = await obdService.getMultipleParameters([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.throttlePosition,
    ]);

    for (final entry in multiResults.entries) {
      print('${entry.key.description}: ${entry.value}');
    }

    obdService.parsedResponseStream.listen((response) {
      print('Parsed: $response');
    });

    await obdService.disconnect();
  } catch (e) {
    print('Error: $e');
  } finally {
    obdService.dispose();
  }
}

void commandEnumExample() {
  final command = ObdCommand.engineRpm;
  print('Command: ${command.code}');
  print('Description: ${command.description}');
  print('Response Type: ${command.responseType}');

  final foundCommand = ObdCommand.fromCode('010C');
  print('Found: ${foundCommand?.description}');

  for (final cmd in ObdCommand.values) {
    print('${cmd.code} - ${cmd.description}');
  }
}

void responseTypeExample(ObdResponse response) {
  if (response is RpmResponse) {
    print('Engine RPM: ${response.rpm}');
  } else if (response is SpeedResponse) {
    print('Speed: ${response.speedKmh} km/h (${response.speedMph} mph)');
  } else if (response is TemperatureResponse) {
    print(
      'Temp: ${response.temperatureCelsius}°C (${response.temperatureFahrenheit}°F)',
    );
  } else if (response is VoltageResponse) {
    print('Voltage: ${response.voltage}V');
  } else if (response is PercentageResponse) {
    print('Percentage: ${response.percentage}%');
  } else if (response is PressureResponse) {
    print(
      'Pressure: ${response.pressureKpa} kPa (${response.pressurePsi} psi)',
    );
  } else if (response is DtcResponse) {
    print('Trouble Codes: ${response.codes.join(", ")}');
    print('Count: ${response.codes.length}');
  } else if (response is StatusResponse) {
    print('Status: ${response.success}');
    print('Message: ${response.message}');
  }
}

class ObdServiceExample extends StatefulWidget {
  const ObdServiceExample({super.key});

  @override
  State<ObdServiceExample> createState() => _ObdServiceExampleState();
}

class _ObdServiceExampleState extends State<ObdServiceExample> {
  final ObdService _obdService = ObdService();
  String _status = 'Disconnected';

  @override
  void initState() {
    super.initState();

    _obdService.parsedResponseStream.listen((response) {
      setState(() {
        _status = response.toString();
      });
    });
  }

  @override
  void dispose() {
    _obdService.dispose();
    super.dispose();
  }

  Future<void> _connectAndRun() async {
    try {
      setState(() => _status = 'Connecting...');

      await _obdService.connect(
        ConnectionConfig.tcp(address: 'localhost', port: 35000),
      );

      setState(() => _status = 'Connected, initializing...');

      await _obdService.initialize();

      setState(() => _status = 'Initialized, querying RPM...');

      final rpm = await _obdService.getEngineRpm();
      setState(() => _status = 'RPM: ${rpm?.rpm ?? "N/A"}');

      final speed = await _obdService.getVehicleSpeed();
      setState(() => _status = 'Speed: ${speed?.speedKmh ?? "N/A"} km/h');
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OBD Service Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_status, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connectAndRun,
              child: const Text('Connect & Query'),
            ),
          ],
        ),
      ),
    );
  }
}
