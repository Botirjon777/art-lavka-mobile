import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap/core_providers.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/home/dashboard_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/onboarding/pending_page.dart';

const _authRoutes = {'/login', '/otp'};

/// Studio router with the strict KYC gate (SPEC §9):
/// - signed out → only auth routes, else `/login`
/// - signed in, not onboarded → `/onboarding`
/// - signed in, pending → `/pending`
/// - signed in, verified → `/dashboard`
final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(appSessionProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (!session.isSignedIn) {
        return _authRoutes.contains(loc) ? null : '/login';
      }
      if (!session.hasOnboarded) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (!session.isVerified) {
        return loc == '/pending' ? null : '/pending';
      }
      // Verified → dashboard; bounce away from gate/auth routes.
      if (_authRoutes.contains(loc) ||
          loc == '/onboarding' ||
          loc == '/pending') {
        return '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/pending', builder: (_, _) => const PendingPage()),
      GoRoute(path: '/dashboard', builder: (_, _) => const DashboardPage()),
    ],
  );
});
