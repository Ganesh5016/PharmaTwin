import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final LinearGradient gradient;
  final String trend;
  final bool? trendUp; // null = neutral

  const KpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
    required this.trend,
    this.trendUp,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.bgCard,
        border: Border.all(color: AppTheme.borderGlass),
        boxShadow: [
          BoxShadow(
            color: gradient.colors.first.withOpacity(0.08),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: gradient,
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const Spacer(),
              if (trendUp != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: (trendUp!
                            ? AppTheme.neonGreen
                            : AppTheme.neonRed)
                        .withOpacity(0.12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp!
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 10,
                        color: trendUp!
                            ? AppTheme.neonGreen
                            : AppTheme.neonRed,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        trend,
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 9,
                          color: trendUp!
                              ? AppTheme.neonGreen
                              : AppTheme.neonRed,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.textMuted.withOpacity(0.12),
                  ),
                  child: Text(
                    trend,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ShaderMask(
            shaderCallback: (bounds) => gradient.createShader(bounds),
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ).animate().shimmer(
                duration: 2.seconds,
                delay: 1.seconds,
                color: Colors.white.withOpacity(0.3),
              ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
