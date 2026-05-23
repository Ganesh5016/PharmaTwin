import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/providers/auth_provider.dart';
import '../../../../shared/widgets/particle_background.dart';
import '../../../../shared/widgets/neon_button.dart';
import '../../../../shared/widgets/glass_text_field.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String _selectedRole = 'researcher';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _selectedRole,
      );
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e'),
              backgroundColor: AppTheme.neonRed),
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
          const ParticleBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios, color: AppTheme.neonCyan),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    'CREATE\nACCOUNT',
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      height: 1.1,
                      foreground: Paint()
                        ..shader = const LinearGradient(
                          colors: [AppTheme.neonGreen, AppTheme.neonCyan],
                        ).createShader(const Rect.fromLTWH(0, 0, 300, 100)),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.3),

                  const SizedBox(height: 8),
                  Text(
                    'Join the PharmaTwin AI research platform',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 350.ms),

                  const SizedBox(height: 40),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: AppTheme.glassDecoration(),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          GlassTextField(
                            controller: _nameController,
                            label: 'FULL NAME',
                            hint: 'Dr. Jane Smith',
                            prefixIcon: Icons.person_outline,
                            validator: (v) =>
                                v?.isEmpty ?? true ? 'Name is required' : null,
                          ).animate().fadeIn(delay: 400.ms),

                          const SizedBox(height: 16),

                          GlassTextField(
                            controller: _emailController,
                            label: 'EMAIL ADDRESS',
                            hint: 'researcher@pharma.com',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Email is required';
                              if (!v!.contains('@')) return 'Invalid email';
                              return null;
                            },
                          ).animate().fadeIn(delay: 500.ms),

                          const SizedBox(height: 16),

                          GlassTextField(
                            controller: _passwordController,
                            label: 'PASSWORD',
                            hint: 'Min. 8 characters',
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
                            validator: (v) {
                              if (v?.isEmpty ?? true) return 'Password is required';
                              if (v!.length < 8)
                                return 'Minimum 8 characters';
                              return null;
                            },
                          ).animate().fadeIn(delay: 600.ms),

                          const SizedBox(height: 20),

                          // Role selection
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ROLE',
                                style: TextStyle(
                                  fontFamily: 'Orbitron',
                                  fontSize: 10,
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  _RoleChip(
                                    label: 'RESEARCHER',
                                    isSelected: _selectedRole == 'researcher',
                                    onTap: () => setState(
                                        () => _selectedRole = 'researcher'),
                                  ),
                                  const SizedBox(width: 10),
                                  _RoleChip(
                                    label: 'USER',
                                    isSelected: _selectedRole == 'user',
                                    onTap: () =>
                                        setState(() => _selectedRole = 'user'),
                                  ),
                                  const SizedBox(width: 10),
                                  _RoleChip(
                                    label: 'ADMIN',
                                    isSelected: _selectedRole == 'admin',
                                    onTap: () =>
                                        setState(() => _selectedRole = 'admin'),
                                    color: AppTheme.neonPurple,
                                  ),
                                ],
                              ),
                            ],
                          ).animate().fadeIn(delay: 700.ms),

                          const SizedBox(height: 28),

                          NeonButton(
                            label: 'CREATE ACCOUNT',
                            isLoading: _isLoading,
                            onPressed: _register,
                            width: double.infinity,
                            gradient: AppTheme.successGradient,
                            glowColor: AppTheme.neonGreen,
                          ).animate().fadeIn(delay: 800.ms).scale(
                              begin: const Offset(0.9, 0.9)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.3),

                  const SizedBox(height: 28),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'ALREADY HAVE AN ACCOUNT? ',
                          style: TextStyle(
                            fontFamily: 'SpaceMono',
                            fontSize: 12,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            'SIGN IN',
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
                  ).animate().fadeIn(delay: 900.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color color;

  const _RoleChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color = AppTheme.neonCyan,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isSelected ? color.withOpacity(0.15) : AppTheme.bgSurface,
          border: Border.all(
            color: isSelected ? color : AppTheme.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Orbitron',
            fontSize: 10,
            color: isSelected ? color : AppTheme.textMuted,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.normal,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}
