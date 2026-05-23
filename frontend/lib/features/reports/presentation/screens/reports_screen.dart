import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  bool _isGenerating = false;
  String? _generatingType;

  final List<Map<String, dynamic>> _reports = [
    {
      'title': 'Stability Analysis Report – PT-2024-A09',
      'type': 'STABILITY',
      'date': '2024-01-15',
      'size': '2.4 MB',
      'color': AppTheme.neonGreen,
      'icon': Icons.shield_outlined,
    },
    {
      'title': 'AI Prediction Summary – Ibuprofen Batch',
      'type': 'PREDICTION',
      'date': '2024-01-14',
      'size': '1.8 MB',
      'color': AppTheme.neonBlue,
      'icon': Icons.auto_awesome_outlined,
    },
    {
      'title': 'Monte Carlo Simulation – Q1 2024',
      'type': 'SIMULATION',
      'date': '2024-01-12',
      'size': '3.1 MB',
      'color': AppTheme.neonPurple,
      'icon': Icons.scatter_plot_outlined,
    },
    {
      'title': 'ICH Compliance Batch Summary',
      'type': 'COMPLIANCE',
      'date': '2024-01-10',
      'size': '1.2 MB',
      'color': AppTheme.neonYellow,
      'icon': Icons.fact_check_outlined,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 15),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildGenerateSection()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: const Text(
                      'RECENT REPORTS',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 11,
                        color: AppTheme.textMuted,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final report = _reports[index];
                        return _ReportCard(report: report)
                            .animate()
                            .fadeIn(
                                delay: Duration(milliseconds: 100 * index))
                            .slideX(begin: 0.1);
                      },
                      childCount: _reports.length,
                    ),
                  ),
                ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
              ],
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
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REPORTS',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.neonYellow, AppTheme.neonOrange],
                    ).createShader(const Rect.fromLTWH(0, 0, 160, 30)),
                ),
              ),
              const Text('PDF GENERATION · ANALYTICS EXPORT',
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
            decoration: AppTheme.neonCardDecoration(
                glowColor: AppTheme.neonYellow),
            child: const Icon(Icons.picture_as_pdf_outlined,
                color: AppTheme.neonYellow, size: 22),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildGenerateSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GlassCard(
        borderColor: AppTheme.neonYellow.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.add_circle_outline,
                    color: AppTheme.neonYellow, size: 16),
                SizedBox(width: 8),
                Text(
                  'GENERATE NEW REPORT',
                  style: TextStyle(
                    fontFamily: 'Orbitron',
                    fontSize: 12,
                    color: AppTheme.neonYellow,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _GenerateButton(
                    label: 'STABILITY\nREPORT',
                    icon: Icons.shield_outlined,
                    color: AppTheme.neonGreen,
                    isLoading:
                        _isGenerating && _generatingType == 'STABILITY',
                    onTap: () => _generate('STABILITY'),
                  ),
                  const SizedBox(width: 10),
                  _GenerateButton(
                    label: 'AI\nSUMMARY',
                    icon: Icons.auto_awesome_outlined,
                    color: AppTheme.neonBlue,
                    isLoading: _isGenerating && _generatingType == 'AI',
                    onTap: () => _generate('AI'),
                  ),
                  const SizedBox(width: 10),
                  _GenerateButton(
                    label: 'BATCH\nANALYSIS',
                    icon: Icons.science_outlined,
                    color: AppTheme.neonCyan,
                    isLoading: _isGenerating && _generatingType == 'BATCH',
                    onTap: () => _generate('BATCH'),
                  ),
                  const SizedBox(width: 10),
                  _GenerateButton(
                    label: 'ICH\nCOMPLIANCE',
                    icon: Icons.fact_check_outlined,
                    color: AppTheme.neonPurple,
                    isLoading:
                        _isGenerating && _generatingType == 'ICH',
                    onTap: () => _generate('ICH'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Future<void> _generate(String type) async {
    setState(() {
      _isGenerating = true;
      _generatingType = type;
    });
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$type report generated successfully'),
          backgroundColor: AppTheme.neonGreen,
        ),
      );
    }
  }
}

class _GenerateButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isLoading;
  final VoidCallback onTap;

  const _GenerateButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: color),
                  )
                : Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 9,
                color: color,
                letterSpacing: 0.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map<String, dynamic> report;

  const _ReportCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final color = report['color'] as Color;

    return GlassCard(
      borderColor: color.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(report['icon'] as IconData, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  report['title'],
                  style: const TextStyle(
                    fontFamily: 'SpaceMono',
                    fontSize: 11,
                    color: AppTheme.textPrimary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        color: color.withOpacity(0.1),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Text(
                        report['type'],
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 8,
                          color: color,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${report['date']} · ${report['size']}',
                      style: const TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 9,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_outlined,
                color: AppTheme.textMuted, size: 20),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Downloading ${report['title']}...'),
                  backgroundColor: color,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
