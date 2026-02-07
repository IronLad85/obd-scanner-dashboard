import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/obd_store.dart';
import '../widgets/live_gauges.dart';
import '../widgets/driving_advisor_widget.dart';

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
              // Driving advisor banner
              DrivingAdvisorBanner(store: widget.store),
              const SizedBox(height: 16),

              // RPM and Speed in same row
              Row(
                children: [
                  Expanded(child: ModernRpmDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: ModernSpeedDisplay(store: widget.store)),
                ],
              ),
              const SizedBox(height: 24),

              // Throttle, Load, and Temp - 3 per row
              Row(
                children: [
                  Expanded(child: ModernThrottleDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: ModernLoadDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: ModernTempDisplay(store: widget.store)),
                ],
              ),
              const SizedBox(height: 8),

              // Oil Temp, Battery, and MAF - 3 items
              Row(
                children: [
                  Expanded(child: ModernOilTempDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: ModernBatteryDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: ModernMafDisplay(store: widget.store)),
                ],
              ),
              const SizedBox(height: 8),

              // Intake Air Temp, Fuel Rate, and Driving Score - 3 items
              Row(
                children: [
                  Expanded(
                    child: ModernIntakeAirTempDisplay(store: widget.store),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: ModernFuelRateDisplay(store: widget.store)),
                  const SizedBox(width: 8),
                  Expanded(child: DrivingScoreWidget(store: widget.store)),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Observer(
        builder: (_) => FloatingActionButton(
          onPressed: () {
            widget.store.toggleVoiceAnnouncements();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  widget.store.voiceAnnouncementsEnabled
                      ? '🔊 Voice announcements enabled'
                      : '🔇 Voice announcements disabled',
                ),
                duration: const Duration(seconds: 1),
              ),
            );
          },
          tooltip: widget.store.voiceAnnouncementsEnabled
              ? 'Disable Voice'
              : 'Enable Voice',
          child: Icon(
            widget.store.voiceAnnouncementsEnabled
                ? Icons.volume_up
                : Icons.volume_off,
          ),
        ),
      ),
    );
  }
}
