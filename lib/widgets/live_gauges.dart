import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/obd_store.dart';

class LiveGaugeWidget extends StatelessWidget {
  final ObdStore store;
  final String label;
  final String Function(dynamic value) valueGetter;
  final IconData icon;
  final Color color;
  final dynamic Function(ObdStore) observableGetter;

  const LiveGaugeWidget({
    super.key,
    required this.store,
    required this.label,
    required this.valueGetter,
    required this.icon,
    required this.color,
    required this.observableGetter,
  });

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final value = observableGetter(store);
        final displayValue = value != null ? valueGetter(value) : '--';

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
                displayValue,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Specific gauge implementations
class RpmGauge extends StatelessWidget {
  final ObdStore store;

  const RpmGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return LiveGaugeWidget(
      store: store,
      label: 'RPM',
      valueGetter: (value) => value.toStringAsFixed(0),
      icon: Icons.speed,
      color: Colors.blue,
      observableGetter: (s) => s.rpm,
    );
  }
}

class SpeedGauge extends StatelessWidget {
  final ObdStore store;

  const SpeedGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return LiveGaugeWidget(
      store: store,
      label: 'Speed',
      valueGetter: (value) => '${value.toStringAsFixed(0)} km/h',
      icon: Icons.directions_car,
      color: Colors.green,
      observableGetter: (s) => s.speedKmh,
    );
  }
}

class TemperatureGauge extends StatelessWidget {
  final ObdStore store;

  const TemperatureGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return LiveGaugeWidget(
      store: store,
      label: 'Temp',
      valueGetter: (value) => '${value.toStringAsFixed(0)}°C',
      icon: Icons.thermostat,
      color: Colors.orange,
      observableGetter: (s) => s.coolantTempC,
    );
  }
}

class ThrottleGauge extends StatelessWidget {
  final ObdStore store;

  const ThrottleGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return LiveGaugeWidget(
      store: store,
      label: 'Throttle',
      valueGetter: (value) => '${value.toStringAsFixed(0)}%',
      icon: Icons.gas_meter,
      color: Colors.purple,
      observableGetter: (s) => s.throttlePercent,
    );
  }
}

class BatteryGauge extends StatelessWidget {
  final ObdStore store;

  const BatteryGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return LiveGaugeWidget(
      store: store,
      label: 'Battery',
      valueGetter: (value) => '${value.toStringAsFixed(1)}V',
      icon: Icons.battery_full,
      color: Colors.cyan,
      observableGetter: (s) => s.batteryVoltage,
    );
  }
}

class EngineLoadGauge extends StatelessWidget {
  final ObdStore store;

  const EngineLoadGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return LiveGaugeWidget(
      store: store,
      label: 'Load',
      valueGetter: (value) => '${value.toStringAsFixed(0)}%',
      icon: Icons.trending_up,
      color: Colors.red,
      observableGetter: (s) => s.engineLoadPercent,
    );
  }
}
