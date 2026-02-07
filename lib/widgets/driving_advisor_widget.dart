import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import '../stores/obd_store.dart';
import '../services/driving_advisor_service.dart';

/// Widget that displays the top driving advisory
class DrivingAdvisorBanner extends StatelessWidget {
  final ObdStore store;

  const DrivingAdvisorBanner({super.key, required this.store});

  Color _getSeverityColor(AdvisorySeverity severity) {
    switch (severity) {
      case AdvisorySeverity.critical:
        return Colors.red;
      case AdvisorySeverity.warning:
        return Colors.orange;
      case AdvisorySeverity.info:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(AdvisorySeverity severity) {
    switch (severity) {
      case AdvisorySeverity.critical:
        return Icons.error;
      case AdvisorySeverity.warning:
        return Icons.warning;
      case AdvisorySeverity.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final advisory = store.getTopAdvisory();

        if (advisory == null) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'All systems optimal',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final color = _getSeverityColor(advisory.severity);

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(_getSeverityIcon(advisory.severity), color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      advisory.message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      advisory.category,
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Widget that displays driving score
class DrivingScoreWidget extends StatelessWidget {
  final ObdStore store;

  const DrivingScoreWidget({super.key, required this.store});

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreLabel(int score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Good';
    if (score >= 70) return 'Fair';
    if (score >= 60) return 'Poor';
    return 'Critical';
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final score = store.getDrivingScore();
        final color = _getScoreColor(score);

        return Container(
          padding: const EdgeInsets.all(12),
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: color, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    'SCORE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$score',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    _getScoreLabel(score),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
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

/// Widget that shows all advisories in a list
class DrivingAdvisoriesPanel extends StatelessWidget {
  final ObdStore store;

  const DrivingAdvisoriesPanel({super.key, required this.store});

  Color _getSeverityColor(AdvisorySeverity severity) {
    switch (severity) {
      case AdvisorySeverity.critical:
        return Colors.red;
      case AdvisorySeverity.warning:
        return Colors.orange;
      case AdvisorySeverity.info:
        return Colors.blue;
    }
  }

  IconData _getSeverityIcon(AdvisorySeverity severity) {
    switch (severity) {
      case AdvisorySeverity.critical:
        return Icons.error;
      case AdvisorySeverity.warning:
        return Icons.warning;
      case AdvisorySeverity.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Observer(
      builder: (_) {
        final advisoriesByCategory = store.getAdvisoriesByCategory();

        if (advisoriesByCategory.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 16),
                Text(
                  'All systems optimal',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: advisoriesByCategory.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                ...entry.value.map((advisory) {
                  final color = _getSeverityColor(advisory.severity);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _getSeverityIcon(advisory.severity),
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            advisory.message,
                            style: TextStyle(fontSize: 13, color: color),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 8),
              ],
            );
          }).toList(),
        );
      },
    );
  }
}
