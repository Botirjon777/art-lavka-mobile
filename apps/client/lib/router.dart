import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap/core_providers.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/auth/profile_completion_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/home/home_page.dart';

/// Auth/onboarding routes a signed-out user may visit.
const _authRoutes = {'/welcome', '/login', '/register', '/otp'};
const _profileRoute = '/profile';

/// The app router. Redirect guards (SPEC §7/§8):
/// - signed out → only auth routes, else `/welcome`
/// - signed in, no profile → forced to `/profile`
/// - signed in, has profile → auth/profile routes bounce to `/home`
final routerProvider = Provider<GoRouter>((ref) {
  // Read once for a stable instance; the session drives refresh via the listener.
  final session = ref.read(appSessionProvider);

  return GoRouter(
    initialLocation: '/welcome',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final onAuth = _authRoutes.contains(loc);

      if (!session.isSignedIn) {
        return onAuth ? null : '/welcome';
      }
      if (!session.hasProfile) {
        return loc == _profileRoute ? null : _profileRoute;
      }
      if (onAuth || loc == _profileRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(
        path: _profileRoute,
        builder: (_, _) => const ProfileCompletionPage(),
      ),
      GoRoute(path: '/home', builder: (_, _) => const HomePage()),
    ],
  );
});
