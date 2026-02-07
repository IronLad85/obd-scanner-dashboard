import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // RPM and Speed in same row
              Row(
                children: [
                  Expanded(child: ModernRpmDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: ModernSpeedDisplay(store: widget.store)),
                ],
              ),
              const SizedBox(height: 24),

              // Other Parameters as Simple Boxes
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Other Parameters',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TemperatureGauge(store: widget.store),
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: ThrottleGauge(store: widget.store)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
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
