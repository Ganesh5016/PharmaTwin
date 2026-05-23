import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class SimulationScreen extends StatefulWidget {
  const SimulationScreen({super.key});

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isRunning = false;
  double _progress = 0.0;
  bool _hasResults = false;

  // Parameters
  double _tempMean = 25.0;
  double _tempStd = 2.0;
  double _humidMean = 60.0;
  double _humidStd = 5.0;
  int _nSimulations = 1000;
  String _simulationType = 'Monte Carlo';

  // Results
  double _meanShelfLife = 0;
  double _stdShelfLife = 0;
  double _p5 = 0, _p50 = 0, _p95 = 0;
  List<double> _histogramData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _runSimulation() async {
    setState(() {
      _isRunning = true;
      _progress = 0.0;
      _hasResults = false;
    });

    // Simulate progress
    for (int i = 0; i <= 100; i += 5) {
      await Future.delayed(const Duration(milliseconds: 60));
      if (mounted) setState(() => _progress = i / 100.0);
    }

    // Generate Monte Carlo results
    final rng = math.Random(42);
    final results = <double>[];
    for (int i = 0; i < _nSimulations; i++) {
      final temp = _tempMean + rng.nextGaussian() * _tempStd;
      final humid = _humidMean + rng.nextGaussian() * _humidStd;
      final Ea = 80000.0;
      const R = 8.314;
      const T_ref = 298.15;
      final arr = math.exp(Ea / R * (1 / T_ref - 1 / (temp + 273.15)));
      final rate = 0.012 * arr * (1 + (humid - 40) * 0.003);
      final shelf = -math.log(0.90) / rate * 12;
      results.add(shelf.clamp(0, 48));
    }

    results.sort();
    final n = results.length;
    _meanShelfLife = results.reduce((a, b) => a + b) / n;
    _stdShelfLife = math.sqrt(
      results.map((x) => math.pow(x - _meanShelfLife, 2)).reduce((a, b) => a + b) / n,
    );
    _p5 = results[(n * 0.05).toInt()];
    _p50 = results[(n * 0.50).toInt()];
    _p95 = results[(n * 0.95).toInt()];

    // Build histogram (20 bins, 6–36 months)
    _histogramData = List.generate(20, (i) {
      final lo = 6.0 + i * 1.5;
      final hi = lo + 1.5;
      return results.where((v) => v >= lo && v < hi).length.toDouble();
    });

    if (mounted) {
      setState(() {
        _isRunning = false;
        _hasResults = true;
      });
      _tabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 15),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSetupTab(),
                      _buildResultsTab(),
                      _buildSensitivityTab(),
                    ],
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
                'SIMULATION',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.neonPurple, AppTheme.neonCyan],
                    ).createShader(const Rect.fromLTWH(0, 0, 220, 30)),
                ),
              ),
              const Text('MONTE CARLO · STOCHASTIC ENGINE',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.textMuted,
                    letterSpacing: 1.5,
                  )),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(8),
            decoration:
                AppTheme.neonCardDecoration(glowColor: AppTheme.neonPurple),
            child: const Icon(Icons.scatter_plot,
                color: AppTheme.neonPurple, size: 22),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.bgSurface,
          border: Border.all(color: AppTheme.borderGlass),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: AppTheme.primaryGradient,
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: const TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8),
          unselectedLabelColor: AppTheme.textMuted,
          labelColor: Colors.white,
          tabs: const [
            Tab(text: 'SETUP'),
            Tab(text: 'RESULTS'),
            Tab(text: 'SENSITIVITY'),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Simulation type
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'SIMULATION TYPE',
                    icon: Icons.tune,
                    color: AppTheme.neonPurple),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      'Monte Carlo',
                      'Latin Hypercube',
                      'Sobol Sequence',
                    ]
                        .map((t) => _TypeChip(
                              label: t,
                              isSelected: _simulationType == t,
                              onTap: () =>
                                  setState(() => _simulationType = t),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),
                _SimSlider(
                  label: 'N SIMULATIONS',
                  unit: '',
                  value: _nSimulations.toDouble(),
                  min: 100,
                  max: 10000,
                  divisions: 99,
                  displayValue: '$_nSimulations',
                  color: AppTheme.neonPurple,
                  onChanged: (v) =>
                      setState(() => _nSimulations = v.toInt()),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 12),

          // Temperature distribution
          GlassCard(
            borderColor: AppTheme.neonRed.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'TEMPERATURE DISTRIBUTION',
                    icon: Icons.thermostat,
                    color: AppTheme.neonRed),
                const SizedBox(height: 16),
                _SimSlider(
                  label: 'MEAN TEMPERATURE',
                  unit: '°C',
                  value: _tempMean,
                  min: 5,
                  max: 55,
                  displayValue: '${_tempMean.toStringAsFixed(1)}°C',
                  color: AppTheme.neonRed,
                  onChanged: (v) => setState(() => _tempMean = v),
                ),
                const SizedBox(height: 12),
                _SimSlider(
                  label: 'STD DEVIATION',
                  unit: '°C',
                  value: _tempStd,
                  min: 0.1,
                  max: 10,
                  displayValue: '±${_tempStd.toStringAsFixed(1)}°C',
                  color: AppTheme.neonOrange,
                  onChanged: (v) => setState(() => _tempStd = v),
                ),
                const SizedBox(height: 12),
                _GaussianPreview(
                    mean: _tempMean, std: _tempStd, color: AppTheme.neonRed, unit: '°C'),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 12),

          // Humidity distribution
          GlassCard(
            borderColor: AppTheme.neonBlue.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'HUMIDITY DISTRIBUTION',
                    icon: Icons.water_drop_outlined,
                    color: AppTheme.neonBlue),
                const SizedBox(height: 16),
                _SimSlider(
                  label: 'MEAN HUMIDITY',
                  unit: '%RH',
                  value: _humidMean,
                  min: 0,
                  max: 95,
                  displayValue: '${_humidMean.toStringAsFixed(0)}%RH',
                  color: AppTheme.neonBlue,
                  onChanged: (v) => setState(() => _humidMean = v),
                ),
                const SizedBox(height: 12),
                _SimSlider(
                  label: 'STD DEVIATION',
                  unit: '%RH',
                  value: _humidStd,
                  min: 0.5,
                  max: 15,
                  displayValue: '±${_humidStd.toStringAsFixed(1)}%RH',
                  color: AppTheme.neonCyan,
                  onChanged: (v) => setState(() => _humidStd = v),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // Run button
          _isRunning
              ? GlassCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.neonPurple),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'RUNNING $_nSimulations SIMULATIONS...',
                            style: const TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              color: AppTheme.neonPurple,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _progress,
                          backgroundColor: AppTheme.bgSurface,
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.neonPurple),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).toInt()}% COMPLETE',
                        style: const TextStyle(
                          fontFamily: 'SpaceMono',
                          fontSize: 10,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                )
              : Container(
                  width: double.infinity,
                  height: 54,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: const LinearGradient(
                        colors: [AppTheme.neonPurple, AppTheme.neonBlue]),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.neonPurple.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      onTap: _runSimulation,
                      borderRadius: BorderRadius.circular(14),
                      child: const Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow_rounded,
                                color: Colors.white, size: 24),
                            SizedBox(width: 10),
                            Text(
                              'RUN MONTE CARLO SIMULATION',
                              style: TextStyle(
                                fontFamily: 'Orbitron',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 400.ms).scale(
                    begin: const Offset(0.95, 0.95)),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildResultsTab() {
    if (!_hasResults) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.bar_chart_outlined,
                color: AppTheme.textMuted.withOpacity(0.3), size: 72),
            const SizedBox(height: 20),
            const Text(
              'NO RESULTS YET',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 16,
                color: AppTheme.textMuted,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure parameters and run the simulation',
              style: TextStyle(
                fontFamily: 'SpaceMono',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Key statistics
          GlassCard(
            borderColor: AppTheme.neonPurple.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'SIMULATION RESULTS',
                    icon: Icons.analytics_outlined,
                    color: AppTheme.neonPurple),
                const SizedBox(height: 8),
                Text(
                  '$_nSimulations iterations · $_simulationType',
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // Big number
                Center(
                  child: Column(
                    children: [
                      ShaderMask(
                        shaderCallback: (b) =>
                            AppTheme.primaryGradient.createShader(b),
                        child: Text(
                          '${_meanShelfLife.toStringAsFixed(1)}',
                          style: const TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 52,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Text('MONTHS (MEAN)',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            letterSpacing: 2,
                          )),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppTheme.neonPurple.withOpacity(0.1),
                          border: Border.all(
                              color: AppTheme.neonPurple.withOpacity(0.3)),
                        ),
                        child: Text(
                          'σ = ${_stdShelfLife.toStringAsFixed(2)} months',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 12,
                            color: AppTheme.neonPurple,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Percentile row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _PercentileCard(
                        label: 'P5', value: _p5, color: AppTheme.neonRed),
                    _PercentileCard(
                        label: 'P50 (MEDIAN)',
                        value: _p50,
                        color: AppTheme.neonCyan),
                    _PercentileCard(
                        label: 'P95', value: _p95, color: AppTheme.neonGreen),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          // Histogram
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'SHELF LIFE DISTRIBUTION',
                    icon: Icons.bar_chart,
                    color: AppTheme.neonCyan),
                const SizedBox(height: 4),
                const Text('Probability density of predicted shelf life',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    )),
                const SizedBox(height: 20),
                SizedBox(
                  height: 180,
                  child: BarChart(
                    BarChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppTheme.borderSubtle,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 4,
                            getTitlesWidget: (v, _) => Text(
                              '${(6 + v * 1.5).toInt()}M',
                              style: const TextStyle(
                                fontFamily: 'SpaceMono',
                                fontSize: 8,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: _histogramData
                          .asMap()
                          .entries
                          .map((e) => BarChartGroupData(
                                x: e.key,
                                barRods: [
                                  BarChartRodData(
                                    toY: e.value,
                                    gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        AppTheme.neonBlue.withOpacity(0.6),
                                        AppTheme.neonCyan,
                                      ],
                                    ),
                                    width: 12,
                                    borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ],
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 16),

          // Risk summary
          GlassCard(
            borderColor: AppTheme.neonOrange.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'RISK ASSESSMENT',
                    icon: Icons.warning_amber_outlined,
                    color: AppTheme.neonOrange),
                const SizedBox(height: 16),
                _RiskRow(
                  label: 'Probability shelf life < 12 months',
                  probability:
                      _histogramData.take(4).reduce((a, b) => a + b) /
                          _histogramData.reduce((a, b) => a + b),
                  color: AppTheme.neonRed,
                ),
                _RiskRow(
                  label: 'Probability shelf life > 18 months',
                  probability:
                      _histogramData.skip(8).reduce((a, b) => a + b) /
                          _histogramData.reduce((a, b) => a + b),
                  color: AppTheme.neonGreen,
                ),
                _RiskRow(
                  label: 'Coefficient of variation (CV)',
                  probability: _stdShelfLife / _meanShelfLife,
                  color: AppTheme.neonCyan,
                  isPercentage: true,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildSensitivityTab() {
    final factors = [
      ('Temperature Mean', 0.38, AppTheme.neonRed),
      ('Humidity Mean', 0.27, AppTheme.neonBlue),
      ('Temperature σ', 0.18, AppTheme.neonOrange),
      ('Humidity σ', 0.11, AppTheme.neonCyan),
      ('Drug Load', 0.06, AppTheme.neonPurple),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GlassCard(
            borderColor: AppTheme.neonCyan.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'SOBOL SENSITIVITY INDICES',
                    icon: Icons.radar,
                    color: AppTheme.neonCyan),
                const SizedBox(height: 4),
                const Text('First-order sensitivity of shelf life to each input',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.textMuted,
                    )),
                const SizedBox(height: 20),
                ...factors.map((f) => _SensitivityBar(
                      name: f.$1,
                      sensitivity: f.$2,
                      color: f.$3,
                    )),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SimSectionHeader(
                    title: 'KEY FINDINGS',
                    icon: Icons.lightbulb_outline,
                    color: AppTheme.neonYellow),
                const SizedBox(height: 16),
                _FindingItem(
                  icon: Icons.thermostat,
                  color: AppTheme.neonRed,
                  text:
                      'Temperature variability accounts for 38% of shelf-life uncertainty. Tighter temperature control would significantly reduce prediction variance.',
                ),
                _FindingItem(
                  icon: Icons.water_drop_outlined,
                  color: AppTheme.neonBlue,
                  text:
                      'Humidity mean is the second most influential factor (27%). Consider desiccant packaging to reduce humidity exposure.',
                ),
                _FindingItem(
                  icon: Icons.warning_amber_outlined,
                  color: AppTheme.neonYellow,
                  text:
                      'Combined temperature and humidity uncertainty contributes to ~±${_stdShelfLife.toStringAsFixed(1)} months shelf-life variance (1σ).',
                ),
              ],
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// ── Supporting Widgets ───────────────────────────────────────────────────────

class _SimSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SimSectionHeader(
      {required this.title, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 11,
              color: color,
              letterSpacing: 1.5,
            )),
      ],
    );
  }
}

class _SimSlider extends StatelessWidget {
  final String label, unit, displayValue;
  final double value, min, max;
  final int? divisions;
  final Color color;
  final ValueChanged<double> onChanged;

  const _SimSlider({
    required this.label,
    required this.unit,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.color,
    required this.onChanged,
    this.divisions,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: AppTheme.textSecondary,
                  letterSpacing: 1,
                )),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color.withOpacity(0.1),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(displayValue,
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  )),
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
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _GaussianPreview extends StatelessWidget {
  final double mean, std;
  final Color color;
  final String unit;

  const _GaussianPreview(
      {required this.mean, required this.std, required this.color, required this.unit});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.bgDeep,
      ),
      child: CustomPaint(
        painter: _GaussianPainter(mean: mean, std: std, color: color),
        size: const Size(double.infinity, 60),
      ),
    );
  }
}

class _GaussianPainter extends CustomPainter {
  final double mean, std;
  final Color color;

  _GaussianPainter({required this.mean, required this.std, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..style = PaintingStyle.fill;

    final path = Path();
    const nPoints = 100;
    final xMin = mean - 4 * std;
    final xMax = mean + 4 * std;

    // Gaussian PDF
    double gaussian(double x) {
      return math.exp(-0.5 * math.pow((x - mean) / std, 2)) /
          (std * math.sqrt(2 * math.pi));
    }

    final maxY = gaussian(mean);

    for (int i = 0; i <= nPoints; i++) {
      final x = xMin + i * (xMax - xMin) / nPoints;
      final y = gaussian(x);
      final px = (i / nPoints) * size.width;
      final py = size.height - (y / maxY) * size.height * 0.85 - 4;
      if (i == 0) {
        path.moveTo(px, size.height);
        path.lineTo(px, py);
      } else {
        path.lineTo(px, py);
      }
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Outline
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final linePath = Path();
    for (int i = 0; i <= nPoints; i++) {
      final x = xMin + i * (xMax - xMin) / nPoints;
      final y = gaussian(x);
      final px = (i / nPoints) * size.width;
      final py = size.height - (y / maxY) * size.height * 0.85 - 4;
      if (i == 0) linePath.moveTo(px, py);
      else linePath.lineTo(px, py);
    }
    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant _GaussianPainter old) =>
      old.mean != mean || old.std != std;
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeChip(
      {required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected
              ? AppTheme.neonPurple.withOpacity(0.15)
              : AppTheme.bgSurface,
          border: Border.all(
            color: isSelected
                ? AppTheme.neonPurple
                : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 10,
              color: isSelected ? AppTheme.neonPurple : AppTheme.textMuted,
              fontWeight:
                  isSelected ? FontWeight.w700 : FontWeight.normal,
              letterSpacing: 0.5,
            )),
      ),
    );
  }
}

class _PercentileCard extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _PercentileCard(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value.toStringAsFixed(1),
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 2),
        Text('M',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 12,
              color: color.withOpacity(0.6),
            )),
        const SizedBox(height: 4),
        Text(label,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
            )),
      ],
    );
  }
}

class _RiskRow extends StatelessWidget {
  final String label;
  final double probability;
  final Color color;
  final bool isPercentage;

  const _RiskRow(
      {required this.label,
      required this.probability,
      required this.color,
      this.isPercentage = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                )),
          ),
          const SizedBox(width: 12),
          Text(
            isPercentage
                ? '${(probability * 100).toStringAsFixed(1)}%'
                : '${(probability * 100).toStringAsFixed(0)}%',
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SensitivityBar extends StatelessWidget {
  final String name;
  final double sensitivity;
  final Color color;

  const _SensitivityBar(
      {required this.name, required this.sensitivity, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(name,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                  )),
              Text('${(sensitivity * 100).toInt()}%',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: sensitivity,
              backgroundColor: AppTheme.bgSurface,
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FindingItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _FindingItem(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.6,
                )),
          ),
        ],
      ),
    );
  }
}

// Gaussian random number extension
extension on math.Random {
  double nextGaussian() {
    double u, v, s;
    do {
      u = nextDouble() * 2 - 1;
      v = nextDouble() * 2 - 1;
      s = u * u + v * v;
    } while (s >= 1 || s == 0);
    return u * math.sqrt(-2 * math.log(s) / s);
  }
}
