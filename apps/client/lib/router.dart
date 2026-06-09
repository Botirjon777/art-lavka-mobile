import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bootstrap/core_providers.dart';
import 'features/auth/login_page.dart';
import 'features/auth/otp_page.dart';
import 'features/auth/profile_completion_page.dart';
import 'features/auth/register_page.dart';
import 'features/auth/welcome_page.dart';
import 'features/cart/cart_page.dart';
import 'features/cart/checkout_page.dart';
import 'features/cart/order_success_page.dart';
import 'features/catalog/catalog_page.dart';
import 'features/home/home_page.dart';
import 'features/orders/order_detail_page.dart';
import 'features/orders/orders_list_page.dart';
import 'features/product/product_page.dart';
import 'features/profile/profile_page.dart';
import 'features/splash/splash_page.dart';
import 'ui/scaffold_with_nav.dart';

const _authRoutes = {'/welcome', '/login', '/register', '/otp'};
const _completeRoute = '/complete-profile';

/// App router with the auth gate + a bottom-nav shell for the main tabs.
final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.read(appSessionProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: session,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Hold on the splash until its animation completes.
      if (!session.splashDone) return loc == '/splash' ? null : '/splash';

      final onAuth = _authRoutes.contains(loc);
      if (!session.isSignedIn) {
        return onAuth ? null : '/welcome';
      }
      if (!session.hasProfile) {
        return loc == _completeRoute ? null : _completeRoute;
      }
      // Signed in with a profile: leave splash/auth/complete for home.
      if (loc == '/splash' || onAuth || loc == _completeRoute) return '/home';
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashPage()),
      GoRoute(path: '/welcome', builder: (_, _) => const WelcomePage()),
      GoRoute(path: '/login', builder: (_, _) => const LoginPage()),
      GoRoute(path: '/register', builder: (_, _) => const RegisterPage()),
      GoRoute(path: '/otp', builder: (_, _) => const OtpPage()),
      GoRoute(
        path: _completeRoute,
        builder: (_, _) => const ProfileCompletionPage(),
      ),

      // Bottom-nav shell: Home / Catalog / Orders / Profile.
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/home', builder: (_, _) => const HomePage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/catalog', builder: (_, _) => const CatalogPage()),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/orders',
                builder: (_, _) => const OrdersListPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profile', builder: (_, _) => const ProfilePage()),
            ],
          ),
        ],
      ),

      // Full-screen routes pushed over the bottom bar.
      GoRoute(
        path: '/product/:id',
        builder: (_, state) =>
            ProductPage(listingId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/cart', builder: (_, _) => const CartPage()),
      GoRoute(path: '/checkout', builder: (_, _) => const CheckoutPage()),
      GoRoute(
        path: '/orders/:id',
        builder: (_, state) =>
            OrderDetailPage(orderId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/order-success/:id',
        builder: (_, state) =>
            OrderSuccessPage(orderId: state.pathParameters['id']!),
      ),
    ],
  );
});
