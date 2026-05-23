import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/glass_text_field.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isGoogleLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString()}'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _googleSignIn() async {
    setState(() => _isGoogleLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google sign-in failed: ${e.toString()}'),
            backgroundColor: AppTheme.neonRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: Stack(
        children: [
          const ParticleBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // Header
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: AppTheme.neonCyan.withOpacity(0.3)),
                          color: AppTheme.neonCyan.withOpacity(0.08),
                        ),
                        child: const Text(
                          'PHARMATWIN AI v1.0',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 10,
                            color: AppTheme.neonCyan,
                            letterSpacing: 2,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 20),

                      Text(
                        'WELCOME\nBACK',
                        style: Theme.of(context)
                            .textTheme
                            .displayLarge
                            ?.copyWith(
                              height: 1.1,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    AppTheme.neonCyan,
                                    AppTheme.neonBlue,
                                    AppTheme.neonPurple,
                                  ],
                                ).createShader(
                                    const Rect.fromLTWH(0, 0, 300, 100)),
                            ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideX(begin: -0.3, end: 0),

                      const SizedBox(height: 8),

                      Text(
                        'Sign in to access your pharmaceutical\ndigital twin platform',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Form glass container
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassDecoration(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          GlassTextField(
                            controller: _emailController,
                            label: 'EMAIL ADDRESS',
                            hint: 'researcher@pharma.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Email is required';
                              if (!value!.contains('@'))
                                return 'Invalid email format';
                              return null;
                            },
                          ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2),

                          const SizedBox(height: 16),

                          GlassTextField(
                            controller: _passwordController,
                            label: 'PASSWORD',
                            hint: '••••••••',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true)
                                return 'Password is required';
                              if (value!.length < 6)
                                return 'Password must be at least 6 characters';
                              return null;
                            },
                          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),

                          const SizedBox(height: 12),

                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () =>
                                  context.push('/auth/forgot-password'),
                              child: const Text(
                                'FORGOT PASSWORD?',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 11,
                                  color: AppTheme.neonCyan,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(delay: 700.ms),

                          const SizedBox(height: 24),

                          // Sign In button
                          NeonButton(
                            label: 'SIGN IN',
                            isLoading: _isLoading,
                            onPressed: _signIn,
                            width: double.infinity,
                          ).animate().fadeIn(delay: 800.ms).scale(begin: const Offset(0.9, 0.9)),

                          const SizedBox(height: 16),

                          // Divider
                          Row(
                            children: [
                              const Expanded(
                                  child: Divider(
                                      color: AppTheme.borderSubtle)),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR',
                                  style: TextStyle(
                                    fontFamily: 'SpaceMono',
                                    fontSize: 11,
                                    color: AppTheme.textMuted,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ),
                              const Expanded(
                                  child: Divider(
                                      color: AppTheme.borderSubtle)),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Google sign in
                          OutlinedButton.icon(
                            onPressed: _isGoogleLoading ? null : _googleSignIn,
                            icon: _isGoogleLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.neonCyan,
                                    ),
                                  )
                                : const Icon(Icons.g_mobiledata, size: 24),
                            label: const Text('CONTINUE WITH GOOGLE'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                          ).animate().fadeIn(delay: 900.ms),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.3),

                  const SizedBox(height: 32),

                  // Sign up link
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "DON'T HAVE AN ACCOUNT? ",
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/auth/register'),
                          child: const Text(
                            'REGISTER',
                            style: TextStyle(
                              fontFamily: 'Orbitron',
                              fontSize: 12,
                              color: AppTheme.neonCyan,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 1.seconds),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
