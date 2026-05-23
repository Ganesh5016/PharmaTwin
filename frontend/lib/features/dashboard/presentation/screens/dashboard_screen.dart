import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/kpi_card.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/stability_gauge.dart';
import '../../../../shared/widgets/risk_meter.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scanController;

  @override
  void initState() {
    super.initState();
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // Load dashboard data
    Future.microtask(() => ref.read(dashboardProvider.notifier).loadDashboard());
  }

  @override
  void dispose() {
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 30),
          SafeArea(
            child: RefreshIndicator(
              onRefresh: () =>
                  ref.read(dashboardProvider.notifier).loadDashboard(),
              color: AppTheme.neonCyan,
              backgroundColor: AppTheme.bgSurface,
              child: CustomScrollView(
                slivers: [
                  // App Bar
                  SliverToBoxAdapter(
                    child: _buildHeader(context),
                  ),

                  // KPI Cards Row
                  SliverToBoxAdapter(
                    child: dashState.when(
                      data: (data) => _buildKpiRow(data),
                      loading: () => _buildKpiSkeleton(),
                      error: (e, _) => _buildError(e.toString()),
                    ),
                  ),

                  // Stability & Risk row
                  SliverToBoxAdapter(
                    child: dashState.when(
                      data: (data) => _buildStabilityRiskRow(data),
                      loading: () => const SizedBox(height: 200),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // Main Chart
                  SliverToBoxAdapter(
                    child: dashState.when(
                      data: (data) => _buildStabilityChart(data),
                      loading: () => const SizedBox(height: 300),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // AI Insights
                  SliverToBoxAdapter(
                    child: dashState.when(
                      data: (data) => _buildAiInsights(data),
                      loading: () => const SizedBox(height: 200),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  // Recent Batches
                  SliverToBoxAdapter(
                    child: dashState.when(
                      data: (data) => _buildRecentBatches(data),
                      loading: () => const SizedBox(height: 200),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DASHBOARD',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.neonCyan, AppTheme.neonBlue],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.neonGreen,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.neonGreen.withOpacity(0.5),
                          blurRadius: 6,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'AI SYSTEMS ONLINE',
                    style: TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.neonGreen,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ],
          ).animate().fadeIn().slideX(begin: -0.2),

          Row(
            children: [
              // Notifications badge
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined,
                        color: AppTheme.textSecondary),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.neonRed,
                        border: Border.all(
                            color: AppTheme.bgDeep, width: 1.5),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 4),

              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  border: Border.all(color: AppTheme.neonCyan, width: 2),
                ),
                child: const Center(
                  child: Text(
                    'R',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ).animate().fadeIn().slideX(begin: 0.2),
        ],
      ),
    );
  }

  Widget _buildKpiRow(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: 'STABILITY SCORE',
                  value: '${(data.stabilityScore * 100).toStringAsFixed(1)}%',
                  icon: Icons.shield_outlined,
                  gradient: AppTheme.successGradient,
                  trend: '+2.3%',
                  trendUp: true,
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  title: 'SHELF LIFE',
                  value: '${data.shelfLifeMonths.toStringAsFixed(1)}M',
                  icon: Icons.schedule_outlined,
                  gradient: AppTheme.cyanGradient,
                  trend: '±${data.shelfLifeUncertainty.toStringAsFixed(1)}M',
                  trendUp: null,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  title: 'DEGRADATION RISK',
                  value: '${(data.degradationRisk * 100).toStringAsFixed(0)}%',
                  icon: Icons.warning_outlined,
                  gradient: AppTheme.getRiskGradient(data.degradationRisk),
                  trend: data.degradationRisk > 0.5 ? 'HIGH' : 'LOW',
                  trendUp: data.degradationRisk < 0.5,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  title: 'CONFIDENCE',
                  value: '${(data.confidence * 100).toStringAsFixed(0)}%',
                  icon: Icons.analytics_outlined,
                  gradient: AppTheme.primaryGradient,
                  trend: '95% CI',
                  trendUp: true,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityRiskRow(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'STABILITY INDEX',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      color: AppTheme.neonCyan,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  StabilityGauge(value: data.stabilityScore),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'RISK MATRIX',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 11,
                      color: AppTheme.neonOrange,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  RiskMeter(
                    degradationRisk: data.degradationRisk,
                    dissolitionRisk: data.dissolutionRisk,
                    enviroRisk: data.environmentalRisk,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 600.ms),
          ),
        ],
      ),
    );
  }

  Widget _buildStabilityChart(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'STABILITY TIMELINE',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 12,
                        color: AppTheme.textPrimary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '24-month predictive model',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 10,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: AppTheme.neonGreen.withOpacity(0.1),
                    border: Border.all(
                        color: AppTheme.neonGreen.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 10,
                      color: AppTheme.neonGreen,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval: 0.2,
                    verticalInterval: 4,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: AppTheme.borderSubtle,
                      strokeWidth: 1,
                    ),
                    getDrawingVerticalLine: (value) => FlLine(
                      color: AppTheme.borderSubtle.withOpacity(0.5),
                      strokeWidth: 1,
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 0.2,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) => Text(
                          '${(value * 100).toInt()}%',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 4,
                        getTitlesWidget: (value, meta) => Text(
                          'M${value.toInt()}',
                          style: const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 9,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 24,
                  minY: 0,
                  maxY: 1,
                  lineBarsData: [
                    // Predicted stability (main line)
                    LineChartBarData(
                      spots: data.stabilityTimeline
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [AppTheme.neonCyan, AppTheme.neonBlue],
                      ),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppTheme.neonCyan.withOpacity(0.2),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    // Confidence upper bound
                    LineChartBarData(
                      spots: data.stabilityUpper
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.neonCyan.withOpacity(0.3),
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                    // Confidence lower bound
                    LineChartBarData(
                      spots: data.stabilityLower
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.neonCyan.withOpacity(0.3),
                      barWidth: 1,
                      dotData: const FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppTheme.bgCard,
                      getTooltipItems: (touchedSpots) =>
                          touchedSpots.map((s) {
                        return LineTooltipItem(
                          'M${s.x.toInt()}: ${(s.y * 100).toStringAsFixed(1)}%',
                          const TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 10,
                            color: AppTheme.neonCyan,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ChartLegendItem(
                    color: AppTheme.neonCyan, label: 'Predicted'),
                const SizedBox(width: 24),
                _ChartLegendItem(
                    color: AppTheme.neonCyan.withOpacity(0.4),
                    label: '95% CI',
                    dashed: true),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: 700.ms),
    );
  }

  Widget _buildAiInsights(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        borderColor: AppTheme.neonPurple.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    gradient: AppTheme.primaryGradient,
                  ),
                  child: const Icon(Icons.psychology_outlined,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Text(
                  'AI INSIGHTS',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'BAYESIAN · 95% CI',
                  style: TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 9,
                    color: AppTheme.neonPurple,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...data.aiInsights.map((insight) => _InsightItem(insight: insight)),
          ],
        ),
      ).animate().fadeIn(delay: 800.ms),
    );
  }

  Widget _buildRecentBatches(DashboardData data) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'RECENT BATCHES',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 13,
                    color: AppTheme.textPrimary,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  'VIEW ALL →',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 10,
                    color: AppTheme.neonCyan,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...data.recentBatches.take(4).map((batch) => _BatchListItem(batch: batch)),
          ],
        ),
      ).animate().fadeIn(delay: 900.ms),
    );
  }

  Widget _buildKpiSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _SkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonCard()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _SkeletonCard()),
              const SizedBox(width: 12),
              Expanded(child: _SkeletonCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.neonRed, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: AppTheme.glassDecoration(),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1500.ms,
          color: AppTheme.neonCyan.withOpacity(0.1),
        );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;

  const _ChartLegendItem({
    required this.color,
    required this.label,
    this.dashed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: CustomPaint(
            painter: _LinePainter(color: color, dashed: dashed),
            size: const Size(24, 2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'SpaceMono',
            fontSize: 10,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _LinePainter extends CustomPainter {
  final Color color;
  final bool dashed;

  _LinePainter({required this.color, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;

    if (dashed) {
      double x = 0;
      while (x < size.width) {
        canvas.drawLine(
            Offset(x, size.height / 2),
            Offset(x + 4, size.height / 2),
            paint);
        x += 8;
      }
    } else {
      canvas.drawLine(
          Offset(0, size.height / 2),
          Offset(size.width, size.height / 2),
          paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

class _InsightItem extends StatelessWidget {
  final AiInsight insight;

  const _InsightItem({required this.insight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: insight.severity == 'warning'
                  ? AppTheme.neonOrange
                  : insight.severity == 'critical'
                      ? AppTheme.neonRed
                      : AppTheme.neonGreen,
              boxShadow: [
                BoxShadow(
                  color: (insight.severity == 'critical'
                          ? AppTheme.neonRed
                          : AppTheme.neonGreen)
                      .withOpacity(0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.description,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BatchListItem extends StatelessWidget {
  final BatchSummary batch;

  const _BatchListItem({required this.batch});

  @override
  Widget build(BuildContext context) {
    final riskColor = AppTheme.getRiskColor(batch.riskScore);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: AppTheme.bgSurface,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              color: riskColor,
              boxShadow: [
                BoxShadow(color: riskColor.withOpacity(0.4), blurRadius: 4),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batch.batchId,
                  style: const TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  batch.formulation,
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 10,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(batch.stabilityScore * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 14,
                  color: riskColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                batch.status,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 9,
                  color: AppTheme.textMuted,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
