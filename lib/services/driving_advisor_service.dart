import 'dart:math';

/// Severity levels for driving advisories
enum AdvisorySeverity { info, warning, critical }

/// A driving advisory with message and severity
class DrivingAdvisory {
  final String message;
  final AdvisorySeverity severity;
  final String category;
  final DateTime timestamp;

  DrivingAdvisory({
    required this.message,
    required this.severity,
    required this.category,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() => '[$category] $message';
}

/// Service that analyzes OBD2 data and provides driving recommendations
/// to protect engine, DSG gearbox, and optimize fuel consumption
class DrivingAdvisorService {
  // Engine protection thresholds
  static const double _maxSafeRpm = 6500;
  static const double _redlineWarningRpm = 6000;
  static const double _maxCoolantTemp = 110;
  static const double _warningCoolantTemp = 100;
  static const double _minOilTempForPerformance = 80;
  static const double _maxOilTemp = 120;
  static const double _warningOilTemp = 110;
  static const double _coldEngineRpmLimit = 3000;

  // DSG gearbox protection thresholds
  static const double _minRpmForHighLoad = 1500;
  static const double _luggingRpmThreshold = 1200;
  static const double _luggingLoadThreshold = 70;
  static const double _prolongedHighRpmThreshold = 5000;
  static const double _maxIntakeAirTemp = 60;

  // Fuel economy thresholds
  static const double _economicalRpmMax = 2500;
  static const double _economicalThrottleMax = 40;
  static const double _highFuelRateThreshold = 12;
  static const double _idleSpeedThreshold = 5;

  // Battery health
  static const double _minHealthyBatteryVoltage = 12.6;
  static const double _warningBatteryVoltage = 12.0;

  /// Analyze all OBD2 data and return driving advisories
  List<DrivingAdvisory> analyzeAllParameters({
    required double? rpm,
    required double? speedKmh,
    required double? coolantTempC,
    required double? oilTempC,
    required double? intakeAirTempC,
    required double? throttlePercent,
    required double? engineLoadPercent,
    required double? mafGramsPerSecond,
    required double? fuelRateLph,
    required double? batteryVoltage,
  }) {
    final advisories = <DrivingAdvisory>[];

    // Engine protection checks
    advisories.addAll(
      _analyzeEngineHealth(
        rpm: rpm,
        coolantTempC: coolantTempC,
        oilTempC: oilTempC,
        throttlePercent: throttlePercent,
      ),
    );

    // DSG gearbox protection checks
    advisories.addAll(
      _analyzeGearboxHealth(
        rpm: rpm,
        engineLoadPercent: engineLoadPercent,
        throttlePercent: throttlePercent,
        intakeAirTempC: intakeAirTempC,
        oilTempC: oilTempC,
      ),
    );

    // Fuel economy optimization
    advisories.addAll(
      _analyzeFuelEfficiency(
        rpm: rpm,
        speedKmh: speedKmh,
        throttlePercent: throttlePercent,
        fuelRateLph: fuelRateLph,
        engineLoadPercent: engineLoadPercent,
      ),
    );

    // Battery health
    advisories.addAll(_analyzeBatteryHealth(batteryVoltage: batteryVoltage));

    // Intake air temperature
    advisories.addAll(_analyzeIntakeAirTemp(intakeAirTempC: intakeAirTempC));

    return advisories;
  }

  /// Analyze engine health and protection
  List<DrivingAdvisory> _analyzeEngineHealth({
    required double? rpm,
    required double? coolantTempC,
    required double? oilTempC,
    required double? throttlePercent,
  }) {
    final advisories = <DrivingAdvisory>[];

    if (rpm == null) return advisories;

    // Critical RPM checks
    if (rpm >= _maxSafeRpm) {
      advisories.add(
        DrivingAdvisory(
          message: '🚨 CRITICAL RPM! Reduce throttle immediately',
          severity: AdvisorySeverity.critical,
          category: 'Engine',
        ),
      );
    } else if (rpm >= _redlineWarningRpm) {
      advisories.add(
        DrivingAdvisory(
          message: '⚠️ High RPM - Shift up or reduce throttle',
          severity: AdvisorySeverity.warning,
          category: 'Engine',
        ),
      );
    }

    // Coolant temperature checks
    if (coolantTempC != null) {
      if (coolantTempC >= _maxCoolantTemp) {
        advisories.add(
          DrivingAdvisory(
            message: '🚨 OVERHEATING! Pull over safely and idle',
            severity: AdvisorySeverity.critical,
            category: 'Engine',
          ),
        );
      } else if (coolantTempC >= _warningCoolantTemp) {
        advisories.add(
          DrivingAdvisory(
            message: '⚠️ Engine running hot - Reduce load',
            severity: AdvisorySeverity.warning,
            category: 'Engine',
          ),
        );
      } else if (coolantTempC < 60) {
        advisories.add(
          DrivingAdvisory(
            message: '❄️ Engine cold - Keep RPM below 3000',
            severity: AdvisorySeverity.info,
            category: 'Engine',
          ),
        );
      }
    }

    // Oil temperature checks
    if (oilTempC != null) {
      if (oilTempC >= _maxOilTemp) {
        advisories.add(
          DrivingAdvisory(
            message: '🚨 Oil temp critical! Reduce load immediately',
            severity: AdvisorySeverity.critical,
            category: 'Engine',
          ),
        );
      } else if (oilTempC >= _warningOilTemp) {
        advisories.add(
          DrivingAdvisory(
            message: '⚠️ Oil temperature high - Drive gently',
            severity: AdvisorySeverity.warning,
            category: 'Engine',
          ),
        );
      } else if (oilTempC < _minOilTempForPerformance) {
        if (rpm > _coldEngineRpmLimit ||
            (throttlePercent != null && throttlePercent > 50)) {
          advisories.add(
            DrivingAdvisory(
              message: '❄️ Oil not warm - Avoid high load/RPM',
              severity: AdvisorySeverity.warning,
              category: 'Engine',
            ),
          );
        } else {
          advisories.add(
            DrivingAdvisory(
              message: 'ℹ️ Engine warming up - Drive gently',
              severity: AdvisorySeverity.info,
              category: 'Engine',
            ),
          );
        }
      }
    }

    return advisories;
  }

  /// Analyze DSG gearbox health and protection
  List<DrivingAdvisory> _analyzeGearboxHealth({
    required double? rpm,
    required double? engineLoadPercent,
    required double? throttlePercent,
    required double? intakeAirTempC,
    required double? oilTempC,
  }) {
    final advisories = <DrivingAdvisory>[];

    if (rpm == null || engineLoadPercent == null) return advisories;

    // Lugging detection (high load at low RPM - very bad for DSG)
    if (rpm < _minRpmForHighLoad && engineLoadPercent > _luggingLoadThreshold) {
      advisories.add(
        DrivingAdvisory(
          message:
              '🚨 LUGGING! High load at low RPM - Downshift or reduce throttle',
          severity: AdvisorySeverity.critical,
          category: 'Gearbox',
        ),
      );
    } else if (rpm < _luggingRpmThreshold && engineLoadPercent > 50) {
      advisories.add(
        DrivingAdvisory(
          message: '⚠️ RPM too low for load - Downshift recommended',
          severity: AdvisorySeverity.warning,
          category: 'Gearbox',
        ),
      );
    }

    // Prolonged high RPM warning (DSG clutches can overheat)
    if (rpm > _prolongedHighRpmThreshold) {
      advisories.add(
        DrivingAdvisory(
          message: '⚠️ High sustained RPM - Shift up to protect DSG clutches',
          severity: AdvisorySeverity.warning,
          category: 'Gearbox',
        ),
      );
    }

    // Cold gearbox + aggressive throttle
    if (oilTempC != null && oilTempC < 40) {
      if (throttlePercent != null && throttlePercent > 70) {
        advisories.add(
          DrivingAdvisory(
            message: '⚠️ DSG cold - Avoid aggressive acceleration',
            severity: AdvisorySeverity.warning,
            category: 'Gearbox',
          ),
        );
      }
    }

    // Optimal shift point recommendation
    if (rpm > 2000 && rpm < 3000 && engineLoadPercent < 30) {
      advisories.add(
        DrivingAdvisory(
          message: 'ℹ️ Optimal cruising RPM range',
          severity: AdvisorySeverity.info,
          category: 'Gearbox',
        ),
      );
    }

    return advisories;
  }

  /// Analyze fuel efficiency and provide optimization tips
  List<DrivingAdvisory> _analyzeFuelEfficiency({
    required double? rpm,
    required double? speedKmh,
    required double? throttlePercent,
    required double? fuelRateLph,
    required double? engineLoadPercent,
  }) {
    final advisories = <DrivingAdvisory>[];

    // High fuel consumption warning
    if (fuelRateLph != null && fuelRateLph > _highFuelRateThreshold) {
      advisories.add(
        DrivingAdvisory(
          message: '⛽ High fuel consumption - Ease off throttle',
          severity: AdvisorySeverity.warning,
          category: 'Fuel',
        ),
      );
    }

    // Idle fuel waste
    if (speedKmh != null &&
        speedKmh < _idleSpeedThreshold &&
        fuelRateLph != null &&
        fuelRateLph > 1) {
      advisories.add(
        DrivingAdvisory(
          message: 'ℹ️ Idling - Consider shutting off for long stops',
          severity: AdvisorySeverity.info,
          category: 'Fuel',
        ),
      );
    }

    // Economical driving recommendation
    if (rpm != null && throttlePercent != null) {
      if (rpm > _economicalRpmMax && throttlePercent < 30) {
        advisories.add(
          DrivingAdvisory(
            message: 'ℹ️ Shift up for better fuel economy',
            severity: AdvisorySeverity.info,
            category: 'Fuel',
          ),
        );
      }

      if (throttlePercent > 80 && rpm > 4000) {
        advisories.add(
          DrivingAdvisory(
            message: '⛽ Excessive throttle and RPM - High fuel consumption',
            severity: AdvisorySeverity.warning,
            category: 'Fuel',
          ),
        );
      }
    }

    // Optimal efficiency zone
    if (rpm != null &&
        rpm >= 1500 &&
        rpm <= 2500 &&
        throttlePercent != null &&
        throttlePercent <= _economicalThrottleMax &&
        speedKmh != null &&
        speedKmh > 30) {
      advisories.add(
        DrivingAdvisory(
          message: '✅ Excellent - Driving in optimal efficiency zone',
          severity: AdvisorySeverity.info,
          category: 'Fuel',
        ),
      );
    }

    return advisories;
  }

  /// Analyze battery health
  List<DrivingAdvisory> _analyzeBatteryHealth({
    required double? batteryVoltage,
  }) {
    final advisories = <DrivingAdvisory>[];

    if (batteryVoltage == null) return advisories;

    if (batteryVoltage < _warningBatteryVoltage) {
      advisories.add(
        DrivingAdvisory(
          message: '🔋 Battery voltage low - Check charging system',
          severity: AdvisorySeverity.critical,
          category: 'Battery',
        ),
      );
    } else if (batteryVoltage < _minHealthyBatteryVoltage) {
      advisories.add(
        DrivingAdvisory(
          message: 'ℹ️ Battery charge low - Consider longer drive',
          severity: AdvisorySeverity.info,
          category: 'Battery',
        ),
      );
    }

    return advisories;
  }

  /// Analyze intake air temperature
  List<DrivingAdvisory> _analyzeIntakeAirTemp({
    required double? intakeAirTempC,
  }) {
    final advisories = <DrivingAdvisory>[];

    if (intakeAirTempC == null) return advisories;

    if (intakeAirTempC > _maxIntakeAirTemp) {
      advisories.add(
        DrivingAdvisory(
          message: '⚠️ Hot intake air - Reduced performance expected',
          severity: AdvisorySeverity.warning,
          category: 'Performance',
        ),
      );
    }

    return advisories;
  }

  /// Get highest priority advisory (for quick display)
  DrivingAdvisory? getTopPriorityAdvisory(List<DrivingAdvisory> advisories) {
    if (advisories.isEmpty) return null;

    // Sort by severity: critical > warning > info
    advisories.sort((a, b) {
      final severityOrder = {
        AdvisorySeverity.critical: 0,
        AdvisorySeverity.warning: 1,
        AdvisorySeverity.info: 2,
      };
      return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
    });

    return advisories.first;
  }

  /// Get advisories grouped by category
  Map<String, List<DrivingAdvisory>> getAdvisoriesByCategory(
    List<DrivingAdvisory> advisories,
  ) {
    final grouped = <String, List<DrivingAdvisory>>{};

    for (final advisory in advisories) {
      grouped.putIfAbsent(advisory.category, () => []).add(advisory);
    }

    return grouped;
  }

  /// Calculate overall driving score (0-100)
  /// Higher is better
  int calculateDrivingScore({
    required double? rpm,
    required double? throttlePercent,
    required double? engineLoadPercent,
    required double? coolantTempC,
    required double? oilTempC,
    required double? fuelRateLph,
  }) {
    int score = 100;

    // RPM penalties
    if (rpm != null) {
      if (rpm > 5000) {
        score -= 30;
      } else if (rpm > 4000) {
        score -= 20;
      } else if (rpm > 3000) {
        score -= 10;
      } else if (rpm < 1200) {
        score -= 15; // Lugging penalty
      }
    }

    // Temperature penalties
    if (coolantTempC != null && coolantTempC > _warningCoolantTemp) {
      score -= 25;
    }
    if (oilTempC != null && oilTempC > _warningOilTemp) {
      score -= 25;
    }

    // Throttle efficiency
    if (throttlePercent != null && throttlePercent > 80) {
      score -= 15;
    }

    // Fuel rate penalty
    if (fuelRateLph != null && fuelRateLph > 10) {
      score -= 20;
    }

    // Engine load vs RPM balance
    if (rpm != null && engineLoadPercent != null) {
      if (rpm < 1500 && engineLoadPercent > 70) {
        score -= 30; // Heavy lugging
      }
    }

    // Bonus for optimal conditions
    if (rpm != null &&
        rpm >= 1500 &&
        rpm <= 2500 &&
        throttlePercent != null &&
        throttlePercent <= 40) {
      score += 10; // Capped at 100
    }

    return max(0, min(100, score));
  }
}
