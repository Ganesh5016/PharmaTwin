import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class DigitalTwinScreen extends StatefulWidget {
  const DigitalTwinScreen({super.key});

  @override
  State<DigitalTwinScreen> createState() => _DigitalTwinScreenState();
}

class _DigitalTwinScreenState extends State<DigitalTwinScreen>
    with TickerProviderStateMixin {
  late AnimationController _rotateController;
  late AnimationController _pulseController;
  late AnimationController _scanController;

  double _temperature = 25.0;
  double _humidity = 40.0;
  double _timeMonths = 0.0;
  String _selectedForm = 'Tablet';
  bool _isSimulating = false;
  double _simulationProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _pulseController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  // Calculate simulated stability based on conditions
  double get _calculatedStability {
    double base = 0.97;
    // Temperature effect (Arrhenius model simplified)
    base -= ((_temperature - 25) * 0.005).clamp(0, 0.3);
    // Humidity effect
    base -= ((_humidity - 40) * 0.002).clamp(0, 0.2);
    // Time degradation
    base -= (_timeMonths * 0.018);
    return base.clamp(0, 1);
  }

  double get _degradationPercent => ((1 - _calculatedStability) * 100);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 25),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        const SizedBox(height: 8),
                        _build3DModel(),
                        const SizedBox(height: 16),
                        _buildPropertyGrid(),
                        const SizedBox(height: 16),
                        _buildEnvironmentControls(),
                        const SizedBox(height: 16),
                        _buildTimeTravelControl(),
                        const SizedBox(height: 16),
                        _buildSimulateButton(),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DIGITAL TWIN',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.neonGreen, AppTheme.neonCyan],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                ),
              ),
              const Text(
                '3D PHARMACEUTICAL SIMULATION ENGINE',
                style: TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Form selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: AppTheme.glassDecoration(borderRadius: 8),
            child: DropdownButton<String>(
              value: _selectedForm,
              isDense: true,
              underline: const SizedBox.shrink(),
              dropdownColor: AppTheme.bgCard,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 11,
                color: AppTheme.neonCyan,
                letterSpacing: 0.5,
              ),
              icon: const Icon(Icons.keyboard_arrow_down,
                  color: AppTheme.neonCyan, size: 18),
              items: ['Tablet', 'Capsule', 'Coated Tab']
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedForm = v!),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _build3DModel() {
    final stability = _calculatedStability;
    final degradationColor = AppTheme.getRiskColor(1 - stability);

    return GlassCard(
      borderColor: AppTheme.neonGreen.withOpacity(0.2),
      child: Column(
        children: [
          // 3D viewport
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.bgDeep,
              border: Border.all(color: AppTheme.borderSubtle),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Scanning grid background
                AnimatedBuilder(
                  animation: _scanController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: _ScanGridPainter(
                        progress: _scanController.value,
                        color: AppTheme.neonCyan.withOpacity(0.1),
                      ),
                      size: const Size(double.infinity, 240),
                    );
                  },
                ),

                // Rotating molecule / tablet
                AnimatedBuilder(
                  animation: _rotateController,
                  builder: (context, child) {
                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(_rotateController.value * 2 * math.pi)
                        ..rotateX(0.2),
                      child: CustomPaint(
                        painter: _selectedForm == 'Capsule'
                            ? _CapsulePainter(
                                stability: stability,
                                degradationColor: degradationColor,
                              )
                            : _TabletPainter(
                                stability: stability,
                                degradationColor: degradationColor,
                              ),
                        size: const Size(160, 120),
                      ),
                    );
                  },
                ),

                // Scanning ring
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      width: 180 + _pulseController.value * 30,
                      height: 180 + _pulseController.value * 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.neonCyan
                              .withOpacity(0.1 + _pulseController.value * 0.1),
                          width: 1,
                        ),
                      ),
                    );
                  },
                ),

                // Holographic labels
                Positioned(
                  top: 16,
                  left: 16,
                  child: _HoloLabel(
                    label: _selectedForm.toUpperCase(),
                    value: 'ICH Q1A COMPLIANT',
                    color: AppTheme.neonCyan,
                  ),
                ),

                Positioned(
                  bottom: 16,
                  right: 16,
                  child: _HoloLabel(
                    label: 'STABILITY',
                    value: '${(stability * 100).toStringAsFixed(1)}%',
                    color: degradationColor,
                    rightAlign: true,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Real-time metrics
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TwinMetric(
                label: 'STABILITY',
                value: '${(stability * 100).toStringAsFixed(1)}%',
                color: AppTheme.getStabilityColor(stability),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderSubtle,
              ),
              _TwinMetric(
                label: 'DEGRADATION',
                value: '${_degradationPercent.toStringAsFixed(1)}%',
                color: degradationColor,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppTheme.borderSubtle,
              ),
              _TwinMetric(
                label: 'POTENCY',
                value: '${(stability * 100 * 1.01).toStringAsFixed(1)}%',
                color: AppTheme.neonBlue,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildPropertyGrid() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MOLECULAR PROPS',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: AppTheme.neonBlue,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                _PropertyRow('MW', '206.28 Da'),
                _PropertyRow('pKa', '4.91'),
                _PropertyRow('LogP', '3.97'),
                _PropertyRow('BCS', 'Class II'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FORMULATION DATA',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: AppTheme.neonPurple,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                _PropertyRow('Drug Load', '${_drugLoad.toStringAsFixed(0)}%'),
                _PropertyRow('Hardness', '8.2 N'),
                _PropertyRow('Friability', '0.3%'),
                _PropertyRow('Disint.', '4.2 min'),
              ],
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
  }

  double _drugLoad = 40.0;

  Widget _buildEnvironmentControls() {
    return GlassCard(
      borderColor: AppTheme.neonOrange.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.thermostat_outlined,
                  color: AppTheme.neonOrange, size: 16),
              SizedBox(width: 8),
              Text(
                'ENVIRONMENTAL SIMULATION',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  color: AppTheme.neonOrange,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Temperature
          _buildSimulationSlider(
            label: 'TEMPERATURE',
            value: _temperature,
            min: 5,
            max: 60,
            unit: '°C',
            color: AppTheme.neonRed,
            onChanged: (v) => setState(() => _temperature = v),
          ),

          const SizedBox(height: 16),

          // Humidity
          _buildSimulationSlider(
            label: 'RELATIVE HUMIDITY',
            value: _humidity,
            min: 0,
            max: 95,
            unit: '%',
            color: AppTheme.neonBlue,
            onChanged: (v) => setState(() => _humidity = v),
          ),

          const SizedBox(height: 16),

          // ICH condition presets
          const Text(
            'ICH PRESETS',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              color: AppTheme.textMuted,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _IchPresetChip(
                  label: 'Zone I',
                  temp: '21°C',
                  rh: '45%',
                  onTap: () => setState(() {
                    _temperature = 21;
                    _humidity = 45;
                  }),
                ),
                const SizedBox(width: 8),
                _IchPresetChip(
                  label: 'Zone II',
                  temp: '25°C',
                  rh: '60%',
                  onTap: () => setState(() {
                    _temperature = 25;
                    _humidity = 60;
                  }),
                ),
                const SizedBox(width: 8),
                _IchPresetChip(
                  label: 'Zone IVa',
                  temp: '30°C',
                  rh: '65%',
                  onTap: () => setState(() {
                    _temperature = 30;
                    _humidity = 65;
                  }),
                ),
                const SizedBox(width: 8),
                _IchPresetChip(
                  label: 'Stress',
                  temp: '40°C',
                  rh: '75%',
                  color: AppTheme.neonOrange,
                  onTap: () => setState(() {
                    _temperature = 40;
                    _humidity = 75;
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }

  Widget _buildTimeTravelControl() {
    return GlassCard(
      borderColor: AppTheme.neonPurple.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.timeline, color: AppTheme.neonPurple, size: 16),
              SizedBox(width: 8),
              Text(
                'TIME SIMULATION',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  color: AppTheme.neonPurple,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Simulate pharmaceutical aging over time',
            style: TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 10,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 16),
          _buildSimulationSlider(
            label: 'ELAPSED TIME',
            value: _timeMonths,
            min: 0,
            max: 36,
            unit: ' months',
            color: AppTheme.neonPurple,
            onChanged: (v) => setState(() => _timeMonths = v),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }

  Widget _buildSimulationSlider({
    required String label,
    required double value,
    required double min,
    required double max,
    required String unit,
    required Color color,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: AppTheme.textSecondary,
                letterSpacing: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 11,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: color,
            inactiveTrackColor: AppTheme.bgSurface,
            thumbColor: color,
            overlayColor: color.withOpacity(0.1),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulateButton() {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [AppTheme.neonGreen, AppTheme.neonCyan],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.neonGreen.withOpacity(0.3),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() => _isSimulating = !_isSimulating);
          },
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isSimulating ? Icons.pause_circle_outline : Icons.play_circle_outline,
                  color: AppTheme.bgDeep,
                  size: 22,
                ),
                const SizedBox(width: 10),
                Text(
                  _isSimulating ? 'PAUSE SIMULATION' : 'RUN FULL SIMULATION',
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.bgDeep,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 600.ms);
  }
}

// Property row helper
class _PropertyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 10,
                color: AppTheme.textMuted,
              )),
          Text(value,
              style: const TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

// Tablet 3D painter
class _TabletPainter extends CustomPainter {
  final double stability;
  final Color degradationColor;

  _TabletPainter({required this.stability, required this.degradationColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black54
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(cx + 4, cy + 4), width: 130, height: 50),
        shadowPaint);

    // Tablet body gradient
    final bodyGradient = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      colors: [
        AppTheme.neonCyan.withOpacity(0.9),
        AppTheme.neonBlue.withOpacity(0.7),
        AppTheme.neonBlue.withOpacity(0.4),
      ],
    ).createShader(Rect.fromCenter(
        center: Offset(cx, cy), width: 140, height: 60));

    final bodyPaint = Paint()..shader = bodyGradient;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(
          center: Offset(cx, cy), width: 130, height: 50),
      const Radius.circular(25),
    );
    canvas.drawRRect(rrect, bodyPaint);

    // Edge highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect, highlightPaint);

    // Score line
    final scorePaint = Paint()
      ..color = Colors.white.withOpacity(0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(
        Offset(cx, cy - 18), Offset(cx, cy + 18), scorePaint);

    // Degradation overlay
    if (stability < 0.9) {
      final degradPaint = Paint()
        ..color = degradationColor.withOpacity(0.15 * (1 - stability));
      canvas.drawRRect(rrect, degradPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TabletPainter old) =>
      old.stability != stability;
}

// Capsule painter
class _CapsulePainter extends CustomPainter {
  final double stability;
  final Color degradationColor;

  _CapsulePainter({required this.stability, required this.degradationColor});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cap (left half)
    final capGradient = RadialGradient(
      center: const Alignment(-0.4, -0.4),
      colors: [
        AppTheme.neonOrange.withOpacity(0.9),
        AppTheme.neonRed.withOpacity(0.6),
      ],
    ).createShader(Rect.fromLTWH(cx - 70, cy - 25, 80, 50));

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - 70, cy - 22, 75, 44),
        topLeft: const Radius.circular(22),
        bottomLeft: const Radius.circular(22),
      ),
      Paint()..shader = capGradient,
    );

    // Body (right half)
    final bodyGradient = RadialGradient(
      center: const Alignment(0.4, -0.4),
      colors: [
        AppTheme.bgSurface.withOpacity(0.9),
        AppTheme.textMuted.withOpacity(0.5),
      ],
    ).createShader(Rect.fromLTWH(cx - 5, cy - 25, 75, 50));

    canvas.drawRRect(
      RRect.fromRectAndCorners(
        Rect.fromLTWH(cx - 5, cy - 22, 75, 44),
        topRight: const Radius.circular(22),
        bottomRight: const Radius.circular(22),
      ),
      Paint()..shader = bodyGradient,
    );

    // Outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
            center: Offset(cx, cy), width: 145, height: 44),
        const Radius.circular(22),
      ),
      Paint()
        ..color = Colors.white.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _CapsulePainter old) =>
      old.stability != stability;
}

// Scan grid painter
class _ScanGridPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ScanGridPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5;

    // Vertical lines
    for (double x = 0; x <= size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Horizontal lines
    for (double y = 0; y <= size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Scan line
    final scanPaint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.4)
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final scanY = size.height * progress;
    canvas.drawLine(Offset(0, scanY), Offset(size.width, scanY), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _ScanGridPainter old) =>
      old.progress != progress;
}

// Holographic label
class _HoloLabel extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final bool rightAlign;

  const _HoloLabel({
    required this.label,
    required this.value,
    required this.color,
    this.rightAlign = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment:
            rightAlign ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 8,
              color: color.withOpacity(0.7),
              letterSpacing: 1,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _TwinMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TwinMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 18,
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 9,
            color: AppTheme.textMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _IchPresetChip extends StatelessWidget {
  final String label;
  final String temp;
  final String rh;
  final VoidCallback onTap;
  final Color color;

  const _IchPresetChip({
    required this.label,
    required this.temp,
    required this.rh,
    required this.onTap,
    this.color = AppTheme.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$temp / $rh',
              style: const TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 9,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
