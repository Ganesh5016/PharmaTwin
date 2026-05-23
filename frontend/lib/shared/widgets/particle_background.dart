import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/theme/app_theme.dart';

class ParticleBackground extends StatefulWidget {
  final int density;
  const ParticleBackground({super.key, this.density = 40});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;
  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    _particles = List.generate(widget.density, (_) => _Particle(_rng));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        for (final p in _particles) {
          p.update();
        }
        return CustomPaint(
          painter: _ParticlePainter(_particles),
          size: MediaQuery.of(context).size,
        );
      },
    );
  }
}

class _Particle {
  late double x, y, vx, vy, size, opacity;
  final math.Random rng;

  _Particle(this.rng) {
    _init();
  }

  void _init() {
    x = rng.nextDouble();
    y = rng.nextDouble();
    vx = (rng.nextDouble() - 0.5) * 0.0008;
    vy = (rng.nextDouble() - 0.5) * 0.0008;
    size = rng.nextDouble() * 2 + 0.5;
    opacity = rng.nextDouble() * 0.4 + 0.1;
  }

  void update() {
    x += vx;
    y += vy;
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;
    x = x.clamp(0.0, 1.0);
    y = y.clamp(0.0, 1.0);
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < particles.length; i++) {
      final p = particles[i];
      final paint = Paint()
        ..color = AppTheme.neonCyan.withOpacity(p.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.size,
        paint,
      );

      // Draw connections between nearby particles
      for (int j = i + 1; j < particles.length; j++) {
        final q = particles[j];
        final dx = (p.x - q.x) * size.width;
        final dy = (p.y - q.y) * size.height;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 100) {
          final linePaint = Paint()
            ..color = AppTheme.neonCyan.withOpacity(0.04 * (1 - dist / 100))
            ..strokeWidth = 0.5;
          canvas.drawLine(
            Offset(p.x * size.width, p.y * size.height),
            Offset(q.x * size.width, q.y * size.height),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_) => true;
}
