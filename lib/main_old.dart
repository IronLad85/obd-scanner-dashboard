import 'package:flutter/material.dart';
import 'services/obd_service.dart';
import 'services/obd_command.dart';
import 'services/obd_response.dart';
import 'services/connection_type.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OBD Dashboard',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const ObdDashboard(),
    );
  }
}

class ObdDashboard extends StatefulWidget {
  const ObdDashboard({super.key});

  @override
  State<ObdDashboard> createState() => _ObdDashboardState();
}

class _ObdDashboardState extends State<ObdDashboard> {
  final ObdService _obdService = ObdService();
  final List<ObdResponse> _responses = [];
  bool _isConnected = false;
  bool _isInitialized = false;
  ConnectionType _selectedConnectionType = ConnectionType.tcp;

  // Live parameter values
  RpmResponse? _rpm;
  SpeedResponse? _speed;
  TemperatureResponse? _coolantTemp;
  PercentageResponse? _throttle;
  VoltageResponse? _voltage;
  PercentageResponse? _engineLoad;

  final TextEditingController _addressController = TextEditingController(
    text: 'localhost',
  );
  final TextEditingController _portController = TextEditingController(
    text: '35000',
  );
  final TextEditingController _commandController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Listen to parsed response stream
    _obdService.parsedResponseStream.listen((response) {
      setState(() {
        _responses.insert(0, response);
        if (_responses.length > 30) {
          _responses.removeLast();
        }

        // Update live gauge values
        if (response is RpmResponse) {
          _rpm = response;
        } else if (response is SpeedResponse) {
          _speed = response;
        } else if (response is TemperatureResponse &&
            response.command == ObdCommand.engineCoolantTemp) {
          _coolantTemp = response;
        } else if (response is PercentageResponse &&
            response.command == ObdCommand.throttlePosition) {
          _throttle = response;
        } else if (response is VoltageResponse) {
          _voltage = response;
        } else if (response is PercentageResponse &&
            response.command == ObdCommand.calculatedEngineLoad) {
          _engineLoad = response;
        }
      });
    });
  }

  @override
  void dispose() {
    _obdService.dispose();
    _addressController.dispose();
    _portController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    try {
      ConnectionConfig config;

      if (_selectedConnectionType == ConnectionType.tcp) {
        config = ConnectionConfig.tcp(
          address: _addressController.text,
          port: int.parse(_portController.text),
        );
      } else {
        config = ConnectionConfig.bluetooth(deviceId: 'DEVICE_ADDRESS');
      }

      await _obdService.connect(config);

      setState(() {
        _isConnected = true;
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Connected successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Connection failed: $e')));
      }
    }
  }

  Future<void> _disconnect() async {
    _obdService.stopContinuousMonitoring();
    await _obdService.disconnect();
    setState(() {
      _isConnected = false;
      _isInitialized = false;
    });
  }

  Future<void> _initializeAndStartMonitoring() async {
    try {
      // Send reset command
      await _obdService.sendCommand(ObdCommand.reset);
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitialized = true;
      });

      // Start continuous monitoring of key parameters (each uses ideal polling interval)
      _obdService.startContinuousMonitoring([
        ObdCommand.engineRpm,
        ObdCommand.vehicleSpeed,
        ObdCommand.engineCoolantTemp,
        ObdCommand.throttlePosition,
        ObdCommand.batteryVoltage,
        ObdCommand.calculatedEngineLoad,
      ]);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Monitoring started')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Initialize failed: $e')));
      }
    }
  }

  void _stopMonitoring() {
    _obdService.stopContinuousMonitoring();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Monitoring stopped')));
    }
  }

  Future<void> _singleBatchQuery() async {
    try {
      await _obdService.quickPoll([
        ObdCommand.engineRpm,
        ObdCommand.vehicleSpeed,
        ObdCommand.engineCoolantTemp,
        ObdCommand.throttlePosition,
        ObdCommand.batteryVoltage,
        ObdCommand.calculatedEngineLoad,
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Query failed: $e')));
      }
    }
  }

  Future<void> _sendCommand() async {
    if (_commandController.text.isEmpty) return;

    final command = ObdCommand.fromCode(_commandController.text);
    if (command == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid command code')));
      }
      return;
    }

    try {
      await _obdService.sendCommand(command);
      _commandController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('OBD Dashboard'),
        actions: [
          if (_obdService.isMonitoring)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Chip(
                label: Text('LIVE'),
                backgroundColor: Colors.green,
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Connection Settings Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connection',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<ConnectionType>(
                        segments: const [
                          ButtonSegment(
                            value: ConnectionType.tcp,
                            label: Text('TCP'),
                            icon: Icon(Icons.wifi),
                          ),
                          ButtonSegment(
                            value: ConnectionType.bluetooth,
                            label: Text('Bluetooth'),
                            icon: Icon(Icons.bluetooth),
                          ),
                        ],
                        selected: {_selectedConnectionType},
                        onSelectionChanged: (Set<ConnectionType> selected) {
                          setState(() {
                            _selectedConnectionType = selected.first;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      if (_selectedConnectionType == ConnectionType.tcp) ...[
                        TextField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _portController,
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: !_isConnected ? _connect : null,
                              icon: const Icon(Icons.link),
                              label: const Text('Connect'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isConnected ? _disconnect : null,
                              icon: const Icon(Icons.link_off),
                              label: const Text('Disconnect'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isConnected && !_obdService.isMonitoring
                                  ? _initializeAndStartMonitoring
                                  : null,
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Init & Monitor'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _obdService.isMonitoring
                                  ? _stopMonitoring
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                              icon: const Icon(Icons.stop),
                              label: const Text('Stop'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  _isInitialized && !_obdService.isMonitoring
                                  ? _singleBatchQuery
                                  : null,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Query'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Live Parameters Gauges
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Live Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGauge(
                              'RPM',
                              _rpm?.rpm.toString() ?? '--',
                              Icons.speed,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGauge(
                              'Speed',
                              _speed != null
                                  ? '${_speed!.speedKmh.toStringAsFixed(0)} km/h'
                                  : '--',
                              Icons.directions_car,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGauge(
                              'Temp',
                              _coolantTemp != null
                                  ? '${_coolantTemp!.temperatureCelsius.toStringAsFixed(0)}°C'
                                  : '--',
                              Icons.thermostat,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildGauge(
                              'Throttle',
                              _throttle != null
                                  ? '${_throttle!.percentage.toStringAsFixed(0)}%'
                                  : '--',
                              Icons.gas_meter,
                              Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGauge(
                              'Battery',
                              _voltage != null
                                  ? '${_voltage!.voltage.toStringAsFixed(1)}V'
                                  : '--',
                              Icons.battery_full,
                              Colors.cyan,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildGauge(
                              'Load',
                              _engineLoad != null
                                  ? '${_engineLoad!.percentage.toStringAsFixed(0)}%'
                                  : '--',
                              Icons.trending_up,
                              Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Manual Command Entry
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _commandController,
                          decoration: const InputDecoration(
                            labelText: 'Manual OBD Command',
                            border: OutlineInputBorder(),
                            hintText: 'e.g., 010C',
                          ),
                          enabled: _isConnected,
                          onSubmitted: (_) => _sendCommand(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _isConnected ? _sendCommand : null,
                        child: const Text('Send'),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Response History
              SizedBox(
                height: 300,
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Response History',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _responses.clear();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: _responses.isEmpty
                            ? const Center(child: Text('No responses yet'))
                            : ListView.builder(
                                itemCount: _responses.length,
                                itemBuilder: (context, index) {
                                  final response = _responses[index];
                                  return ListTile(
                                    dense: true,
                                    leading: _getResponseIcon(response),
                                    title: Text(response.command.description),
                                    subtitle: Text(
                                      response.toString(),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                    trailing: Text(
                                      _formatTime(response.timestamp),
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGauge(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Icon _getResponseIcon(ObdResponse response) {
    if (response is RpmResponse) return const Icon(Icons.speed, size: 20);
    if (response is SpeedResponse) {
      return const Icon(Icons.directions_car, size: 20);
    }
    if (response is TemperatureResponse) {
      return const Icon(Icons.thermostat, size: 20);
    }
    if (response is VoltageResponse) {
      return const Icon(Icons.battery_full, size: 20);
    }
    if (response is PercentageResponse) {
      return const Icon(Icons.percent, size: 20);
    }
    return const Icon(Icons.data_object, size: 20);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
