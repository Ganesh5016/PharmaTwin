import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class StabilityGauge extends StatefulWidget {
  final double value; // 0.0 to 1.0

  const StabilityGauge({super.key, required this.value});

  @override
  State<StabilityGauge> createState() => _StabilityGaugeState();
}

class _StabilityGaugeState extends State<StabilityGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = Tween<double>(begin: 0, end: widget.value).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant StabilityGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return Center(
          child: SizedBox(
            width: 140,
            height: 80,
            child: CustomPaint(
              painter: _GaugePainter(value: _animation.value),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${(_animation.value * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.getStabilityColor(_animation.value),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getLabel(_animation.value),
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AppTheme.textMuted,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _getLabel(double v) {
    if (v > 0.85) return 'EXCELLENT';
    if (v > 0.65) return 'GOOD';
    if (v > 0.45) return 'ACCEPTABLE';
    return 'CRITICAL';
  }
}

class _GaugePainter extends CustomPainter {
  final double value;

  _GaugePainter({required this.value});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height - 20;
    final radius = size.width * 0.45;

    final startAngle = math.pi;
    final sweepAngle = math.pi;

    // Background arc
    final bgPaint = Paint()
      ..color = AppTheme.bgSurface
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Zones
    _drawZone(canvas, cx, cy, radius, startAngle, sweepAngle * 0.33,
        AppTheme.neonRed.withOpacity(0.3), 8);
    _drawZone(canvas, cx, cy, radius, startAngle + sweepAngle * 0.33,
        sweepAngle * 0.34, AppTheme.neonYellow.withOpacity(0.3), 8);
    _drawZone(canvas, cx, cy, radius, startAngle + sweepAngle * 0.67,
        sweepAngle * 0.33, AppTheme.neonGreen.withOpacity(0.3), 8);

    // Value arc
    final color = AppTheme.getStabilityColor(value);
    final valuePaint = Paint()
      ..shader = LinearGradient(
        colors: [AppTheme.neonRed, AppTheme.neonYellow, color],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(
          center: Offset(cx, cy), radius: radius))
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      startAngle,
      sweepAngle * value,
      false,
      valuePaint,
    );

    // Needle
    final needleAngle = startAngle + sweepAngle * value;
    final needleX = cx + (radius - 6) * math.cos(needleAngle);
    final needleY = cy + (radius - 6) * math.sin(needleAngle);

    canvas.drawCircle(
      Offset(needleX, needleY),
      5,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      Offset(needleX, needleY),
      5,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Center dot
    canvas.drawCircle(
      Offset(cx, cy),
      4,
      Paint()..color = AppTheme.textMuted.withOpacity(0.4),
    );
  }

  void _drawZone(Canvas canvas, double cx, double cy, double radius,
      double start, double sweep, Color color, double width) {
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      start,
      sweep,
      false,
      Paint()
        ..color = color
        ..strokeWidth = width
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter old) => old.value != value;
}
