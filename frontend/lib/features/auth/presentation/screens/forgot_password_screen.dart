import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/glass_text_field.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_emailController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.sendPasswordResetEmail(_emailController.text.trim());
      setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(density: 20),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: AppTheme.neonCyan),
                  ),
                  const SizedBox(height: 32),

                  if (!_emailSent) ...[
                    Text(
                      'RESET\nPASSWORD',
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                height: 1.1,
                                foreground: Paint()
                                  ..shader = const LinearGradient(
                                    colors: [
                                      AppTheme.neonYellow,
                                      AppTheme.neonOrange
                                    ],
                                  ).createShader(
                                      const Rect.fromLTWH(0, 0, 300, 100)),
                              ),
                    ).animate().fadeIn().slideX(begin: -0.3),

                    const SizedBox(height: 12),
                    const Text(
                      'Enter your email to receive a password reset link',
                      style: TextStyle(
                        fontFamily: 'SpaceMono',
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    const SizedBox(height: 48),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: AppTheme.glassDecoration(),
                      child: Column(
                        children: [
                          GlassTextField(
                            controller: _emailController,
                            label: 'EMAIL ADDRESS',
                            hint: 'researcher@pharma.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                          ).animate().fadeIn(delay: 300.ms),

                          const SizedBox(height: 24),

                          NeonButton(
                            label: 'SEND RESET LINK',
                            isLoading: _isLoading,
                            onPressed: _sendReset,
                            width: double.infinity,
                            gradient: AppTheme.warningGradient,
                            glowColor: AppTheme.neonOrange,
                          ).animate().fadeIn(delay: 400.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.3),
                  ] else ...[
                    // Success state
                    Center(
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.neonGreen.withOpacity(0.15),
                              border: Border.all(
                                  color: AppTheme.neonGreen.withOpacity(0.5),
                                  width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.neonGreen.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.mark_email_read_outlined,
                                color: AppTheme.neonGreen, size: 48),
                          ).animate().scale(delay: 200.ms),

                          const SizedBox(height: 32),
                          const Text(
                            'RESET LINK SENT',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 22,
                              color: AppTheme.neonGreen,
                              letterSpacing: 2,
                            ),
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 12),
                          Text(
                            'Check your inbox at\n${_emailController.text}',
                            style: const TextStyle(
                              fontFamily: 'SpaceMono',
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                              height: 1.6,
                            ),
                            textAlign: TextAlign.center,
                          ).animate().fadeIn(delay: 600.ms),

                          const SizedBox(height: 48),

                          NeonButton(
                            label: 'BACK TO LOGIN',
                            onPressed: () => context.go('/auth/login'),
                            width: 200,
                          ).animate().fadeIn(delay: 800.ms),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
