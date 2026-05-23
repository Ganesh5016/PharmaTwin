import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/digital_twin/presentation/screens/digital_twin_screen.dart';
import '../../features/predictions/presentation/screens/predictions_screen.dart';
import '../../features/predictions/presentation/screens/prediction_detail_screen.dart';
import '../../features/batch/presentation/screens/batch_screen.dart';
import '../../features/batch/presentation/screens/batch_detail_screen.dart';
import '../../features/simulation/presentation/screens/simulation_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/admin/presentation/screens/admin_screen.dart';
import '../../features/chat/presentation/screens/ai_chat_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth') ||
          state.matchedLocation == '/splash';

      if (!isAuthRoute && !isAuthenticated) return '/auth/login';
      if (isAuthenticated && state.matchedLocation == '/auth/login') return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/auth/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/digital-twin',
            builder: (context, state) => const DigitalTwinScreen(),
          ),
          GoRoute(
            path: '/predictions',
            builder: (context, state) => const PredictionsScreen(),
          ),
          GoRoute(
            path: '/predictions/:id',
            builder: (context, state) => PredictionDetailScreen(
              predictionId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/chat',
            builder: (context, state) => const AiChatScreen(),
          ),
          GoRoute(
            path: '/batches',
            builder: (context, state) => const BatchScreen(),
          ),
          GoRoute(
            path: '/batches/:id',
            builder: (context, state) => BatchDetailScreen(
              batchId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/simulation',
            builder: (context, state) => const SimulationScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/admin',
            builder: (context, state) => const AdminScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
});
