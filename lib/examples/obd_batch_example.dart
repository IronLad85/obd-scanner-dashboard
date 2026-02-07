import 'package:flutter/material.dart';
import '../services/obd_service.dart';
import '../services/obd_command.dart';
import '../services/obd_response.dart';
import '../services/connection_type.dart';

class ObdBatchExample extends StatefulWidget {
  const ObdBatchExample({super.key});

  @override
  State<ObdBatchExample> createState() => _ObdBatchExampleState();
}

class _ObdBatchExampleState extends State<ObdBatchExample> {
  final ObdService _obdService = ObdService();
  final Map<ObdCommand, ObdResponse?> _latestValues = {};
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _obdService.parsedResponseStream.listen((response) {
      setState(() {
        _latestValues[response.command] = response;
      });
    });
  }

  @override
  void dispose() {
    _obdService.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    await _obdService.connect(
      ConnectionConfig.tcp(address: 'localhost', port: 35000),
    );
    await _obdService.initialize();
    setState(() => _isConnected = true);
  }

  Future<void> _singleBatchQuery() async {
    final results = await _obdService.sendBatch([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.throttlePosition,
      ObdCommand.batteryVoltage,
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Batch returned ${results.length} results')),
      );
    }
  }

  Future<void> _quickPoll() async {
    final results = await _obdService.quickPoll([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.throttlePosition,
    ]);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Quick poll: ${results.length} results')),
      );
    }
  }

  void _startMonitoring() {
    _obdService.startContinuousMonitoring([
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.throttlePosition,
    ]);
    setState(() {});
  }

  void _stopMonitoring() {
    _obdService.stopContinuousMonitoring();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OBD Batch Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: _isConnected ? null : _connect,
              child: const Text('Connect & Initialize'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isConnected ? _singleBatchQuery : null,
              child: const Text('Send Batch (5 commands)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isConnected ? _quickPoll : null,
              child: const Text('Quick Poll (3 commands)'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isConnected && !_obdService.isMonitoring
                  ? _startMonitoring
                  : null,
              child: const Text('Start Continuous Monitoring'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _obdService.isMonitoring ? _stopMonitoring : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Stop Monitoring'),
            ),
            const SizedBox(height: 16),
            Text(
              'Monitoring: ${_obdService.isMonitoring ? "Active" : "Stopped"}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: ListView(
                  children: [
                    _buildValueTile('RPM', _latestValues[ObdCommand.engineRpm]),
                    _buildValueTile(
                      'Speed',
                      _latestValues[ObdCommand.vehicleSpeed],
                    ),
                    _buildValueTile(
                      'Coolant Temp',
                      _latestValues[ObdCommand.engineCoolantTemp],
                    ),
                    _buildValueTile(
                      'Throttle',
                      _latestValues[ObdCommand.throttlePosition],
                    ),
                    _buildValueTile(
                      'Battery',
                      _latestValues[ObdCommand.batteryVoltage],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildValueTile(String label, ObdResponse? response) {
    String value = '--';
    if (response != null) {
      if (response is RpmResponse) {
        value = '${response.rpm} RPM';
      } else if (response is SpeedResponse) {
        value = '${response.speedKmh} km/h';
      } else if (response is TemperatureResponse) {
        value = '${response.temperatureCelsius}°C';
      } else if (response is PercentageResponse) {
        value = '${response.percentage.toStringAsFixed(1)}%';
      } else if (response is VoltageResponse) {
        value = '${response.voltage.toStringAsFixed(2)}V';
      }
    }

    return ListTile(
      title: Text(label),
      trailing: Text(
        value,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

void batchUsageExamples() async {
  final obdService = ObdService();

  await obdService.connect(
    ConnectionConfig.tcp(address: 'localhost', port: 35000),
  );
  await obdService.initialize();

  final batchResults = await obdService.sendBatch([
    ObdCommand.engineRpm,
    ObdCommand.vehicleSpeed,
    ObdCommand.engineCoolantTemp,
    ObdCommand.throttlePosition,
    ObdCommand.batteryVoltage,
  ]);

  for (final entry in batchResults.entries) {
    print('${entry.key.description}: ${entry.value}');
  }

  final quickResults = await obdService.quickPoll([
    ObdCommand.engineRpm,
    ObdCommand.vehicleSpeed,
  ]);

  print('Quick poll completed: ${quickResults.length} results');

  obdService.startContinuousMonitoring([
    ObdCommand.engineRpm,
    ObdCommand.vehicleSpeed,
    ObdCommand.throttlePosition,
  ]);

  obdService.parsedResponseStream.listen((response) {
    if (response is RpmResponse) {
      print('Real-time RPM: ${response.rpm}');
    }
  });

  await Future.delayed(const Duration(seconds: 10));
  obdService.stopContinuousMonitoring();

  await obdService.disconnect();
  obdService.dispose();
}
