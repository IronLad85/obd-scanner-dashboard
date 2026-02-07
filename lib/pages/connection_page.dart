import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../stores/obd_store.dart';
import '../services/connection_type.dart';
import '../services/ble_connection_adapter.dart';

class ConnectionPage extends StatefulWidget {
  final ObdStore store;

  const ConnectionPage({super.key, required this.store});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  bool _isConnecting = false;
  bool _showAdvancedOptions = false;
  bool _isScanning = false;
  List<BluetoothDevice> _availableDevices = [];

  @override
  void initState() {
    super.initState();
    _checkBluetoothAndScan();
  }

  Future<void> _checkBluetoothAndScan() async {
    final isOn = await BleConnectionAdapter.isBluetoothOn();
    if (isOn && mounted) {
      _scanForDevices();
    }
  }

  Future<void> _scanForDevices() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
      _availableDevices.clear();
    });

    try {
      final devices = await BleConnectionAdapter.scanForDevices(
        timeout: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _availableDevices = devices;
          _isScanning = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScanning = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Scan failed: $e')));
      }
    }
  }

  void _selectDevice(BluetoothDevice device) {
    widget.store.setSelectedBleDevice(device);
  }

  Future<void> _connect() async {
    setState(() => _isConnecting = true);
    try {
      await widget.store.connect();
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
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('OBD Dashboard - Connect'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 8,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.directions_car,
                    size: 80,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Connect to OBD Device',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 32),
                  Observer(
                    builder: (_) =>
                        widget.store.selectedConnectionType ==
                            ConnectionType.bluetooth
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.blue.withOpacity(0.3),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.bluetooth_searching,
                                      size: 48,
                                      color: Colors.blue[700],
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'Bluetooth 4.0 / BLE',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue[700],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Observer(
                                      builder: (_) => Text(
                                        widget.store.selectedBleDevice != null
                                            ? 'Selected: ${widget.store.selectedBleDevice!.platformName.isNotEmpty ? widget.store.selectedBleDevice!.platformName : widget.store.selectedBleDevice!.remoteId}'
                                            : 'No device selected',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color:
                                              widget.store.selectedBleDevice !=
                                                  null
                                              ? Colors.green[700]
                                              : Colors.grey,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Device list
                              Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 300,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey[300]!),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: _isScanning
                                    ? const Center(
                                        child: Padding(
                                          padding: EdgeInsets.all(32.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              CircularProgressIndicator(),
                                              SizedBox(height: 16),
                                              Text('Scanning for devices...'),
                                            ],
                                          ),
                                        ),
                                      )
                                    : _availableDevices.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(32.0),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.bluetooth_disabled,
                                                size: 48,
                                                color: Colors.grey,
                                              ),
                                              const SizedBox(height: 16),
                                              const Text(
                                                'No devices found',
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              TextButton.icon(
                                                onPressed: _scanForDevices,
                                                icon: const Icon(Icons.refresh),
                                                label: const Text('Scan Again'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        shrinkWrap: true,
                                        itemCount: _availableDevices.length,
                                        itemBuilder: (context, index) {
                                          final device =
                                              _availableDevices[index];
                                          final isSelected =
                                              widget
                                                  .store
                                                  .selectedBleDevice
                                                  ?.remoteId ==
                                              device.remoteId;
                                          final deviceName =
                                              device.platformName.isNotEmpty
                                              ? device.platformName
                                              : 'Unknown Device';

                                          return Observer(
                                            builder: (_) => ListTile(
                                              leading: Icon(
                                                Icons.bluetooth,
                                                color: isSelected
                                                    ? Colors.blue
                                                    : Colors.grey,
                                              ),
                                              title: Text(deviceName),
                                              subtitle: Text(
                                                device.remoteId.toString(),
                                              ),
                                              trailing: isSelected
                                                  ? const Icon(
                                                      Icons.check_circle,
                                                      color: Colors.green,
                                                    )
                                                  : null,
                                              selected: isSelected,
                                              onTap: () =>
                                                  _selectDevice(device),
                                            ),
                                          );
                                        },
                                      ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _showAdvancedOptions =
                                        !_showAdvancedOptions;
                                    if (_showAdvancedOptions) {
                                      widget.store.setConnectionType(
                                        ConnectionType.tcp,
                                      );
                                    }
                                  });
                                },
                                icon: Icon(
                                  _showAdvancedOptions
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                ),
                                label: const Text('Advanced TCP Connection'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Container(),
                  ),
                  if (_showAdvancedOptions)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'IP Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.computer),
                          ),
                          controller:
                              TextEditingController(text: widget.store.address)
                                ..selection = TextSelection.collapsed(
                                  offset: widget.store.address.length,
                                ),
                          onChanged: widget.store.setAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          decoration: const InputDecoration(
                            labelText: 'Port',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                          ),
                          keyboardType: TextInputType.number,
                          controller:
                              TextEditingController(text: widget.store.port)
                                ..selection = TextSelection.collapsed(
                                  offset: widget.store.port.length,
                                ),
                          onChanged: widget.store.setPort,
                        ),
                      ],
                    ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _isConnecting ? null : _connect,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link),
                    label: Text(_isConnecting ? 'Connecting...' : 'Connect'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
