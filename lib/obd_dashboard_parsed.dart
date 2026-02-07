import 'package:flutter/material.dart';
import 'services/obd_service.dart';
import 'services/obd_command.dart';
import 'services/obd_response.dart';
import 'services/connection_type.dart';

class ObdDashboardParsed extends StatefulWidget {
  const ObdDashboardParsed({super.key});

  @override
  State<ObdDashboardParsed> createState() => _ObdDashboardParsedState();
}

class _ObdDashboardParsedState extends State<ObdDashboardParsed> {
  final ObdService _obdService = ObdService();

  bool _isConnected = false;
  bool _isInitialized = false;
  ConnectionType _selectedConnectionType = ConnectionType.tcp;

  final TextEditingController _addressController = TextEditingController(
    text: 'localhost',
  );
  final TextEditingController _portController = TextEditingController(
    text: '35000',
  );

  RpmResponse? _rpm;
  SpeedResponse? _speed;
  TemperatureResponse? _coolantTemp;
  PercentageResponse? _throttle;
  VoltageResponse? _voltage;

  final List<ObdResponse> _recentResponses = [];

  @override
  void initState() {
    super.initState();
    _obdService.parsedResponseStream.listen((response) {
      setState(() {
        _recentResponses.insert(0, response);
        if (_recentResponses.length > 20) {
          _recentResponses.removeLast();
        }

        if (response is RpmResponse) _rpm = response;
        if (response is SpeedResponse) _speed = response;
        if (response is TemperatureResponse) _coolantTemp = response;
        if (response is PercentageResponse) _throttle = response;
        if (response is VoltageResponse) _voltage = response;
      });
    });
  }

  @override
  void dispose() {
    _obdService.dispose();
    _addressController.dispose();
    _portController.dispose();
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
    await _obdService.disconnect();
    setState(() {
      _isConnected = false;
      _isInitialized = false;
      _rpm = null;
      _speed = null;
      _coolantTemp = null;
      _throttle = null;
      _voltage = null;
    });
  }

  Future<void> _initialize() async {
    try {
      final result = await _obdService.initialize();
      setState(() {
        _isInitialized = result.success;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? 'Initialized successfully'
                  : 'Initialization failed: ${result.message}',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Initialization error: $e')));
      }
    }
  }

  Future<void> _queryParameter(ObdCommand command) async {
    try {
      await _obdService.sendCommand(command);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Query failed: $e')));
      }
    }
  }

  Future<void> _startMonitoring() async {
    final commands = [
      ObdCommand.engineRpm,
      ObdCommand.vehicleSpeed,
      ObdCommand.engineCoolantTemp,
      ObdCommand.throttlePosition,
      ObdCommand.batteryVoltage,
    ];

    while (_isConnected && _isInitialized && mounted) {
      for (final command in commands) {
        if (!_isConnected) break;
        await _queryParameter(command);
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('OBD-II Dashboard (Parsed)'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildConnectionCard(),
            const SizedBox(height: 16),
            _buildParametersCard(),
            const SizedBox(height: 16),
            Expanded(child: _buildResponsesCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 120,
                    child: TextField(
                      controller: _portController,
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? null : _connect,
                    icon: const Icon(Icons.power),
                    label: const Text('Connect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected ? _disconnect : null,
                    icon: const Icon(Icons.power_off),
                    label: const Text('Disconnect'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isConnected && !_isInitialized
                        ? _initialize
                        : null,
                    icon: const Icon(Icons.settings),
                    label: const Text('Initialize'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Live Parameters',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: _isConnected && _isInitialized
                      ? _startMonitoring
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Monitor'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildParameterChip(
                  'RPM',
                  _rpm?.rpm.toString() ?? '--',
                  Icons.speed,
                ),
                _buildParameterChip(
                  'Speed',
                  _speed != null ? '${_speed!.speedKmh} km/h' : '--',
                  Icons.directions_car,
                ),
                _buildParameterChip(
                  'Coolant',
                  _coolantTemp != null
                      ? '${_coolantTemp!.temperatureCelsius}°C'
                      : '--',
                  Icons.thermostat,
                ),
                _buildParameterChip(
                  'Throttle',
                  _throttle != null
                      ? '${_throttle!.percentage.toStringAsFixed(0)}%'
                      : '--',
                  Icons.gas_meter,
                ),
                _buildParameterChip(
                  'Battery',
                  _voltage != null
                      ? '${_voltage!.voltage.toStringAsFixed(1)}V'
                      : '--',
                  Icons.battery_full,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: _isConnected && _isInitialized
                      ? () => _queryParameter(ObdCommand.engineRpm)
                      : null,
                  child: const Text('RPM'),
                ),
                ElevatedButton(
                  onPressed: _isConnected && _isInitialized
                      ? () => _queryParameter(ObdCommand.vehicleSpeed)
                      : null,
                  child: const Text('Speed'),
                ),
                ElevatedButton(
                  onPressed: _isConnected && _isInitialized
                      ? () => _queryParameter(ObdCommand.batteryVoltage)
                      : null,
                  child: const Text('Voltage'),
                ),
                ElevatedButton(
                  onPressed: _isConnected && _isInitialized
                      ? () => _queryParameter(ObdCommand.troubleCodes)
                      : null,
                  child: const Text('DTCs'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterChip(String label, String value, IconData icon) {
    return Chip(avatar: Icon(icon, size: 18), label: Text('$label: $value'));
  }

  Widget _buildResponsesCard() {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Parsed Responses',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _recentResponses.clear();
                    });
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _recentResponses.isEmpty
                ? const Center(child: Text('No responses yet'))
                : ListView.builder(
                    itemCount: _recentResponses.length,
                    itemBuilder: (context, index) {
                      final response = _recentResponses[index];
                      return ListTile(
                        dense: true,
                        leading: _getResponseIcon(response),
                        title: Text(response.command.description),
                        subtitle: Text(response.toString()),
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
    );
  }

  Icon _getResponseIcon(ObdResponse response) {
    if (response is RpmResponse) return const Icon(Icons.speed);
    if (response is SpeedResponse) return const Icon(Icons.directions_car);
    if (response is TemperatureResponse) return const Icon(Icons.thermostat);
    if (response is VoltageResponse) return const Icon(Icons.battery_full);
    if (response is PercentageResponse) return const Icon(Icons.percent);
    if (response is DtcResponse) return const Icon(Icons.error);
    return const Icon(Icons.data_object);
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:${time.second.toString().padLeft(2, '0')}';
  }
}
