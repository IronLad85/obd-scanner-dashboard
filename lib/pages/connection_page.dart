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
  bool _autoMode = true;
  BluetoothDevice? _autoDetectedDevice;

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
      _autoDetectedDevice = null;
    });

    try {
      final devices = await BleConnectionAdapter.scanForDevices(
        timeout: const Duration(seconds: 10),
      );

      if (mounted) {
        setState(() {
          _availableDevices = devices;
          _isScanning = false;

          // Auto-detect OBD device
          if (_autoMode && devices.isNotEmpty) {
            _autoDetectedDevice = _detectObdDevice(devices);
            if (_autoDetectedDevice != null) {
              widget.store.setSelectedBleDevice(_autoDetectedDevice);
            }
          }
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

  BluetoothDevice? _detectObdDevice(List<BluetoothDevice> devices) {
    // Common OBD-II device name patterns
    const obdPatterns = [
      'obd',
      'obdii',
      'obd2',
      'elm327',
      'modaxe',
      'chx',
      'v-link',
      'vlink',
      'vgate',
      'konnwei',
      'autel',
    ];

    for (final device in devices) {
      final name = device.platformName.toLowerCase();
      for (final pattern in obdPatterns) {
        if (name.contains(pattern)) {
          return device;
        }
      }
    }
    return null;
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
        final errorMessage = e.toString();

        // Show error with troubleshooting tips
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Connection Failed'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    errorMessage,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Troubleshooting Tips:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('• Make sure your car ignition is ON'),
                  const Text('• Unplug and replug the OBD device'),
                  const Text('• Move your phone closer to the device'),
                  const Text('• Check if device is paired in phone settings'),
                  const Text('• Try turning Bluetooth OFF and ON'),
                  const Text('• Restart the OBD device (unplug for 30s)'),
                  const Text('• Close other apps using Bluetooth'),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _connect(); // Retry
                },
                child: const Text('RETRY'),
              ),
            ],
          ),
        );

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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.directions_car, size: 48, color: Colors.blue),
              const SizedBox(height: 12),
              const Text(
                'Connect to OBD Device',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Observer(
                builder: (_) =>
                    widget.store.selectedConnectionType ==
                        ConnectionType.bluetooth
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Colors.blue.withOpacity(0.3),
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.bluetooth_searching,
                                  size: 32,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Bluetooth 4.0 / BLE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Observer(
                                  builder: (_) => Text(
                                    widget.store.selectedBleDevice != null
                                        ? 'Selected: ${widget.store.selectedBleDevice!.platformName.isNotEmpty ? widget.store.selectedBleDevice!.platformName : widget.store.selectedBleDevice!.remoteId}'
                                        : 'No device selected',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          widget.store.selectedBleDevice != null
                                          ? Colors.green[700]
                                          : Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Auto/Manual mode toggle
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Auto-detect',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _autoMode
                                      ? Colors.blue[700]
                                      : Colors.grey,
                                  fontWeight: _autoMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              Switch(
                                value: !_autoMode,
                                onChanged: (value) {
                                  setState(() {
                                    _autoMode = !value;
                                    if (_autoMode &&
                                        _availableDevices.isNotEmpty) {
                                      _autoDetectedDevice = _detectObdDevice(
                                        _availableDevices,
                                      );
                                      if (_autoDetectedDevice != null) {
                                        widget.store.setSelectedBleDevice(
                                          _autoDetectedDevice,
                                        );
                                      }
                                    }
                                  });
                                },
                              ),
                              Text(
                                'Manual select',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: !_autoMode
                                      ? Colors.blue[700]
                                      : Colors.grey,
                                  fontWeight: !_autoMode
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Device list or auto-detection display
                          Container(
                            constraints: const BoxConstraints(maxHeight: 200),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _isScanning
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            _autoMode
                                                ? 'Searching for OBD scanner...'
                                                : 'Scanning for devices...',
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : _autoMode
                                ? // Auto mode display
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: _autoDetectedDevice != null
                                          ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.bluetooth_connected,
                                                  size: 40,
                                                  color: Colors.green[700],
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'Scanner Found!',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _autoDetectedDevice!
                                                          .platformName
                                                          .isNotEmpty
                                                      ? _autoDetectedDevice!
                                                            .platformName
                                                      : _autoDetectedDevice!
                                                            .remoteId
                                                            .toString(),
                                                  style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 11,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton.icon(
                                                  onPressed: _scanForDevices,
                                                  icon: const Icon(
                                                    Icons.refresh,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Scan Again',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                          : Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.search_off,
                                                  size: 40,
                                                  color: Colors.orange[700],
                                                ),
                                                const SizedBox(height: 8),
                                                const Text(
                                                  'No OBD Scanner Found',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  _availableDevices.isEmpty
                                                      ? 'No Bluetooth devices nearby'
                                                      : 'Found ${_availableDevices.length} device(s) but none matched OBD patterns',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                TextButton.icon(
                                                  onPressed: _scanForDevices,
                                                  icon: const Icon(
                                                    Icons.refresh,
                                                    size: 16,
                                                  ),
                                                  label: const Text(
                                                    'Scan Again',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                if (_availableDevices
                                                    .isNotEmpty)
                                                  TextButton(
                                                    onPressed: () {
                                                      setState(
                                                        () => _autoMode = false,
                                                      );
                                                    },
                                                    child: const Text(
                                                      'Switch to Manual Mode',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                    ),
                                  )
                                : // Manual mode - show device list
                                  _availableDevices.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.bluetooth_disabled,
                                            size: 32,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(height: 8),
                                          const Text(
                                            'No devices found',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          TextButton.icon(
                                            onPressed: _scanForDevices,
                                            icon: const Icon(
                                              Icons.refresh,
                                              size: 16,
                                            ),
                                            label: const Text(
                                              'Scan Again',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: _availableDevices.length,
                                    itemBuilder: (context, index) {
                                      final device = _availableDevices[index];
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
                                          dense: true,
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 0,
                                              ),
                                          leading: Icon(
                                            Icons.bluetooth,
                                            size: 20,
                                            color: isSelected
                                                ? Colors.blue
                                                : Colors.grey,
                                          ),
                                          title: Text(
                                            deviceName,
                                            style: const TextStyle(
                                              fontSize: 13,
                                            ),
                                          ),
                                          subtitle: Text(
                                            device.remoteId.toString(),
                                            style: const TextStyle(
                                              fontSize: 10,
                                            ),
                                          ),
                                          trailing: isSelected
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20,
                                                )
                                              : null,
                                          selected: isSelected,
                                          onTap: () => _selectDevice(device),
                                        ),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _showAdvancedOptions = !_showAdvancedOptions;
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
                              size: 18,
                            ),
                            label: const Text(
                              'Advanced TCP Connection',
                              style: TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
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
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'IP Address',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.computer, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      controller:
                          TextEditingController(text: widget.store.address)
                            ..selection = TextSelection.collapsed(
                              offset: widget.store.address.length,
                            ),
                      onChanged: widget.store.setAddress,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        labelText: 'Port',
                        labelStyle: TextStyle(fontSize: 12),
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.numbers, size: 18),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                      keyboardType: TextInputType.number,
                      controller: TextEditingController(text: widget.store.port)
                        ..selection = TextSelection.collapsed(
                          offset: widget.store.port.length,
                        ),
                      onChanged: widget.store.setPort,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              Observer(
                builder: (_) {
                  final isBluetoothMode =
                      widget.store.selectedConnectionType ==
                      ConnectionType.bluetooth;
                  final canConnect =
                      !_isConnecting &&
                      (!isBluetoothMode ||
                          widget.store.selectedBleDevice != null);

                  return ElevatedButton.icon(
                    onPressed: canConnect ? _connect : null,
                    icon: _isConnecting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.link, size: 18),
                    label: Text(
                      _isConnecting
                          ? 'Connecting...'
                          : isBluetoothMode &&
                                widget.store.selectedBleDevice == null
                          ? 'Select Device First'
                          : 'Connect',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 14),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
