import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class RiskMeter extends StatelessWidget {
  final double degradationRisk;
  final double dissolitionRisk;
  final double enviroRisk;

  const RiskMeter({
    super.key,
    required this.degradationRisk,
    required this.dissolitionRisk,
    required this.enviroRisk,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _RiskBar(
          label: 'DEGRAD',
          value: degradationRisk,
          color: AppTheme.getRiskColor(degradationRisk),
        ),
        const SizedBox(height: 8),
        _RiskBar(
          label: 'DISSOL',
          value: dissolitionRisk,
          color: AppTheme.getRiskColor(dissolitionRisk),
        ),
        const SizedBox(height: 8),
        _RiskBar(
          label: 'ENVIRO',
          value: enviroRisk,
          color: AppTheme.getRiskColor(enviroRisk),
        ),
      ],
    );
  }
}

class _RiskBar extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _RiskBar({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppTheme.textMuted,
                letterSpacing: 1,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: AppTheme.bgSurface,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
