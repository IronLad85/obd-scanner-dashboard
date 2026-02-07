import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:google_fonts/google_fonts.dart';
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

// Modern Linear Gauge Widgets
class ModernRpmDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernRpmDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final rpm = store.rpm ?? 0;
        final percentage = (rpm / 8000).clamp(0.0, 1.0);

        Color getColor() {
          if (rpm < 3000) return Colors.green;
          if (rpm < 6000) return Colors.orange;
          return Colors.red;
        }

        String formatRpmNumber(double rpm) {
          if (rpm < 1000) {
            return (rpm / 1000).toStringAsFixed(1);
          } else {
            final rounded = (rpm / 1000).toStringAsFixed(1);
            // Remove trailing .0 for whole numbers
            if (rounded.endsWith('.0')) {
              return rounded.substring(0, rounded.length - 2);
            }
            return rounded;
          }
        }

        return Container(
          padding: const EdgeInsets.all(16),
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, color: getColor(), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'RPM',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: formatRpmNumber(rpm),
                            style: GoogleFonts.audiowide(
                              fontSize: 48,
                              color: getColor(),
                              height: 1.0,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernSpeedDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernSpeedDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final speed = store.speedKmh ?? 0;
        final percentage = (speed / 200).clamp(0.0, 1.0);

        Color getColor() {
          if (speed < 60) return Colors.blue;
          if (speed < 120) return Colors.orange;
          return Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.directions_car, color: getColor(), size: 28),
                      const SizedBox(height: 4),
                      Text(
                        'SPEED',
                        style: GoogleFonts.rajdhani(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${speed.toInt()}',
                          style: GoogleFonts.audiowide(
                            fontSize: 75,
                            color: getColor(),
                            height: 1.0,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 12,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(getColor()),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernThrottleDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernThrottleDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final throttle = store.throttlePercent ?? 0;

        Color getColor() {
          if (throttle < 30) return Colors.green;
          if (throttle < 70) return Colors.amber;
          return Colors.deepOrange;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gas_meter, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'THROTTLE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${throttle.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      '%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernLoadDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernLoadDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final load = store.engineLoadPercent ?? 0;

        Color getColor() {
          if (load < 40) return Colors.green;
          if (load < 75) return Colors.amber;
          return Colors.redAccent;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.trending_up, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'LOAD',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${load.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      '%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernTempDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernTempDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final temp = store.coolantTempC ?? 0;

        Color getColor() {
          if (temp < 75) return Colors.cyan;
          if (temp < 95) return Colors.orange;
          return Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thermostat, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'TEMP',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${temp.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernOilTempDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernOilTempDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final temp = store.oilTempC ?? 0;

        Color getColor() {
          if (temp < 90) return Colors.cyan;
          if (temp < 110) return Colors.orange;
          return Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.water_drop, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'OIL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${temp.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: getColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernMafDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernMafDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final maf = store.mafGramsPerSecond ?? 0;

        Color getColor() {
          if (maf < 8) return Colors.cyan;
          if (maf < 20) return Colors.green;
          if (maf < 40) return Colors.orange;
          return Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.air, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'MAF',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    maf.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      'g/s',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: getColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernIntakeAirTempDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernIntakeAirTempDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final temp = store.intakeAirTempC ?? 0;

        Color getColor() {
          if (temp < 30) return Colors.cyan;
          if (temp < 50) return Colors.green;
          if (temp < 70) return Colors.orange;
          return Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.air, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'INTAKE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${temp.toInt()}',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      '°C',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: getColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernFuelRateDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernFuelRateDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final fuelRate = store.fuelRateLph ?? 0;

        Color getColor() {
          if (fuelRate < 3) return Colors.green;
          if (fuelRate < 8) return Colors.cyan;
          if (fuelRate < 15) return Colors.orange;
          return Colors.red;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_gas_station, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'FUEL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fuelRate.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      'L/h',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: getColor(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class ModernBatteryDisplay extends StatelessWidget {
  final ObdStore store;

  const ModernBatteryDisplay({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final voltage = store.batteryVoltage ?? 0;

        Color getColor() {
          if (voltage >= 12.6) return Colors.green;
          if (voltage >= 12.0) return Colors.amber;
          return Colors.redAccent;
        }

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                getColor().withOpacity(0.1),
                getColor().withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: getColor().withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.battery_full, color: getColor(), size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'BATTERY',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    voltage.toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: getColor(),
                      height: 1.0,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 2),
                    child: Text(
                      'V',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// Circular Gauge Widgets using Syncfusion (deprecated - use Modern displays above)
class CircularRpmGauge extends StatelessWidget {
  final ObdStore store;

  const CircularRpmGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final rpm = store.rpm ?? 0;

        return SfRadialGauge(
          animationDuration: 100,
          enableLoadingAnimation: true,
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 8000,
              interval: 1000,
              minorTicksPerInterval: 4,
              axisLineStyle: const AxisLineStyle(
                thickness: 0.15,
                thicknessUnit: GaugeSizeUnit.factor,
                color: Colors.blue,
              ),
              majorTickStyle: const MajorTickStyle(
                length: 0.15,
                lengthUnit: GaugeSizeUnit.factor,
                thickness: 2,
                color: Colors.black54,
              ),
              minorTickStyle: const MinorTickStyle(
                length: 0.08,
                lengthUnit: GaugeSizeUnit.factor,
                thickness: 1,
                color: Colors.black26,
              ),
              axisLabelStyle: const GaugeTextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              onLabelCreated: (AxisLabelCreatedArgs args) {
                if (args.text == '0') {
                  args.text = '0';
                } else {
                  args.text = '${(double.parse(args.text) ~/ 1000)}K';
                }
              },
              ranges: <GaugeRange>[
                GaugeRange(
                  startValue: 0,
                  endValue: 3000,
                  color: Colors.green,
                  startWidth: 0.15,
                  endWidth: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
                GaugeRange(
                  startValue: 3000,
                  endValue: 6000,
                  color: Colors.orange,
                  startWidth: 0.15,
                  endWidth: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
                GaugeRange(
                  startValue: 6000,
                  endValue: 8000,
                  color: Colors.red,
                  startWidth: 0.15,
                  endWidth: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: rpm.toDouble(),
                  enableAnimation: true,
                  animationDuration: 100,
                  animationType: AnimationType.ease,
                  needleLength: 0.7,
                  needleStartWidth: 1.5,
                  needleEndWidth: 4,
                  needleColor: Colors.blueGrey,
                  knobStyle: const KnobStyle(
                    knobRadius: 0.08,
                    color: Colors.white,
                    borderColor: Colors.blueGrey,
                    borderWidth: 0.03,
                  ),
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        rpm.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      const Text(
                        'RPM',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  angle: 90,
                  positionFactor: 0.8,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class CircularSpeedGauge extends StatelessWidget {
  final ObdStore store;

  const CircularSpeedGauge({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final speed = store.speedKmh ?? 0;

        return SfRadialGauge(
          animationDuration: 100,
          enableLoadingAnimation: true,
          axes: <RadialAxis>[
            RadialAxis(
              minimum: 0,
              maximum: 200,
              interval: 20,
              minorTicksPerInterval: 4,
              axisLineStyle: const AxisLineStyle(
                thickness: 0.15,
                thicknessUnit: GaugeSizeUnit.factor,
                color: Colors.green,
              ),
              majorTickStyle: const MajorTickStyle(
                length: 0.15,
                lengthUnit: GaugeSizeUnit.factor,
                thickness: 2,
                color: Colors.black54,
              ),
              minorTickStyle: const MinorTickStyle(
                length: 0.08,
                lengthUnit: GaugeSizeUnit.factor,
                thickness: 1,
                color: Colors.black26,
              ),
              axisLabelStyle: const GaugeTextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              ranges: <GaugeRange>[
                GaugeRange(
                  startValue: 0,
                  endValue: 60,
                  color: Colors.green,
                  startWidth: 0.15,
                  endWidth: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
                GaugeRange(
                  startValue: 60,
                  endValue: 120,
                  color: Colors.orange,
                  startWidth: 0.15,
                  endWidth: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
                GaugeRange(
                  startValue: 120,
                  endValue: 200,
                  color: Colors.red,
                  startWidth: 0.15,
                  endWidth: 0.15,
                  sizeUnit: GaugeSizeUnit.factor,
                ),
              ],
              pointers: <GaugePointer>[
                NeedlePointer(
                  value: speed.toDouble(),
                  enableAnimation: true,
                  animationDuration: 100,
                  animationType: AnimationType.ease,
                  needleLength: 0.7,
                  needleStartWidth: 1.5,
                  needleEndWidth: 4,
                  needleColor: Colors.blueGrey,
                  knobStyle: const KnobStyle(
                    knobRadius: 0.08,
                    color: Colors.white,
                    borderColor: Colors.blueGrey,
                    borderWidth: 0.03,
                  ),
                ),
              ],
              annotations: <GaugeAnnotation>[
                GaugeAnnotation(
                  widget: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        speed.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const Text(
                        'km/h',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  angle: 90,
                  positionFactor: 0.8,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
