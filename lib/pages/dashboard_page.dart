import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/obd_store.dart';
import '../widgets/live_gauges.dart';

class DashboardPage extends StatefulWidget {
  final ObdStore store;

  const DashboardPage({super.key, required this.store});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    // Auto-start monitoring when entering dashboard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.store.isConnected && !widget.store.isInitialized) {
        _initializeAndStartMonitoring();
      }
    });
  }

  Future<void> _initializeAndStartMonitoring() async {
    try {
      await widget.store.initializeAndStartMonitoring();
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

  Future<void> _disconnect() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect'),
        content: const Text('Are you sure you want to disconnect?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await widget.store.disconnect();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Disconnected')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('OBD Dashboard'),
        automaticallyImplyLeading: false,
        actions: [
          Observer(
            builder: (_) => widget.store.isMonitoring
                ? const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Chip(
                      label: Text('LIVE'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Disconnect',
            onPressed: _disconnect,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
                          Expanded(child: RpmGauge(store: widget.store)),
                          const SizedBox(width: 8),
                          Expanded(child: SpeedGauge(store: widget.store)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TemperatureGauge(store: widget.store),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: ThrottleGauge(store: widget.store)),
                          const SizedBox(width: 8),
                          Expanded(child: BatteryGauge(store: widget.store)),
                          const SizedBox(width: 8),
                          Expanded(child: EngineLoadGauge(store: widget.store)),
                        ],
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
}
