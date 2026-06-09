import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap/core_providers.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/designs/designs_page.dart';
import 'features/designs/new_design_page.dart';
import 'features/earnings/earnings_page.dart';
import 'features/onboarding/onboarding_page.dart';
import 'features/onboarding/pending_page.dart';
import 'features/splash/splash_page.dart';
import 'features/stats/stats_page.dart';
import 'ui/scaffold_with_nav.dart';

const _authRoutes = {'/login', '/otp'};

/// Studio router with the splash + strict KYC gate (SPEC §9). The verified seller
/// area is a bottom-nav shell: Designs / Earnings / Stats.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(appSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      if (!session.splashDone) return loc == '/splash' ? null : '/splash';
      if (!session.isSignedIn) {
        return _authRoutes.contains(loc) ? null : '/login';
      }
      if (!session.hasOnboarded) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (!session.isVerified) {
        return loc == '/pending' ? null : '/pending';
      }
      // Verified → seller area; bounce splash/auth/gate routes to Designs.
      if (loc == '/splash' ||
          _authRoutes.contains(loc) ||
          loc == '/onboarding' ||
          loc == '/pending') {
        return '/designs';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingPage()),
      GoRoute(path: '/pending', builder: (_, _) => const PendingPage()),

      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/designs', builder: (_, _) => const DesignsPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/earnings',
                builder: (_, _) => const EarningsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/stats', builder: (_, _) => const StatsPage()),
            ],
          ),
        ],
      ),

      GoRoute(path: '/designs/new', builder: (_, _) => const NewDesignPage()),
    ],
  );
});
