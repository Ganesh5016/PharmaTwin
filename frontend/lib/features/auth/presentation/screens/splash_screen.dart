import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/particle_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _navigateAfterDelay();
  }

  void _navigateAfterDelay() async {
    await Future.delayed(const Duration(seconds: 4));
    if (mounted) context.go('/auth/login');
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Molecular ring animation
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 180 + _pulseController.value * 20,
                      height: 180 + _pulseController.value * 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.neonCyan
                              .withOpacity(0.2 + _pulseController.value * 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.neonCyan
                                .withOpacity(0.1 + _pulseController.value * 0.2),
                            blurRadius: 40,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.neonBlue.withOpacity(0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.neonCyan.withOpacity(0.15),
                                AppTheme.neonBlue.withOpacity(0.05),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: const _PharmaMoleculeIcon(),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 48),

                // Title
                Text(
                  'PHARMA',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppTheme.neonCyan, AppTheme.neonBlue],
                      ).createShader(
                          const Rect.fromLTWH(0, 0, 200, 50)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 500.ms)
                    .slideY(begin: 0.5, end: 0),

                Text(
                  'TWIN AI',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 8,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                        colors: [AppTheme.neonPurple, AppTheme.neonCyan],
                      ).createShader(
                          const Rect.fromLTWH(0, 0, 200, 50)),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms, delay: 700.ms)
                    .slideY(begin: 0.5, end: 0),

                const SizedBox(height: 16),

                Text(
                  'PHARMACEUTICAL DIGITAL TWIN PLATFORM',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.textMuted,
                    letterSpacing: 3,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 600.ms, delay: 900.ms),

                const SizedBox(height: 64),

                // Scanning progress bar
                SizedBox(
                  width: 240,
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _scanController,
                        builder: (context, child) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _scanController.value,
                              backgroundColor:
                                  AppTheme.bgSurface,
                              valueColor: const AlwaysStoppedAnimation(
                                AppTheme.neonCyan,
                              ),
                              minHeight: 2,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'INITIALIZING AI SYSTEMS...',
                        style: TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: AppTheme.textMuted,
                          letterSpacing: 2,
                        ),
                      ).animate().fadeIn(delay: 1.seconds).then().shimmer(
                            duration: 2.seconds,
                            delay: 1.seconds,
                          ),
                    ],
                  ),
                ).animate().fadeIn(delay: 1.5.seconds),
              ],
            ),
          ),

          // Version tag
          Positioned(
            bottom: 32,
            right: 24,
            child: Text(
              'v1.0.0 | ENTERPRISE',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textMuted.withOpacity(0.5),
                letterSpacing: 1.5,
              ),
            ).animate().fadeIn(delay: 2.seconds),
          ),
        ],
      ),
    );
  }
}

class _PharmaMoleculeIcon extends StatelessWidget {
  const _PharmaMoleculeIcon();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(100, 100),
        painter: _MoleculePainter(),
      ),
    );
  }
}

class _MoleculePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppTheme.neonCyan
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Central atom
    canvas.drawCircle(center, 12, fillPaint);
    canvas.drawCircle(center, 12, paint);

    // Orbital atoms
    const double orbitRadius = 35;
    final positions = [
      Offset(center.dx + orbitRadius, center.dy),
      Offset(center.dx - orbitRadius, center.dy),
      Offset(center.dx, center.dy - orbitRadius),
      Offset(center.dx, center.dy + orbitRadius),
    ];

    final bondPaint = Paint()
      ..color = AppTheme.neonBlue.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (final pos in positions) {
      canvas.drawLine(center, pos, bondPaint);
      canvas.drawCircle(pos, 7, Paint()
        ..color = AppTheme.neonBlue.withOpacity(0.4)
        ..style = PaintingStyle.fill);
      canvas.drawCircle(pos, 7, Paint()
        ..color = AppTheme.neonBlue
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke);
    }

    // Cross atoms
    const double diagRadius = 28;
    final diagPositions = [
      Offset(center.dx + diagRadius, center.dy - diagRadius),
      Offset(center.dx - diagRadius, center.dy + diagRadius),
    ];

    for (final pos in diagPositions) {
      canvas.drawLine(center, pos, bondPaint);
      canvas.drawCircle(pos, 5, Paint()
        ..color = AppTheme.neonPurple.withOpacity(0.4)
        ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
