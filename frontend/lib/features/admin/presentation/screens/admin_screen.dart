import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/particle_background.dart';

class AdminScreen extends ConsumerWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 10),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(context)),
                SliverToBoxAdapter(child: _buildSystemStatus()),
                SliverToBoxAdapter(child: _buildAiModels()),
                SliverToBoxAdapter(child: _buildUserManagement()),
                SliverToBoxAdapter(child: _buildDangerZone(context, ref)),
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADMIN PANEL',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [AppTheme.neonRed, AppTheme.neonPurple],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                ),
              ),
              const Text('SYSTEM MANAGEMENT · ENTERPRISE',
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: AppTheme.neonRed.withOpacity(0.1),
              border: Border.all(color: AppTheme.neonRed.withOpacity(0.4)),
            ),
            child: const Text('ADMIN',
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 10,
                  color: AppTheme.neonRed,
                  letterSpacing: 1.5,
                )),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildSystemStatus() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GlassCard(
        borderColor: AppTheme.neonGreen.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.monitor_heart_outlined,
                    color: AppTheme.neonGreen, size: 16),
                SizedBox(width: 8),
                Text('SYSTEM STATUS',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: AppTheme.neonGreen,
                      letterSpacing: 1.5,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            _StatusRow('API Server', 'ONLINE', AppTheme.neonGreen),
            _StatusRow('PostgreSQL', 'CONNECTED', AppTheme.neonGreen),
            _StatusRow('Redis Cache', 'ACTIVE', AppTheme.neonGreen),
            _StatusRow('Firebase Auth', 'OPERATIONAL', AppTheme.neonGreen),
            _StatusRow('AI Models', 'ALL LOADED', AppTheme.neonCyan),
            _StatusRow('Background Jobs', 'RUNNING', AppTheme.neonCyan),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _buildAiModels() {
    final models = [
      ('LSTM', 'Stability Forecasting', 0.943, '2024-01-15', AppTheme.neonCyan),
      ('XGBoost', 'Degradation Prediction', 0.927, '2024-01-15', AppTheme.neonBlue),
      ('Bayesian NN', 'Uncertainty Quantification', 0.935, '2024-01-14', AppTheme.neonPurple),
      ('GRU', 'Time-Series Forecasting', 0.918, '2024-01-14', AppTheme.neonGreen),
      ('Autoencoder', 'Anomaly Detection', 0.961, '2024-01-13', AppTheme.neonOrange),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        borderColor: AppTheme.neonBlue.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology_outlined,
                        color: AppTheme.neonBlue, size: 16),
                    SizedBox(width: 8),
                    Text('AI MODEL METRICS',
                        style: TextStyle(
                          fontFamily: 'Orbitron',
                          fontSize: 12,
                          color: AppTheme.neonBlue,
                          letterSpacing: 1.5,
                        )),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('RETRAIN ALL',
                      style: TextStyle(
                        fontFamily: 'Orbitron',
                        fontSize: 10,
                        color: AppTheme.neonRed,
                        letterSpacing: 1,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...models.map((m) => _ModelRow(
                  name: m.$1,
                  purpose: m.$2,
                  r2: m.$3,
                  trained: m.$4,
                  color: m.$5,
                )),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildUserManagement() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        borderColor: AppTheme.neonCyan.withOpacity(0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.people_outline,
                    color: AppTheme.neonCyan, size: 16),
                SizedBox(width: 8),
                Text('USER STATISTICS',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: AppTheme.neonCyan,
                      letterSpacing: 1.5,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBlock('24', 'TOTAL\nUSERS', AppTheme.neonCyan),
                _StatBlock('18', 'RESEARCHERS', AppTheme.neonBlue),
                _StatBlock('4', 'ADMINS', AppTheme.neonPurple),
                _StatBlock('2', 'GUESTS', AppTheme.textMuted),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.borderSubtle),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatBlock('156', 'PREDICTIONS\nTHIS MONTH', AppTheme.neonGreen),
                _StatBlock('43', 'BATCHES\nCREATED', AppTheme.neonCyan),
                _StatBlock('12', 'REPORTS\nGENERATED', AppTheme.neonYellow),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildDangerZone(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: GlassCard(
        borderColor: AppTheme.neonRed.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.warning_outlined,
                    color: AppTheme.neonRed, size: 16),
                SizedBox(width: 8),
                Text('SYSTEM ACTIONS',
                    style: TextStyle(
                      fontFamily: 'Orbitron',
                      fontSize: 12,
                      color: AppTheme.neonRed,
                      letterSpacing: 1.5,
                    )),
              ],
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'SIGN OUT',
              icon: Icons.logout,
              color: AppTheme.neonRed,
              onTap: () async {
                final auth = ref.read(authServiceProvider);
                await auth.signOut();
              },
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'CLEAR AI CACHE',
              icon: Icons.cached,
              color: AppTheme.neonOrange,
              onTap: () {},
            ),
            const SizedBox(height: 8),
            _ActionButton(
              label: 'EXPORT ALL DATA',
              icon: Icons.cloud_download_outlined,
              color: AppTheme.neonCyan,
              onTap: () {},
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}

class _StatusRow extends StatelessWidget {
  final String label, status;
  final Color color;

  const _StatusRow(this.label, this.status, this.color);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'SpaceMono',
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                )),
          ),
          Text(status,
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: color,
                letterSpacing: 0.8,
              )),
        ],
      ),
    );
  }
}

class _ModelRow extends StatelessWidget {
  final String name, purpose, trained;
  final double r2;
  final Color color;

  const _ModelRow({
    required this.name,
    required this.purpose,
    required this.r2,
    required this.trained,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: color.withOpacity(0.1),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Text(name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 9,
                  color: color,
                  letterSpacing: 0.5,
                )),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(purpose,
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    )),
                Text('Trained: $trained',
                    style: const TextStyle(
                      fontFamily: 'SpaceMono',
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    )),
              ],
            ),
          ),
          Text('R²=${r2.toStringAsFixed(3)}',
              style: TextStyle(
                fontFamily: 'Orbitron',
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.bold,
              )),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String value, label;
  final Color color;

  const _StatBlock(this.value, this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
              fontFamily: 'Orbitron',
              fontSize: 24,
              color: color,
              fontWeight: FontWeight.w900,
            )),
        const SizedBox(height: 4),
        Text(label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'SpaceMono',
              fontSize: 9,
              color: AppTheme.textMuted,
              letterSpacing: 0.8,
              height: 1.4,
            )),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: color.withOpacity(0.08),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                  fontFamily: 'Orbitron',
                  fontSize: 12,
                  color: color,
                  letterSpacing: 1,
                )),
            const Spacer(),
            Icon(Icons.chevron_right, color: color.withOpacity(0.5), size: 18),
          ],
        ),
      ),
    );
  }
}
