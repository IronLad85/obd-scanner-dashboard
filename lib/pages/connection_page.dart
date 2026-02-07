import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/obd_store.dart';
import '../services/connection_type.dart';

class ConnectionPage extends StatefulWidget {
  final ObdStore store;

  const ConnectionPage({super.key, required this.store});

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

class _ConnectionPageState extends State<ConnectionPage> {
  bool _isConnecting = false;

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
                  const Text(
                    'Connection Type',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 12),
                  Observer(
                    builder: (_) => SegmentedButton<ConnectionType>(
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
                      selected: {widget.store.selectedConnectionType},
                      onSelectionChanged: (Set<ConnectionType> selected) {
                        widget.store.setConnectionType(selected.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  Observer(
                    builder: (_) =>
                        widget.store.selectedConnectionType ==
                            ConnectionType.tcp
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              TextField(
                                decoration: const InputDecoration(
                                  labelText: 'IP Address',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.computer),
                                ),
                                controller:
                                    TextEditingController(
                                        text: widget.store.address,
                                      )
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
                                    TextEditingController(
                                        text: widget.store.port,
                                      )
                                      ..selection = TextSelection.collapsed(
                                        offset: widget.store.port.length,
                                      ),
                                onChanged: widget.store.setPort,
                              ),
                            ],
                          )
                        : const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              'Bluetooth connection will scan for available devices',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
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
